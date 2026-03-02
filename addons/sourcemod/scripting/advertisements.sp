#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <mapchooser>
#include <updater>

#pragma newdecls required
#pragma semicolon 1

#include "advertisements/chatcolors.sp"
#include "advertisements/topcolors.sp"

#define PL_VERSION	"2.1.3"
#define UPDATE_URL	"http://ErikMinekus.github.io/sm-advertisements/update.txt"

public Plugin myinfo =
{
    name        = "Advertisements",
    author      = "Tsunami",
    description = "Display advertisements",
    version     = PL_VERSION,
    url         = "http://www.tsunami-productions.nl"
};


enum struct Advertisement
{
    char center[1024];
    char chat[2048];
    char hint[1024];
    char menu[1024];
    char top[1024];
    bool adminsOnly;
    bool hasFlags;
    int flags;
}


/**
 * Globals
 */
bool g_bMapChooser;
bool g_bSayText2;
bool g_bUseDatabase;
int g_iCurrentAd;
ArrayList g_hAdvertisements;
ConVar g_hEnabled;
ConVar g_hFile;
ConVar g_hInterval;
ConVar g_hRandom;
ConVar g_hUseDatabase;
ConVar g_hDatabaseConfig;
Handle g_hTimer;
Database g_hDatabase;


/**
 * Plugin Forwards
 */
public void OnPluginStart()
{
    CreateConVar("sm_advertisements_version", PL_VERSION, "Display advertisements", FCVAR_NOTIFY);
    g_hEnabled        = CreateConVar("sm_advertisements_enabled",  "1",                  "Enable/disable displaying advertisements.");
    g_hFile           = CreateConVar("sm_advertisements_file",     "advertisements.txt", "File to read the advertisements from.");
    g_hInterval       = CreateConVar("sm_advertisements_interval", "30",                 "Number of seconds between advertisements.");
    g_hRandom         = CreateConVar("sm_advertisements_random",   "0",                  "Enable/disable random advertisements.");
    g_hUseDatabase    = CreateConVar("sm_advertisements_database", "1",                  "Use database (1) or flat files (0).");
    g_hDatabaseConfig = CreateConVar("sm_advertisements_dbconfig", "advertisements",     "Database config name from databases.cfg.");

    g_hFile.AddChangeHook(ConVarChanged_File);
    g_hInterval.AddChangeHook(ConVarChanged_Interval);
    g_hUseDatabase.AddChangeHook(ConVarChanged_Database);
    g_hDatabaseConfig.AddChangeHook(ConVarChanged_Database);

    g_bMapChooser = LibraryExists("mapchooser");
    g_bSayText2 = GetUserMessageId("SayText2") != INVALID_MESSAGE_ID;
    g_hAdvertisements = new ArrayList(sizeof(Advertisement));

    RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");

    AddChatColors();
    AddTopColors();

    if (LibraryExists("updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnConfigsExecuted()
{
    if (g_hUseDatabase.BoolValue) {
        ConnectToDatabase();
    } else {
        ParseAds();
        RestartTimer();
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "mapchooser")) {
        g_bMapChooser = true;
    }
    if (StrEqual(name, "updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "mapchooser")) {
        g_bMapChooser = false;
    }
}


/**
 * ConVar Changes
 */
public void ConVarChanged_File(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!g_bUseDatabase) {
        ParseAds();
    }
}

public void ConVarChanged_Interval(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RestartTimer();
}

public void ConVarChanged_Database(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_hUseDatabase.BoolValue) {
        ConnectToDatabase();
    } else {
        g_bUseDatabase = false;
        ParseAds();
        RestartTimer();
    }
}


/**
 * Commands
 */
public Action Command_ReloadAds(int args)
{
    if (g_bUseDatabase) {
        LoadAdsFromDatabase();
    } else {
        ParseAds();
    }
    return Plugin_Handled;
}


/**
 * Menu Handlers
 */
public void MenuHandler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {}


/**
 * Timers
 */
public void Timer_DisplayAd(Handle timer)
{
    if (!g_hEnabled.BoolValue) {
        return;
    }

    Advertisement ad;
    g_hAdvertisements.GetArray(g_iCurrentAd, ad);
    char message[1024];

    if (ad.center[0]) {
        ProcessVariables(ad.center, message, sizeof(message));

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                PrintCenterText(i, "%s", message);

                DataPack hCenterAd;
                CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                hCenterAd.WriteCell(i);
                hCenterAd.WriteString(message);
            }
        }
    }
    if (ad.chat[0]) {
        bool teamColor[10];
        char messages[10][1024];
        int messageCount = ExplodeString(ad.chat, "\n", messages, sizeof(messages), sizeof(messages[]));

        for (int idx; idx < messageCount; idx++) {
            teamColor[idx] = StrContains(messages[idx], "{teamcolor}", false) != -1;
            if (teamColor[idx] && !g_bSayText2) {
                SetFailState("This game does not support {teamcolor}");
            }

            ProcessChatColors(messages[idx], message, sizeof(message));
            ProcessVariables(message, messages[idx], sizeof(messages[]));
        }

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                for (int idx; idx < messageCount; idx++) {
                    if (teamColor[idx]) {
                        SayText2(i, messages[idx]);
                    } else {
                        PrintToChat(i, "%s", messages[idx]);
                    }
                }
            }
        }
    }
    if (ad.hint[0]) {
        ProcessVariables(ad.hint, message, sizeof(message));

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                PrintHintText(i, "%s", message);
            }
        }
    }
    if (ad.menu[0]) {
        ProcessVariables(ad.menu, message, sizeof(message));

        Panel hPl = new Panel();
        hPl.DrawText(message);
        hPl.CurrentKey = 10;

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                hPl.Send(i, MenuHandler_DoNothing, 10);
            }
        }

        delete hPl;
    }
    if (ad.top[0]) {
        int iStart    = 0,
            aColor[4] = {255, 255, 255, 255};

        ParseTopColor(ad.top, iStart, aColor);
        ProcessVariables(ad.top[iStart], message, sizeof(message));

        KeyValues hKv = new KeyValues("Stuff", "title", message);
        hKv.SetColor4("color", aColor);
        hKv.SetNum("level",    1);
        hKv.SetNum("time",     10);

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                CreateDialog(i, hKv, DialogType_Msg);
            }
        }

        delete hKv;
    }

    if (++g_iCurrentAd >= g_hAdvertisements.Length) {
        g_iCurrentAd = 0;
    }
}

public Action Timer_CenterAd(Handle timer, DataPack pack)
{
    char message[1024];
    static int iCount = 0;

    pack.Reset();
    int iClient = pack.ReadCell();
    pack.ReadString(message, sizeof(message));

    if (!IsClientInGame(iClient) || ++iCount >= 5) {
        iCount = 0;
        return Plugin_Stop;
    }

    PrintCenterText(iClient, "%s", message);
    return Plugin_Continue;
}


/**
 * Functions
 */
bool IsValidClient(int client, Advertisement ad)
{
    return IsClientInGame(client) && !IsFakeClient(client)
        && ((!ad.adminsOnly && !(ad.hasFlags && (GetUserFlagBits(client) & (ad.flags|ADMFLAG_ROOT))))
            || (ad.adminsOnly && (GetUserFlagBits(client) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))));
}

void ParseAds()
{
    g_iCurrentAd = 0;
    g_hAdvertisements.Clear();

    char sFile[64], sPath[PLATFORM_MAX_PATH];
    g_hFile.GetString(sFile, sizeof(sFile));
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);

    if (!FileExists(sPath)) {
        SetFailState("File Not Found: %s", sPath);
    }

    KeyValues hConfig = new KeyValues("Advertisements");
    hConfig.SetEscapeSequences(true);
    hConfig.ImportFromFile(sPath);
    hConfig.GotoFirstSubKey();

    Advertisement ad;
    char flags[22];
    do {
        hConfig.GetString("center", ad.center, sizeof(Advertisement::center));
        hConfig.GetString("chat",   ad.chat,   sizeof(Advertisement::chat));
        hConfig.GetString("hint",   ad.hint,   sizeof(Advertisement::hint));
        hConfig.GetString("menu",   ad.menu,   sizeof(Advertisement::menu));
        hConfig.GetString("top",    ad.top,    sizeof(Advertisement::top));
        hConfig.GetString("flags",  flags,     sizeof(flags), "none");
        ad.adminsOnly = StrEqual(flags, "");
        ad.hasFlags   = !StrEqual(flags, "none");
        ad.flags      = ReadFlagString(flags);

        g_hAdvertisements.PushArray(ad);
    } while (hConfig.GotoNextKey());

    if (g_hRandom.BoolValue) {
        g_hAdvertisements.Sort(Sort_Random, Sort_Integer);
    }

    delete hConfig;
}

void ProcessVariables(const char[] message, char[] buffer, int maxlength)
{
    char name[64], value[256];
    int buf_idx, i, name_len;
    ConVar hConVar;

    while (message[i] && buf_idx < maxlength - 1) {
        if (message[i] != '{' || (name_len = FindCharInString(message[i + 1], '}')) == -1) {
            buffer[buf_idx++] = message[i++];
            continue;
        }

        strcopy(name, name_len + 1, message[i + 1]);

        if (StrEqual(name, "currentmap", false)) {
            GetCurrentMap(value, sizeof(value));
            GetMapDisplayName(value, value, sizeof(value));
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "nextmap", false)) {
            if (g_bMapChooser && EndOfMapVoteEnabled() && !HasEndOfMapVoteFinished()) {
                buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, "Pending Vote");
            } else {
                GetNextMap(value, sizeof(value));
                GetMapDisplayName(value, value, sizeof(value));
                buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
            }
        }
        else if (StrEqual(name, "date", false)) {
            FormatTime(value, sizeof(value), "%m/%d/%Y");
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "time", false)) {
            FormatTime(value, sizeof(value), "%I:%M:%S%p");
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "time24", false)) {
            FormatTime(value, sizeof(value), "%H:%M:%S");
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "timeleft", false)) {
            int mins, secs, timeleft;
            if (GetMapTimeLeft(timeleft) && timeleft > 0) {
                mins = timeleft / 60;
                secs = timeleft % 60;
            }

            buf_idx += FormatEx(buffer[buf_idx], maxlength - buf_idx, "%d:%02d", mins, secs);
        }
        else if ((hConVar = FindConVar(name))) {
            hConVar.GetString(value, sizeof(value));
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else {
            buf_idx += FormatEx(buffer[buf_idx], maxlength - buf_idx, "{%s}", name);
        }

        i += name_len + 2;
    }

    buffer[buf_idx] = '\0';
}

void RestartTimer()
{
    delete g_hTimer;
    g_hTimer = CreateTimer(float(g_hInterval.IntValue), Timer_DisplayAd, _, TIMER_REPEAT);
}

/**
 * Database Functions
 */
void ConnectToDatabase()
{
    char configName[64];
    g_hDatabaseConfig.GetString(configName, sizeof(configName));
    
    Database.Connect(OnDatabaseConnected, configName);
}

public void OnDatabaseConnected(Database db, const char[] error, any data)
{
    if (db == null) {
        LogError("Failed to connect to database: %s", error);
        LogError("Falling back to flat file configuration");
        g_bUseDatabase = false;
        ParseAds();
        RestartTimer();
        return;
    }
    
    g_hDatabase = db;
    g_bUseDatabase = true;
    
    // Set character set for MySQL databases
    char driver[16];
    db.Driver.GetIdentifier(driver, sizeof(driver));
    if (StrEqual(driver, "mysql", false)) {
        db.SetCharset("utf8mb4");
    }
    
    CreateDatabaseTables();
}

void CreateDatabaseTables()
{
    char driver[16];
    g_hDatabase.Driver.GetIdentifier(driver, sizeof(driver));
    bool isMySQL = StrEqual(driver, "mysql", false);
    
    char query[1024];
    
    // Create messages table
    if (isMySQL) {
        Format(query, sizeof(query), 
            "CREATE TABLE IF NOT EXISTS advertisements_messages ("
            ... "id INT NOT NULL AUTO_INCREMENT, "
            ... "enabled TINYINT, "
            ... "`order` INT, "
            ... "center TEXT, "
            ... "chat TEXT, "
            ... "hint TEXT, "
            ... "menu TEXT, "
            ... "top TEXT, "
            ... "flags VARCHAR(32), "
            ... "PRIMARY KEY(id)"
            ... ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    } else {
        Format(query, sizeof(query), 
            "CREATE TABLE IF NOT EXISTS advertisements_messages ("
            ... "id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE, "
            ... "enabled INTEGER, "
            ... "\"order\" INTEGER, "
            ... "center TEXT, "
            ... "chat TEXT, "
            ... "hint TEXT, "
            ... "menu TEXT, "
            ... "top TEXT, "
            ... "flags TEXT"
            ... ")");
    }
    
    if (!SQL_FastQuery(g_hDatabase, query)) {
        char error[256];
        SQL_GetError(g_hDatabase, error, sizeof(error));
        LogError("Failed to create messages table: %s", error);
    }
    
    LoadAdsFromDatabase();
}

void LoadAdsFromDatabase()
{
    if (g_hDatabase == null) {
        LogError("Database not connected");
        g_bUseDatabase = false;
        ParseAds();
        RestartTimer();
        return;
    }
    
    char driver[16];
    g_hDatabase.Driver.GetIdentifier(driver, sizeof(driver));
    bool isMySQL = StrEqual(driver, "mysql", false);
    
    char query[256];
    if (isMySQL) {
        Format(query, sizeof(query), 
            "SELECT center, chat, hint, menu, top, flags FROM advertisements_messages "
            ... "WHERE enabled = 1 ORDER BY `order`, id");
    } else {
        Format(query, sizeof(query), 
            "SELECT center, chat, hint, menu, top, flags FROM advertisements_messages "
            ... "WHERE enabled = 1 ORDER BY \"order\", id");
    }
    
    DBResultSet results = SQL_Query(g_hDatabase, query);
    
    if (results == null) {
        char error[256];
        SQL_GetError(g_hDatabase, error, sizeof(error));
        LogError("Failed to load advertisements from database: %s", error);
        LogError("Falling back to flat file configuration");
        g_bUseDatabase = false;
        ParseAds();
        RestartTimer();
        return;
    }
    
    g_iCurrentAd = 0;
    g_hAdvertisements.Clear();
    
    Advertisement ad;
    while (SQL_FetchRow(results)) {
        // Reset the struct
        ad.center[0] = '\0';
        ad.chat[0] = '\0';
        ad.hint[0] = '\0';
        ad.menu[0] = '\0';
        ad.top[0] = '\0';
        ad.adminsOnly = false;
        ad.hasFlags = false;
        ad.flags = 0;
        
        // Read from database
        if (!SQL_IsFieldNull(results, 0))
            SQL_FetchString(results, 0, ad.center, sizeof(Advertisement::center));
        if (!SQL_IsFieldNull(results, 1))
            SQL_FetchString(results, 1, ad.chat, sizeof(Advertisement::chat));
        if (!SQL_IsFieldNull(results, 2))
            SQL_FetchString(results, 2, ad.hint, sizeof(Advertisement::hint));
        if (!SQL_IsFieldNull(results, 3))
            SQL_FetchString(results, 3, ad.menu, sizeof(Advertisement::menu));
        if (!SQL_IsFieldNull(results, 4))
            SQL_FetchString(results, 4, ad.top, sizeof(Advertisement::top));
        
        char flags[22];
        if (!SQL_IsFieldNull(results, 5)) {
            SQL_FetchString(results, 5, flags, sizeof(flags));
        } else {
            strcopy(flags, sizeof(flags), "none");
        }
        
        ad.adminsOnly = StrEqual(flags, "");
        ad.hasFlags   = !StrEqual(flags, "none");
        ad.flags      = ReadFlagString(flags);
        
        g_hAdvertisements.PushArray(ad);
    }
    
    delete results;
    
    if (g_hRandom.BoolValue) {
        g_hAdvertisements.Sort(Sort_Random, Sort_Integer);
    }
    
    RestartTimer();
    LogMessage("Loaded %d advertisements from database (%s)", g_hAdvertisements.Length, driver);
}

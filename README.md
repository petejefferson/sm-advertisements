# Advertisements Plugin - Database Integration Summary

## Changes Made

### Version Update
- Updated plugin version from 2.1.2 to 2.1.3

### New ConVars
- `sm_advertisements_database` - Controls whether to use database (1) or flat files (0). Default: 1
- `sm_advertisements_dbconfig` - Database config name from databases.cfg. Default: "advertisements"

### New Global Variables
- `g_bUseDatabase` - Boolean flag indicating if database is currently in use
- `g_hUseDatabase` - ConVar handle for database toggle
- `g_hDatabaseConfig` - ConVar handle for database config name
- `g_hDatabase` - Database connection handle

### New Functions

1. **ConnectToDatabase()** - Establishes database connection
   - Reads config name from ConVar
   - Uses async connection via Database.Connect
   - Falls back to flat files on failure

2. **OnDatabaseConnected()** - Database connection callback
   - Handles connection success/failure
   - Sets UTF-8 charset for MySQL databases
   - Calls CreateDatabaseTables() on success

3. **CreateDatabaseTables()** - Creates database schema
   - Detects database driver (MySQL, SQLite, PostgreSQL, etc.)
   - Creates `advertisements_messages` table with driver-specific syntax
   - Calls LoadAdsFromDatabase() after table creation

4. **LoadAdsFromDatabase()** - Loads advertisements from database
   - Detects database driver for query syntax
   - Queries `advertisements_messages` table
   - Orders by 'order' field, then 'id'
   - Only loads enabled advertisements (enabled = 1)
   - Automatically falls back to flat files on any error
   - Logs database driver type on success

### Modified Functions

1. **OnPluginStart()** - Added database ConVars and change hooks
2. **OnConfigsExecuted()** - Checks database ConVar and connects to DB or loads flat files
3. **ConVarChanged_File()** - Only reloads if not using database
4. **ConVarChanged_Database()** - New hook to handle database-related ConVar changes
5. **Command_ReloadAds()** - Reloads from DB or files based on mode

## Supported Databases

The plugin now supports multiple database backends:

- **SQLite** - Local database file, no additional setup required
- **MySQL/MariaDB** - Remote or local MySQL server with utf8mb4 charset support
- **PostgreSQL** - Enterprise PostgreSQL server
- **Any SourceMod-compatible database driver**

## Database Configuration

Database connections are configured in `addons/sourcemod/configs/databases.cfg`:

```
"advertisements"
{
    "driver"    "sqlite"    // or "mysql", "pgsql", etc.
    "database"  "advertisements"
    // Additional connection parameters for MySQL/PostgreSQL
}
```

The ConVar `sm_advertisements_database` controls whether to use the database (1) or flat files (0).

## Database Schema

### advertisements_messages Table
- Stores advertisement messages
- Fields: id, enabled, order, center, chat, hint, menu, top, flags
- Supports all existing advertisement types and features
- Ordered by 'order' field, then 'id'

## Fallback Mechanism

The plugin falls back to flat files in the following scenarios:

1. **Initial Connection Failure**
   - Database cannot be connected
   - Logs error and loads from flat file

2. **Table Creation Errors**
   - Non-critical: logs error but continues
   
3. **Message Loading Errors**
   - Cannot query advertisements_messages table
   - Falls back to flat files

4. **ConVar Override**
   - `sm_advertisements_database` set to 0
   - Uses flat files instead of database

## Database-Specific Handling

The plugin automatically detects the database driver and adjusts its behavior:

### SQLite
- Uses `INTEGER PRIMARY KEY AUTOINCREMENT` for auto-increment columns
- Uses double quotes for reserved word `"order"`
- No charset configuration needed

### MySQL
- Uses `INT AUTO_INCREMENT` for auto-increment columns
- Uses backticks for reserved word `` `order` ``
- Automatically sets `utf8mb4` charset for emoji support
- Uses `InnoDB` engine with proper character set
- Uses `VARCHAR(64)` for key columns instead of TEXT

### PostgreSQL
- Uses standard SQL syntax
- Uses double quotes for reserved words
- Proper data type handling

## Files Created/Modified

### Modified:
- `addons/sourcemod/scripting/advertisements.sp` - Main plugin file with multi-database support

### Created:
- `addons/sourcemod/configs/advertisements_sqlite.sql` - SQLite initialization script
- `addons/sourcemod/configs/advertisements_mysql.sql` - MySQL initialization script
- `addons/sourcemod/configs/databases.cfg.example` - Database configuration examples
- `addons/sourcemod/configs/DATABASE_USAGE.md` - User documentation
- `SQLITE_CHANGES.md` - This technical summary

## Testing Recommendations

1. **SQLite Testing**
   - Test with empty database (auto-creates tables)
   - Test with populated database (loads messages correctly)
   - Test fallback by renaming database file

2. **MySQL Testing**
   - Test connection with valid MySQL credentials
   - Test utf8mb4 charset support with emoji in messages
   - Test concurrent access from multiple servers

3. **General Testing**
   - Test ConVar changes (sm_advertisements_database 0/1)
   - Test sm_advertisements_reload command in both modes
   - Test with different database config names via sm_advertisements_dbconfig
   - Verify all advertisement types work (center, chat, hint, menu, top)
   - Verify flag filtering works correctly
   - Verify message ordering by 'order' field
   - Verify variables and color codes work in database messages

## Backwards Compatibility

- Fully backwards compatible
- Existing installations continue to work with flat files
- New installations default to database mode but fall back if needed
- No breaking changes to existing configurations
- ConVar names changed but functionality preserved

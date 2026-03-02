# Database Usage for Advertisements Plugin

## Overview

The Advertisements plugin now supports storing configuration and messages in a database (SQLite, MySQL, PostgreSQL, or any SourceMod-compatible database) with automatic fallback to flat files if the database cannot be accessed.

## Supported Databases

- **SQLite** - Local database file (default, no additional setup required)
- **MySQL** - Remote or local MySQL/MariaDB server
- **PostgreSQL** - Remote or local PostgreSQL server
- Any other database supported by SourceMod

## Setup

### 1. Configure Database Connection

Add a database configuration to `addons/sourcemod/configs/databases.cfg`:

#### For SQLite (Default):
```
"advertisements"
{
    "driver"    "sqlite"
    "database"  "advertisements"
}
```

#### For MySQL:
```
"advertisements"
{
    "driver"    "mysql"
    "host"      "localhost"
    "database"  "sourcemod"
    "user"      "your_username"
    "pass"      "your_password"
    //"port"    "3306"
}
```

#### For PostgreSQL:
```
"advertisements"
{
    "driver"    "pgsql"
    "host"      "localhost"
    "database"  "sourcemod"
    "user"      "postgres"
    "pass"      "your_password"
    //"port"    "5432"
}
```

See `databases.cfg.example` for more details.

### 2. Initialize the Database

The plugin will automatically create the necessary tables when it connects. However, you need to populate it with initial data.

#### For SQLite:
```bash
# In the SourceMod data directory (sourcemod/data/)
sqlite3 advertisements.sq3 < ../configs/advertisements_sqlite.sql
```

#### For MySQL:
```bash
mysql -u username -p database_name < advertisements_mysql.sql
```

Or use any database management tool (phpMyAdmin, MySQL Workbench, etc.) to execute the SQL file.

### 3. Configure the Plugin

The plugin has two new ConVars:

```
sm_advertisements_database "1"               // 1 = Use database, 0 = Use flat files (default: 1)
sm_advertisements_dbconfig "advertisements"  // Database config name from databases.cfg (default: "advertisements")
```

### 4. Switching Between Database and Flat Files

To switch between database and flat files, simply change the ConVar:

```
// Use database
sm_advertisements_database 1

// Use flat files
sm_advertisements_database 0
```

Then reload the plugin with: `sm_advertisements_reload`

## Database Schema

### advertisements_messages Table

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER/INT | Auto-incrementing ID (PRIMARY KEY) |
| enabled | INTEGER/TINYINT | 1 = enabled, 0 = disabled |
| order | INTEGER/INT | Display order (lower numbers first) |
| center | TEXT | Center screen message |
| chat | TEXT | Chat message (use \n for multiple lines) |
| hint | TEXT | Hint message |
| menu | TEXT | Menu panel message |
| top | TEXT | Top screen message with color |
| flags | TEXT/VARCHAR(32) | Admin flags (empty = admins only, 'none' = everyone) |

**Note:** Column types vary by database engine. The plugin handles these differences automatically.

## Managing Advertisements

### Add a New Advertisement

#### SQLite:
```sql
INSERT INTO advertisements_messages (enabled, "order", center, chat, flags) 
VALUES (1, 10, 'Visit our website!', '', 'none');
```

#### MySQL:
```sql
INSERT INTO advertisements_messages (enabled, `order`, center, chat, flags) 
VALUES (1, 10, 'Visit our website!', '', 'none');
```

### Disable an Advertisement

```sql
UPDATE advertisements_messages SET enabled = 0 WHERE id = 3;
```

### Change Display Order

#### SQLite:
```sql
UPDATE advertisements_messages SET "order" = 5 WHERE id = 2;
```

#### MySQL:
```sql
UPDATE advertisements_messages SET `order` = 5 WHERE id = 2;
```

### Delete an Advertisement

```sql
DELETE FROM advertisements_messages WHERE id = 4;
```

### After Making Changes

Reload the plugin to apply changes:
```
sm_advertisements_reload
```

## Fallback Behavior

The plugin will automatically fall back to flat files in these scenarios:

1. **Database connection fails** - Plugin logs error and loads from `advertisements.txt`
2. **ConVar `sm_advertisements_database` is set to 0** - Plugin uses flat files
3. **Query errors** - Plugin logs error and falls back to flat files

In all cases, the plugin will continue to function using the traditional flat file system.

## Database-Specific Notes

### SQLite
- Database file is stored in `addons/sourcemod/data/advertisements.sq3`
- No additional server setup required
- Best for single-server setups
- Use double quotes for reserved words: `"order"`

### MySQL
- Supports multiple servers sharing the same database
- Requires a MySQL/MariaDB server
- Better performance for large datasets
- Use backticks for reserved words: `` `order` ``
- Automatically uses utf8mb4 charset for emoji support

### PostgreSQL
- Enterprise-grade reliability
- Requires a PostgreSQL server
- Advanced features and performance
- Use double quotes for reserved words: `"order"`

## Variables and Color Codes

All existing variables and color codes work in database messages:

**Variables:**
- `{currentmap}` - Current map name
- `{nextmap}` - Next map name
- `{date}` - Current date
- `{time}` - Current time
- `{time24}` - 24-hour time
- `{timeleft}` - Time remaining on map
- Any ConVar name in braces

**Chat Colors:**
- `{default}`, `{red}`, `{green}`, `{blue}`, `{yellow}`, `{lightgreen}`, `{orange}`, etc.
- `{teamcolor}` - Player's team color

**Top Colors:**
- `{orange}`, `{red}`, `{green}`, `{blue}`, etc.

## Examples

### Multi-line Chat Message

```sql
INSERT INTO advertisements_messages (enabled, "order", chat, flags)
VALUES (1, 1, '{green}Welcome to our server!\n{lightgreen}Type !help for commands', 'none');
```

### Admin-Only Message

```sql
INSERT INTO advertisements_messages (enabled, "order", top, flags)
VALUES (1, 5, '{red}Admin: Check player reports', '');
```

### Exclude Specific Admin Flags

```sql
-- This ad won't show to admins with 'z' or 'cft' flags
INSERT INTO advertisements_messages (enabled, "order", hint, flags)
VALUES (1, 3, 'Donate for VIP!', 'zcft');
```

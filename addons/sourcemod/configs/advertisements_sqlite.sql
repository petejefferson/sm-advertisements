-- SQLite database schema for Advertisements plugin
-- Use this file if you are using SQLite as your database backend

-- Create advertisements table
CREATE TABLE IF NOT EXISTS advertisements (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    enabled INTEGER,
    "order" INTEGER,
    center TEXT,
    chat TEXT,
    hint TEXT,
    menu TEXT,
    top TEXT,
    flags TEXT
);

-- Sample advertisements
-- Note: Use \n for multiple chat lines in the chat field
INSERT INTO advertisements (enabled, "order", center, chat, hint, menu, top, flags) 
VALUES (1, 1, 'www.domain.com', '', '', '', '', 'none');

INSERT INTO advertisements (enabled, "order", center, chat, hint, menu, top, flags) 
VALUES (1, 2, 'contact@domain.com', '', 'contact@domain.com', '', '', 'none');

INSERT INTO advertisements (enabled, "order", center, chat, hint, menu, top, flags) 
VALUES (1, 3, '', '', '', 'Next map is {nextmap} in {timeleft} minutes.', '', 'cft');

INSERT INTO advertisements (enabled, "order", center, chat, hint, menu, top, flags) 
VALUES (1, 4, '', '{green}Current {lightgreen}Map: {default}{currentmap}', '', '', '', 'z');

INSERT INTO advertisements (enabled, "order", center, chat, hint, menu, top, flags) 
VALUES (1, 5, '', '', '', '', '{orange}Admins: friendly fire is {mp_friendlyfire}.', '');

-- To disable an advertisement, set enabled = 0
-- UPDATE advertisements SET enabled = 0 WHERE id = 1;

-- To switch to flat files, use the ConVar:
-- sm_advertisements_database 0

-- To add a new advertisement
-- INSERT INTO advertisements (enabled, "order", center, flags) 
-- VALUES (1, 10, 'Your message', 'none');


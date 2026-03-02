-- MySQL database schema for Advertisements plugin
-- Use this file if you are using MySQL as your database backend

-- Create messages table
CREATE TABLE IF NOT EXISTS advertisements_messages (
    id INT NOT NULL AUTO_INCREMENT,
    enabled TINYINT,
    `order` INT,
    center TEXT,
    chat TEXT,
    hint TEXT,
    menu TEXT,
    top TEXT,
    flags VARCHAR(32),
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sample advertisements
-- Note: Use \n for multiple chat lines in the chat field
INSERT INTO advertisements_messages (enabled, `order`, center, chat, hint, menu, top, flags) 
VALUES (1, 1, 'www.domain.com', '', '', '', '', 'none');

INSERT INTO advertisements_messages (enabled, `order`, center, chat, hint, menu, top, flags) 
VALUES (1, 2, 'contact@domain.com', '', 'contact@domain.com', '', '', 'none');

INSERT INTO advertisements_messages (enabled, `order`, center, chat, hint, menu, top, flags) 
VALUES (1, 3, '', '', '', 'Next map is {nextmap} in {timeleft} minutes.', '', 'cft');

INSERT INTO advertisements_messages (enabled, `order`, center, chat, hint, menu, top, flags) 
VALUES (1, 4, '', '{green}Current {lightgreen}Map: {default}{currentmap}', '', '', '', 'z');

INSERT INTO advertisements_messages (enabled, `order`, center, chat, hint, menu, top, flags) 
VALUES (1, 5, '', '', '', '', '{orange}Admins: friendly fire is {mp_friendlyfire}.', '');

-- To disable an advertisement, set enabled = 0
-- UPDATE advertisements_messages SET enabled = 0 WHERE id = 1;

-- To switch to flat files, use the ConVar:
-- sm_advertisements_database 0

-- To add a new advertisement
-- INSERT INTO advertisements_messages (enabled, `order`, center, flags) 
-- VALUES (1, 10, 'Your message', 'none');

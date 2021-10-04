-- Up
CREATE TABLE users (
    username TEXT PRIMARY KEY,
    password TEXT,
    admin INT DEFAULT 0
);

CREATE TABLE wtfs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    organizer TEXT,
    description TEXT,
    FOREIGN KEY (organizer) REFERENCES users(username)
);

CREATE TABLE challs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    wtf INTEGER,
    name TEXT,
    description TEXT,
    points INTEGER,
    flag TEXT,
    FOREIGN KEY (wtf) REFERENCES wtfs(id)
);

CREATE TABLE solves (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    challenge INTEGER,
    user TEXT,
    FOREIGN KEY (challenge) REFERENCES challs(id)
);
INSERT INTO users (username, password, admin) VALUES ("admin", '', 1);
INSERT INTO wtfs (name, organizer, description) VALUES (
    "tastelessctf21",
    "admin",
    "lots of memes");
INSERT INTO challs (wtf, name, description, points, flag) VALUES (
    1,
    "wtftime",
    "amazing wtf stuff",
    500,
    "tstlss{flag}");
INSERT INTO challs (wtf, name, description, points, flag) VALUES (
    1,
    "bebyped",
    "meny cry",
    300,
    "wtf{cry}");

INSERT INTO solves (user, challenge) VALUES ("alice", 1);
INSERT INTO solves (user, challenge) VALUES ("alice", 2);
INSERT INTO solves (user, challenge) VALUES ("bob", 2);
INSERT INTO solves (user, challenge) VALUES ("charlie", 1);

-- Down
DROP TABLE users;
DROP TABLE wtfs;
DROP TABLE challs;
DROP TABLE solves;
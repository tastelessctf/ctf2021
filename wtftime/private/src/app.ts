import session from "express-session";
import express from "express";
import type { IncomingMessage } from "http";
import { graphqlHTTP } from "express-graphql";
import { loadSchema } from "@graphql-tools/load";
import { GraphQLFileLoader } from "@graphql-tools/graphql-file-loader";
import sqlite3 from "sqlite3";
import { open, ISqlite } from "sqlite";
import bcrypt from "bcrypt";
import path from "path";
import sanitizeHtml from 'sanitize-html';

const PORT = process.env.PORT || 3000;
const FLAG = process.env.FLAG || "tstlss{FlagGoesHere}";
const ADMINPW = process.env.ADMIN_PW || "secret";

class Organizer {
  name: string;

  constructor({ name }) {
    this.name = name;
  }

  wtfs(_, ctx) {
    return ctx.db
      .all(`SELECT * FROM wtfs WHERE organizer = :name`, { ":name": this.name })
      .then((result) =>
        result.map(
          (r) =>
            new WTF(r.id, {
              organizer: r.organizer,
              description: r.description,
              name: r.name,
            })
        )
      );
  }
}

class WTF {
  id: number;
  name: string;
  description: string;
  _organizer: string;

  constructor(
    id,
    args: { organizer: string; description: string; name: string }
  ) {
    this.id = id;
    this.description = args.description;
    this.name = args.name;
    this._organizer = args.organizer;
  }

  organizer(_, ctx) {
    return new Organizer({ name: this._organizer });
  }

  challs(_, ctx) {
    return ctx.db
      .all("SELECT * FROM challs WHERE wtf = :wtf", { ":wtf": this.id })
      .then((results) => results.map((r) => new Chall(r.id, r)));
  }

  scoreboard(_, ctx) {
    return ctx.db.all(
      `SELECT solves.user as user, SUM(challs.points) as points FROM challs
            LEFT JOIN solves
            WHERE challs.id = solves.challenge
            AND challs.wtf = :wtf
            GROUP BY solves.user
            ORDER BY points DESC`,
      { ":wtf": this.id }
    );
  }
}

class Chall {
  id: number;
  name: string;
  description: string;
  points: number;
  _flag: string;
  _wtf: number;

  constructor(
    id,
    args: {
      wtf: number;
      description: string;
      name: string;
      points: number;
      flag: string;
    }
  ) {
    this.id = id;
    this.description = args.description;
    this.name = args.name;
    this.points = args.points;
    this._wtf = args.wtf;
    this._flag = args.flag;
  }

  wtf(_, ctx) {
    return ctx.db
      .get("SELECT * FROM wtfs WHERE id = :id", { ":id": this.id })
      .then((result) => new WTF(result.id, result));
  }

  solves(_, ctx) {
    return ctx.db
      .all("SELECT * FROM solves WHERE challenge = :id", { ":id": this.id })
      .then((result) => result.map((r) => new Solve(r.id, r)));
  }

  flag(_, ctx) {
    if (!ctx.admin())
      return Promise.reject(new Error("Only admins can get flags!"));
    return this._flag;
  }
}

class Solve {
  id: number;
  user: string;
  _chall: number;

  constructor(id, args: { user: string; challenge: number }) {
    this.id = id;
    this._chall = args.challenge;
    this.user = args.user;
  }

  challenge(_, ctx) {
    return ctx.db
      .get("SELECT * FROM challs where id = :id", { ":id": this.id })
      .then((result) => new Chall(result.id, result));
  }
}

const root = {
  register: ({ username, password }, ctx) =>
    new Promise((resolve, reject) =>
      bcrypt.hash(password, 10, (err, hash) =>
        ctx.db
          .run(
            "INSERT INTO users (username, password) VALUES (:username, :password)",
            {
              ":username": username,
              ":password": hash,
            }
          )
          .catch((_) => reject(new Error("Failed to create user")))
          .then((_) => resolve(true))
      )
    ),

  authenticate: ({ username, password }, ctx) =>
    new Promise((resolve, reject) =>
      ctx.db
        .get("SELECT * FROM users WHERE username = :username", {
          ":username": username,
        })
        .then((user) => {
          if (!user) return reject(new Error("Authentication failed!"));
          bcrypt.compare(password, user.password, (err, res) =>
            res ? resolve(user) : reject(new Error("Authentication failed!"))
          );
        })
    ).then((user: { username: string; admin: boolean }) => {
      ctx.session.username = user.username;
      ctx.session.admin = !!user.admin;
      return user.username;
    }),

  logout: (_, ctx) =>
    new Promise((resolve, reject) => {
      ctx.session.username = undefined;
      ctx.session.admin = false;
      resolve(true);
    }),

  currentUser: (_, ctx) =>
    new Promise((resolve, reject) => {
      if (!ctx.username()) return reject(new Error("Unauthenticated!"));
      resolve({ username: ctx.username(), admin: ctx.admin() });
    }),

  organizers: (_, ctx) =>
    ctx.db
      .all("SELECT * from users")
      .then((result) => result.map((r) => new Organizer({ name: r.username }))),

  wtf: ({ id }, ctx) =>
    new Promise((resolve, reject) =>
      ctx.db
        .get("SELECT * FROM wtfs WHERE id = :id", { ":id": id })
        .then((result) =>
          result
            ? resolve(new WTF(result.id, result))
            : reject(new Error("Invalid ID"))
        )
    ),

  createWTF: ({ input }, ctx) =>
    new Promise((resolve, reject) => {
      if (ctx.username() === undefined)
        return reject(new Error("Authentication required!"));
      return ctx.db
        .run(
          `INSERT INTO wtfs (name, organizer, description)
        VALUES (:name, :organizer, :description)`,
          {
            ":name": input.name,
            ":description": sanitizeHtml(input.description),
            ":organizer": ctx.username(),
          }
        )
        .then((result) => resolve(new WTF(result.lastID, input)));
    }),

  createChall: ({ input }, ctx) =>
    new Promise((resolve, reject) => {
      if (ctx.username() === undefined)
        return reject(new Error("Authentication required!"));
      ctx.db
        .run(
          `INSERT INTO challs (wtf, name, description, points, flag)
          VALUES (:wtf, :name, :description, :points, :flag)`,
          {
            ":wtf": input.wtf,
            ":name": input.name,
            ":description": sanitizeHtml(input.description),
            ":points": input.points,
            ":flag": input.flag,
          }
        )
        .then((result) => resolve(new Chall(result.lastID, input)))
  }),

  submitFlag: ({ flag }, ctx) =>
    new Promise((resolve, reject) => {
      ctx.db
        .get("SELECT * FROM challs WHERE flag = :flag", flag)
        .then((challenge) => {
          if (!challenge) reject(new Error("Invalid Flag Submission!"));

          let user = ctx.username();

          ctx.db
            .get(
              "SELECT * FROM solves WHERE challenge = :challenge AND user = :user",
              {
                ":challenge": challenge.id,
                ":user": user,
              }
            )
            .then((existing_solve) => {
              if (existing_solve)
                reject(new Error("Challenge already solved!"));
            });

          ctx.db
            .run(
              "INSERT INTO solves (challenge, user) VALUES (:challenge, :user)",
              {
                ":challenge": challenge.id,
                ":user": user,
              }
            )
            .then((result) =>
              resolve(
                new Solve(result.lastID, { user, challenge: challenge.id })
              )
            );
        });
    }),
};

Promise.all([
  open({ filename: ":memory:", driver: sqlite3.Database }).then(async (db) => {
    await db.run("PRAGMA foreign_keys=on");
    await db.migrate({ migrationsPath: "./migrations" });
    await db.run("UPDATE users SET password = :hash WHERE admin = 1", {
      ":hash": bcrypt.hashSync(ADMINPW, 10),
    });
    await db.run("UPDATE challs SET flag = :flag WHERE id = 1", {
      ":flag": FLAG,
    });
    return db;
  }),
  loadSchema("src/schema.gql", {
    loaders: [new GraphQLFileLoader()],
  }),
])
  .then(([db, schema]) => {
    const app = express();
    app.use(express.static(path.join(__dirname, "/../app")));
    app.use(
      session({
        secret: "keyboard cat",
        cookie: { maxAge: 24 * 60 * 60 * 1000 },
        resave: false,
        saveUninitialized: true,
      })
    );
    app.use(
      "/graphql",
      graphqlHTTP(
        (
          request: IncomingMessage & {
            url: string;
            session: session.Session & { username: string; admin: boolean };
          }
        ) => {
          return {
            graphiql: true,
            pretty: true,
            schema,
            rootValue: root,
            context: {
              db: {
                get: (sql: ISqlite.SqlType, ...args) => db.get(sql, ...args),
                all: (sql: ISqlite.SqlType, ...args: any) =>
                  db.all(sql, ...args),
                run: (sql: ISqlite.SqlType, ...args) => db.run(sql, ...args),
              },
              username: () => request.session.username,
              admin: () => request.session.admin || false,
              session: request.session,
            },
          };
        }
      )
    );

    app.listen(PORT, () => {
      console.log(`GraphQL server is now running on http://localhost:${PORT}`);
    });
  })
  .catch((e) => console.error(e));

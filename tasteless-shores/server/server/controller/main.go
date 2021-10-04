package main

import (
	"context"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"strconv"
	"strings"
	"ts/server/controller/api"

	_ "github.com/mattn/go-sqlite3"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"golang.org/x/crypto/bcrypt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

var (
	pPlayers = prometheus.NewCounterVec(prometheus.CounterOpts{
		Name: "ts_players",
	}, []string{"team"})

	pShards = prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "ts_shards",
	}, []string{"host"})

	pOnline = prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "ts_online",
	}, []string{"team", "area"})
)

func init() {
	prometheus.MustRegister(pPlayers)
	prometheus.MustRegister(pShards)
	prometheus.MustRegister(pOnline)
}

var events = make(chan *api.AdminEvent, 100)
var servers = make(map[string]server)
var shards = make(map[uint64]shard)
var players = make(map[uint64]player)

type server struct {
	event chan string
}

type shard struct {
	host string
	area uint32
}

type player struct {
	shard uint64
}

func dispatch(event *api.AdminEvent) {
	select {
	case events <- event:
	default:
	}
}

type impl struct {
	api.UnimplementedControllerServer
}

func (impl *impl) Events(req *api.EventsRequest, client api.Controller_EventsServer) error {
	dispatch(&api.AdminEvent{Event: "addServer", Data: req.Host, Host: req.Host})

	events := make(chan string)
	servers[req.Host] = server{
		event: events,
	}

eventloop:
	for {
		select {
		case event := <-events:
			client.Send(&api.Event{
				Event: event,
			})
		case <-client.Context().Done():
			break eventloop
		}
	}

	delete(servers, req.Host)
	dispatch(&api.AdminEvent{Event: "rmServer", Data: req.Host, Host: req.Host})
	return nil
}

func (impl *impl) Auth(ctx context.Context, req *api.AuthRequest) (*api.Player, error) {
	dispatch(&api.AdminEvent{Event: "auth", Data: req.User, Host: req.Host})

	row := db.QueryRowContext(ctx, `SELECT id, pass, char, area, team FROM users WHERE user = ?`, req.User)

	p := new(api.Player)
	var pw string
	if err := row.Scan(&p.Id, &pw, &p.Char, &p.Area, &p.Team); err != nil {
		return nil, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(pw), []byte(req.Password)); err != nil {
		return nil, err
	}

	if _, ok := players[p.Id]; ok {
		if s, ok := servers[shards[players[p.Id].shard].host]; ok {
			s.event <- "kick " + strconv.FormatUint(p.Id, 10)
		}
	}
	players[p.Id] = player{}

	rows, err := db.QueryContext(ctx, `SELECT marker FROM markers WHERE id = ?`, p.Id)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var marker string
		if err := rows.Scan(&marker); err != nil {
			return nil, err
		}
		p.Marker = append(p.Marker, marker)
	}

	return p, nil
}

func (impl *impl) Inventory(ctx context.Context, req *api.InventoryRequest) (*api.InventoryResponse, error) {
	dispatch(&api.AdminEvent{Event: "inventory", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})

	rows, err := db.QueryContext(ctx, `SELECT item FROM items WHERE id = ?`, req.Id)
	if err != nil {
		return nil, err
	}
	inventory := new(api.InventoryResponse)
	for rows.Next() {
		var item uint64
		if err := rows.Scan(&item); err != nil {
			return nil, err
		}
		inventory.Items = append(inventory.Items, item)
	}

	return inventory, nil
}

func (impl *impl) AddItem(ctx context.Context, req *api.AddItemRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "item", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})

	if _, err := db.ExecContext(ctx, `INSERT INTO items (id, item) VALUES (?, ?)`, req.Id, req.Item); err != nil {
		log.Println(err)
	}
	return &api.EmptyResponse{}, nil
}

func (impl *impl) AddMarker(ctx context.Context, req *api.AddMarkerRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "marker", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})

	db.ExecContext(ctx, `INSERT INTO markers (id, marker) VALUES (?, ?)`, req.Id, req.Marker)
	return &api.EmptyResponse{}, nil
}

func (impl *impl) ChangeArea(ctx context.Context, req *api.ChangeAreaRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "area", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})

	db.ExecContext(ctx, `UPDATE users SET area = ? WHERE id = ?`, req.Area, req.Id)
	return &api.EmptyResponse{}, nil
}

func (impl *impl) ChangeChar(ctx context.Context, req *api.ChangeCharRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "char", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})

	db.ExecContext(ctx, `UPDATE users SET char = ? WHERE id = ?`, req.Char, req.Id)
	return &api.EmptyResponse{}, nil
}

func (impl *impl) AddShard(ctx context.Context, req *api.AddShardRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "addShard", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})
	shards[req.Id] = shard{
		host: req.Host,
	}
	pShards.WithLabelValues(req.Host).Add(1)
	return &api.EmptyResponse{}, nil
}
func (impl *impl) RmShard(ctx context.Context, req *api.RmShardRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "rmShard", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})
	delete(shards, req.Id)
	pShards.WithLabelValues(req.Host).Add(-1)
	return &api.EmptyResponse{}, nil
}
func (impl *impl) MoveShard(ctx context.Context, req *api.MoveShardRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "moveShard", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})
	shard := shards[req.Id]
	shard.area = req.Area
	shards[req.Id] = shard
	return &api.EmptyResponse{}, nil
}
func (impl *impl) MoveUser(ctx context.Context, req *api.MoveUserRequest) (*api.EmptyResponse, error) {
	dispatch(&api.AdminEvent{Event: "moveUser", Data: strconv.FormatUint(req.Id, 10), Host: req.Host})
	players[req.Id] = player{req.Shard}
	return &api.EmptyResponse{}, nil
}

var db *sql.DB

func init() {
	var err error
	db, err = sql.Open("sqlite3", "file:/tmp/ts.sqlite")
	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY,
		user VARCHAR(255),
		pass VARCHAR(100),
		char INTEGER,
		area INTEGER,
		team VARCHAR(255)
	);
	CREATE UNIQUE INDEX IF NOT EXISTS user ON users(user);

	CREATE TABLE IF NOT EXISTS teams (
		id INTEGER,
		team VARCHAR(255)
	);
	
	CREATE TABLE IF NOT EXISTS markers (
		id INTEGER,
		marker VARCHAR(255)
	);
	CREATE UNIQUE INDEX IF NOT EXISTS marker ON markers(id, marker);

	CREATE TABLE IF NOT EXISTS items (
		id INTEGER,
		item INTEGER
	);
	CREATE UNIQUE INDEX IF NOT EXISTS item ON items(id, item);
`)
	if err != nil {
		panic(err)
	}
}

type admin struct {
	api.UnimplementedAdminServer
}

func (*admin) Users(ctx context.Context, _ *api.EmptyRequest) (*api.AdminUsersResponse, error) {
	rows, err := db.QueryContext(ctx, `SELECT id, user, char, area FROM users`)
	if err != nil {
		return nil, err
	}
	response := new(api.AdminUsersResponse)
	for rows.Next() {
		player := &api.AdminUser{
			Player: new(api.Player),
		}
		if err := rows.Scan(&player.Player.Id, &player.User, &player.Player.Char, &player.Player.Area); err != nil {
			return nil, err
		}
		response.Users = append(response.Users, player)
	}
	return response, nil
}

func (*admin) Events(_ *api.EmptyRequest, client api.Admin_EventsServer) error {
	for server := range servers {
		client.Send(&api.AdminEvent{Event: "addServer", Data: server, Host: server})
	}
	for shard, s := range shards {
		client.Send(&api.AdminEvent{Event: "addShard", Data: strconv.FormatUint(shard, 10), Host: s.host})
	}
	for shard, s := range shards {
		client.Send(&api.AdminEvent{Event: "moveShard", Data: strconv.FormatUint(shard, 10) + " " + strconv.Itoa(int(s.area)), Host: s.host})
	}
eventloop:
	for {
		select {
		case event := <-events:
			client.Send(event)
		case <-client.Context().Done():
			break eventloop
		}
	}
	return nil
}

func (*admin) Command(ctx context.Context, req *api.CommandRequest) (*api.EmptyResponse, error) {
	a := strings.Split(req.Cmd, " ")
	switch a[0] {
	case "kick":
		id, _ := strconv.ParseUint(a[1], 10, 64)
		if p, ok := players[id]; ok {
			servers[shards[p.shard].host].event <- req.Cmd
		}
	case "mark":
		id, _ := strconv.ParseUint(a[1], 10, 64)
		db.ExecContext(ctx, `INSERT INTO markers (id, marker) VALUES (?, ?)`, id, a[2])
	}
	return &api.EmptyResponse{}, nil
}

func main() {
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())
	go func() { log.Fatal(http.ListenAndServe(":9101", mux)) }()

	http.HandleFunc("/server", func(rw http.ResponseWriter, r *http.Request) {
		var s struct {
			Servers []string `json:"servers"`
		}
		for server := range servers {
			s.Servers = append(s.Servers, server)
		}
		json.NewEncoder(rw).Encode(s)
	})
	http.HandleFunc("/registration", func(rw http.ResponseWriter, r *http.Request) {
		if r.Method == "POST" {
			user, pw, token := strings.TrimSpace(r.FormValue("user")), strings.TrimSpace(r.FormValue("pass")), strings.TrimSpace(r.FormValue("token"))
			if user == "" || pw == "" || token == "" {
				return
			}
			if len(pw) < 8 {
				fmt.Fprintf(rw, "password too short")
				return
			}
			var t = strings.Split(token, ":")
			if len(t) != 2 {
				fmt.Fprintf(rw, "invalid token")
				return
			}
			h := sha256.Sum256([]byte("1273131DYSGYU@G@*e78wgPreSharedKeysAreLife" + t[0] + "OhBoyHopeThisWorksWTF??"))
			if hex.EncodeToString(h[:]) != t[1] {
				fmt.Fprintf(rw, "invalid token")
				return
			}

			b, err := bcrypt.GenerateFromPassword([]byte(pw), bcrypt.DefaultCost)
			if err != nil {
				fmt.Fprintf(rw, "invalid password")
				return
			}
			pw = string(b)
			if _, err := db.ExecContext(r.Context(), `INSERT INTO users (user, pass, char, area, team) VALUES (?, ?, 0, 0, ?)`, user, pw, t[0]); err != nil {
				log.Println(err)
				fmt.Fprintf(rw, "invalid user")
				return
			}
			fmt.Fprint(rw, `Registered`)
			return
		}
		fmt.Fprint(rw, `<html>
Register new player account
<form method="post">
Token: <input name="token" placeholder="team:token" size=30/><br/>
User: <input name="user" placeholder="user" size=30 /><br/>
Password: <input name="pass" placeholder="password" size=30 /><br/>
<button type="submit">Register</button><br/>
</form>
</html>`)
	})
	go http.ListenAndServe(":13380", nil)

	certificate, err := tls.LoadX509KeyPair(
		"auth/ts.tasteless.eu.crt",
		"auth/ts.tasteless.eu.key",
	)

	certPool := x509.NewCertPool()
	bs, err := ioutil.ReadFile("auth/TastelessShores.crt")
	if err != nil {
		log.Fatalf("failed to read client ca cert: %s", err)
	}

	ok := certPool.AppendCertsFromPEM(bs)
	if !ok {
		log.Fatal("failed to append client certs")
	}

	tlsConfig := &tls.Config{
		ClientAuth:   tls.RequireAndVerifyClientCert,
		Certificates: []tls.Certificate{certificate},
		ClientCAs:    certPool,
	}

	server := grpc.NewServer(grpc.Creds(credentials.NewTLS(tlsConfig)))
	api.RegisterControllerServer(server, &impl{})
	api.RegisterAdminServer(server, &admin{})
	l, err := net.Listen("tcp", ":1337")
	if err != nil {
		panic(err)
	}
	server.Serve(l)
}

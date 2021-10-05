package ts

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"flag"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
	"ts/server/controller/api"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

var Controller = connectController()

type controller interface {
	auth(user, pass string) *api.Player
	inventory(uid uint64) []uint64
	addItem(uid, item uint64)
	addMarker(uid uint64, marker string)
	changeArea(uid uint64, area uint8)
	changeChar(uid uint64, char uint8)
	addShard(id uint64)
	rmShard(id uint64)
	moveShard(id uint64, area uint32)
	moveUser(uid, shard uint64, area uint32)
}

type localController struct {
	player *api.Player
	inv    []uint64
}

func connectController() controller {
	ma := flag.String("controller", "", "controller server")
	key := flag.String("key", "", "controller key")
	host, err := os.Hostname()
	if err != nil {
		panic(err)
	}
	name := flag.String("name", host, "name")
	flag.Parse()

	if ma == nil || *ma == "" {
		return &localController{
			player: &api.Player{
				Id:     rand.Uint64(),
				Team:   "Local",
				Char:   6,
				Marker: []string{"FLAG_EYES"},
				Area:   0,
			},
			inv: []uint64{3},
		}
	}

	return newRemoteController(*ma, *name, *key)
}

func (controller *localController) auth(user, pass string) *api.Player {
	controller.player.Id = rand.Uint64()
	return controller.player
}

func (controller *localController) inventory(uid uint64) []uint64 {
	return controller.inv
}

func (controller *localController) addItem(id, item uint64) {
	controller.inv = append(controller.inv, item)
}

func (controller *localController) addMarker(id uint64, marker string) {
	if contains(controller.player.Marker, marker) {
		return
	}
	controller.player.Marker = append(controller.player.Marker, marker)
}

func (controller *localController) changeArea(id uint64, area uint8) {
	controller.player.Area = uint32(area)
}

func (controller *localController) changeChar(id uint64, char uint8) {
	controller.player.Char = uint32(char)
}

func (controller *localController) addShard(id uint64)                      {}
func (controller *localController) rmShard(id uint64)                       {}
func (controller *localController) moveShard(id uint64, area uint32)        {}
func (controller *localController) moveUser(uid, shard uint64, area uint32) {}

type remoteController struct {
	addr   string
	host   string
	client api.ControllerClient
}

func newRemoteController(addr, name, key string) controller {
	certificate, err := tls.LoadX509KeyPair(
		"auth/"+key+".crt",
		"auth/"+key+".key",
	)
	if err != nil {
		log.Fatalf("failed to read certs: %s", err)
	}

	certPool := x509.NewCertPool()
	bs, err := ioutil.ReadFile("auth/TastelessShores.crt")
	if err != nil {
		log.Fatalf("failed to read ca cert: %s", err)
	}

	ok := certPool.AppendCertsFromPEM(bs)
	if !ok {
		log.Fatal("failed to append certs")
	}

	transportCreds := credentials.NewTLS(&tls.Config{
		ServerName:   "ts.tasteless.eu",
		Certificates: []tls.Certificate{certificate},
		RootCAs:      certPool,
	})

	dialOption := grpc.WithTransportCredentials(transportCreds)

	cc, err := grpc.Dial(addr, dialOption)
	if err != nil {
		panic(err)
	}
	m := &remoteController{
		addr:   addr,
		client: api.NewControllerClient(cc),
		host:   name,
	}
	go m.eventHandler()
	time.Sleep(1 * time.Second)
	return m
}

func (m *remoteController) eventHandler() {
	for {
		events, err := m.client.Events(context.Background(), &api.EventsRequest{
			Host: m.host,
		})
		if err != nil {
			log.Println(err)
			time.Sleep(1 * time.Second)
			continue
		}

		time.Sleep(1 * time.Second)

		for _, shard := range SM.server {
			m.addShard(shard.id)
		}

		for {
			msg, err := events.Recv()
			if err != nil {
				break
			}
			a := strings.Split(msg.Event, " ")
			switch a[0] {
			case "kick":
				id, _ := strconv.ParseUint(a[1], 10, 64)
				SM.lock.Lock()
				for _, s := range SM.server {
					if p, ok := s.players[id]; ok {
						go p.kick()
					}
				}
				SM.lock.Unlock()
			}
		}
	}
}

func (controller *remoteController) auth(user, pass string) *api.Player {
	resp, err := controller.client.Auth(context.Background(), &api.AuthRequest{
		User:     user,
		Password: pass,
		Host:     controller.host,
	})
	if err != nil {
		log.Println(err)
	}
	return resp
}

func (controller *remoteController) inventory(uid uint64) []uint64 {
	resp, err := controller.client.Inventory(context.Background(), &api.InventoryRequest{
		Id:   uid,
		Host: controller.host,
	})
	if err != nil {
		log.Println(err)
	}
	if len(resp.GetItems()) == 0 {
		controller.addItem(uid, 3)
		return []uint64{3}
	}
	return resp.GetItems()
}

func (controller *remoteController) addItem(id, item uint64) {
	_, err := controller.client.AddItem(context.Background(), &api.AddItemRequest{
		Id:   id,
		Item: item,
		Host: controller.host,
	})
	if err != nil {
		log.Println(err)
	}
}

func (controller *remoteController) addMarker(id uint64, marker string) {
	_, err := controller.client.AddMarker(context.Background(), &api.AddMarkerRequest{
		Id:     id,
		Marker: marker,
		Host:   controller.host,
	})
	if err != nil {
		log.Println(err)
	}
}

func (controller *remoteController) changeArea(id uint64, area uint8) {
	_, err := controller.client.ChangeArea(context.Background(), &api.ChangeAreaRequest{
		Id:   id,
		Area: uint32(area),
		Host: controller.host,
	})
	if err != nil {
		log.Println(err)
	}
}

func (controller *remoteController) changeChar(id uint64, char uint8) {
	_, err := controller.client.ChangeChar(context.Background(), &api.ChangeCharRequest{
		Id:   id,
		Char: uint32(char),
		Host: controller.host,
	})
	if err != nil {
		log.Println(err)
	}
}

func (controller *remoteController) addShard(id uint64) {
	controller.client.AddShard(context.Background(), &api.AddShardRequest{Id: id, Host: controller.host})
}
func (controller *remoteController) rmShard(id uint64) {
	controller.client.RmShard(context.Background(), &api.RmShardRequest{Id: id, Host: controller.host})
}
func (controller *remoteController) moveShard(id uint64, area uint32) {
	controller.client.MoveShard(context.Background(), &api.MoveShardRequest{Id: id, Area: area, Host: controller.host})
}
func (controller *remoteController) moveUser(uid, shard uint64, area uint32) {
	controller.client.MoveUser(context.Background(), &api.MoveUserRequest{Id: uid, Area: area, Shard: shard, Host: controller.host})
}

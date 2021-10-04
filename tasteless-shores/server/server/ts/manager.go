package ts

import (
	"log"
	"os/exec"
	"sync"
	"time"
)

type ServerManager struct {
	lock     sync.RWMutex
	server   []*Server
	spawning sync.Once
}

func (sm *ServerManager) Add(s *Server) {
	sm.lock.Lock()
	defer sm.lock.Unlock()

	sm.spawning = sync.Once{}

	log.Println("Adding ", s)
	Controller.addShard(s.id)

	sm.server = append(sm.server, s)

	go func() {
		<-s.closed
		sm.Remove(s)
	}()
}

func (sm *ServerManager) Remove(s *Server) {
	sm.lock.Lock()

	log.Println("Removing ", s)
	Controller.rmShard(s.id)

	for i, sn := range sm.server {
		if s == sn {
			sm.server = append(sm.server[:i], sm.server[i+1:]...)
			break
		}
	}

	sm.lock.Unlock()

	for _, p := range s.players {
		sm.AddPlayer(p)
		p.send(ServerMessageChat{
			Msg: "tasteless server is no good server, please retry whatever you were doing",
		})
	}
}

func (sm *ServerManager) spawnServer() {
	sm.spawning.Do(func() {
		log.Println("spawning server...")
		exec := exec.Command("/Applications/Godot.app/Contents/MacOS/Godot", "--print-fps", "--path", "..", "server")
		exec.Start()
	})
	time.Sleep(10 * time.Second)
}

func (sm *ServerManager) findServer(player *Player) *Server {
	log.Println(player, "finding server")
	sm.lock.Lock()

	// find matching server
	for _, s := range sm.server {
		if s.area == player.area && len(s.players) < 50 {
			sm.lock.Unlock()
			return s
		}
	}

	// find free server
	for _, s := range sm.server {
		if len(s.players) == 0 {
			s.area = player.area
			Controller.moveShard(s.id, uint32(s.area))
			sm.lock.Unlock()
			return s
		}
	}

	// fallback to free server
	for _, s := range sm.server {
		if len(s.players) < 50 {
			sm.lock.Unlock()
			return s
		}
	}
	sm.lock.Unlock()

	return nil
}

func (sm *ServerManager) AddPlayer(player *Player) {
	player.lock.Lock()
	defer player.lock.Unlock()

	if player.server != nil {
		player.server.playerLock.Lock()
		delete(player.server.players, player.id)
		player.server.send(ServerMessageLeave{
			id: player.id,
		})
		if !player.server.solo {
			for _, p := range player.server.players {
				p.send(ServerMessageLeave{
					id: player.id,
				})
			}
		}
		player.server.playerLock.Unlock()
	}

	player.server = sm.findServer(player)
	if player.server == nil {
		log.Println("no server available", player)
		player.kick()
		return
	}
	player.server.playerLock.Lock()
	defer player.server.playerLock.Unlock()

	Controller.moveUser(player.id, player.server.id, uint32(player.area))
	log.Println("adding", player, "to", player.server)

	player.server.players[player.id] = player
	player.server.send(ServerMessageJoin{
		id:     player.id,
		name:   player.name,
		team:   player.team,
		char:   player.char,
		marker: player.marker,
		x:      player.x,
		y:      player.y,
		z:      player.z,
	})
	if !player.server.solo {
		for _, p := range player.server.players {
			player.send(ServerMessageJoin{
				id:     p.id,
				name:   p.name,
				team:   p.team,
				char:   p.char,
				marker: p.marker,
				x:      p.x,
				y:      p.y,
				z:      p.z,
			})
			player.send(ServerMessageEquip{
				id:   p.id,
				item: p.weapon,
			})
			p.send(ServerMessageJoin{
				id:     player.id,
				name:   player.name,
				team:   player.team,
				char:   player.char,
				marker: player.marker,
				x:      player.x,
				y:      player.y,
				z:      player.z,
			})
		}
	}
	for id, e := range player.server.enemies {
		player.send(ServerMessageSpawn{
			id:  id,
			typ: e.typ,
			x:   e.x,
			y:   e.y,
			z:   e.z,
		})
		player.send(ServerMessageTarget{
			id: id,
			x:  e.tx,
			y:  e.ty,
			z:  e.tz,
		})
	}
}

func (sm *ServerManager) RemovePlayer(player *Player) {
	player.lock.Lock()
	defer player.lock.Unlock()

	if player.server != nil {
		player.server.playerLock.Lock()
		defer player.server.playerLock.Unlock()

		delete(player.server.players, player.id)
		player.server.send(ServerMessageLeave{
			id: player.id,
		})
		if !player.server.solo {
			for _, p := range player.server.players {
				p.send(ServerMessageLeave{
					id: player.id,
				})
			}
		}
		player.server = nil

		log.Println("kicked", player)
	}
}

var SM = &ServerManager{}

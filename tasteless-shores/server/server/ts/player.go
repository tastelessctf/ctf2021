package ts

import (
	"fmt"
	"log"
	"net"
	gdebug "runtime/debug"
	"sync"
	"time"
)

type ClientMessage interface {
	_clientMessage()
}

type ClientMessageJoin struct {
	char uint8
}

func (ClientMessageJoin) _clientMessage() {}

type ClientMessageUpdatePlayer struct {
	x, y, z  float64
	rotation float64
}

func (ClientMessageUpdatePlayer) _clientMessage() {}

type ClientMessageAttack struct {
	target uint64
}

func (ClientMessageAttack) _clientMessage() {}

type ClientMessageEquip struct {
	item uint8
}

func (ClientMessageEquip) _clientMessage() {}

type ClientMessageFish struct {
}

func (ClientMessageFish) _clientMessage() {}

type ClientMessageTryFlag struct {
	flag string
}

func (ClientMessageTryFlag) _clientMessage() {}

type ClientMessageChat struct {
	whisper uint64
	msg     string
}

func (ClientMessageChat) _clientMessage() {}

type ClientMessageBldPlace struct {
	bldid    uint64
	x, y, z  float64
	rotation float64
	data     string
}

func (ClientMessageBldPlace) _clientMessage() {}

type ClientMessageAuth struct {
	user string
	pw   string
}

func (ClientMessageAuth) _clientMessage() {}

type ClientMessageInteract struct {
	id uint64
}

func (ClientMessageInteract) _clientMessage() {}

type ClientMessageTogglePVP struct{}

func (ClientMessageTogglePVP) _clientMessage() {}

type ClientMessagePing struct{}

func (ClientMessagePing) _clientMessage() {}

type Player struct {
	lock      sync.RWMutex
	server    *Server
	id        uint64
	char      uint8
	name      string
	conn      net.Conn
	out       chan ServerMessage
	x, y, z   float64
	rotation  float64
	team      string
	solo      bool
	buildings []ServerMessageBld
	health    float64
	weapon    uint8
	marker    []string
	area      uint8
}

func (player *Player) String() string {
	return fmt.Sprintf("[%d] %s <%s>", player.id, player.name, player.team)
}

func (p *Player) readMsg() (ClientMessage, error) {
	cmd, err := readUint8(p.conn)
	if err != nil {
		return nil, err
	}
	switch cmd {
	case MsgClientJoin:
		char, err := readUint8(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageJoin{
			char: char,
		}, nil
	case MsgClientUpdatePlayer:
		x, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		rotation, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		if x < -1000 {
			x = -1000
		} else if x > 1000 {
			x = 1000
		}
		if y < -200 {
			y = -200
		} else if y > 200 {
			y = 200
		}
		if z < -1000 {
			z = -1000
		} else if z > 1000 {
			z = 1000
		}
		if rotation < -10 {
			rotation = -10
		} else if rotation > 10 {
			rotation = 10
		}
		return ClientMessageUpdatePlayer{
			x:        x,
			y:        y,
			z:        z,
			rotation: rotation,
		}, nil
	case MsgClientAttack:
		target, err := readUint64(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageAttack{
			target: target,
		}, nil
	case MsgClientEquip:
		item, err := readUint8(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageEquip{
			item: item,
		}, nil
	case MsgClientFish:
		return ClientMessageFish{}, nil
	case MsgClientTryFlag:
		flag, err := readString(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageTryFlag{
			flag: flag,
		}, nil
	case MsgClientChat:
		whisper, err := readUint64(p.conn)
		if err != nil {
			return nil, err
		}
		msg, err := readString(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageChat{
			whisper: whisper,
			msg:     msg,
		}, nil
	case MsgClientBldPlace:
		bldid, err := readUint64(p.conn)
		if err != nil {
			return nil, err
		}
		x, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		r, err := readFloat64(p.conn)
		if err != nil {
			return nil, err
		}
		data, err := readString(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageBldPlace{
			bldid:    bldid,
			x:        x,
			y:        y,
			z:        z,
			rotation: r,
			data:     data,
		}, nil
	case MsgClientAuth:
		user, err := readString(p.conn)
		if err != nil {
			return nil, err
		}
		pw, err := readString(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageAuth{
			user: user,
			pw:   pw,
		}, nil
	case MsgClientInteract:
		id, err := readUint64(p.conn)
		if err != nil {
			return nil, err
		}
		return ClientMessageInteract{
			id: id,
		}, nil
	case MsgClientTogglePVP:
		return ClientMessageTogglePVP{}, nil
	case MsgClientPing:
		return ClientMessagePing{}, nil
	default:
		log.Println("Unknown command: ", cmd)
		return nil, fmt.Errorf("unknown command")
	}
}

func (p *Player) writePump() error {
	for message := range p.out {
		if _, ok := message.(ServerMessageUpdatePlayers); debug > 0 && !ok {
			log.Printf("server > player %d: %#v", p.id, message)
		} else if debug > 1 && ok {
			log.Printf("server > player %d: %#v", p.id, message)
		}
		if err := message._serverMessage(p.conn); err != nil {
			return err
		}
	}
	return nil
}

func (p *Player) send(message ServerMessage) {
	select {
	case p.out <- message:
	default:
		log.Println("player output channel clogged, disconnecting")
		p.kick()
		return
	}
}

func (p *Player) sendUnreliable(message ServerMessage) {
	if len(p.out) > 0 {
		return
	}
	select {
	case p.out <- message:
	default:
	}
}

func (p *Player) sendServer(message ServerMessage) {
	p.lock.RLock()
	defer p.lock.RUnlock()

	p.server.send(message)
}

func (p *Player) kick() {
	log.Println("kicking", p)
	p.conn.Close()
	go SM.RemovePlayer(p)
}

func HandlePlayerConn(conn net.Conn) {
	defer func() {
		if err := recover(); err != nil {
			log.Println("CLIENT PANIC! ", err)
			gdebug.PrintStack()
		}
	}()

	conn.SetDeadline(time.Now().Add(30 * time.Second))

	player := &Player{
		name: "",
		conn: conn,
		out:  make(chan ServerMessage, 500),
		id:   0,
		team: "",
		solo: false,
	}

	handshake := make([]byte, 8)
	n, err := conn.Read(handshake)
	if err != nil {
		log.Println("No handshake received", err)
		return
	}
	if n != 8 {
		log.Println("Didn't get 8 bytes")
		return
	}
	if string(handshake) != "pirates!" {
		log.Println("wrong handshake", string(handshake))
		return
	}

	go func(player *Player) {
		if err := player.writePump(); err != nil {
			log.Println(player, "writePump", err)
		}
		player.conn.Close()
	}(player)

	for {
		time.Sleep(50 * time.Millisecond)

		message, err := player.readMsg()
		if err != nil {
			log.Println(err)
			break
		}

		if _, ok := message.(ClientMessageUpdatePlayer); debug > 0 && !ok {
			log.Printf("player %d > server: %#v", player.id, message)
		} else if debug > 1 && ok {
			log.Printf("player %d > server: %#v", player.id, message)
		}

		if player.name == "" {
			_, loginMsg := message.(ClientMessageAuth)
			if !loginMsg {
				log.Println("missing login", player, message)
				player.conn.Close()
			}
		}

		conn.SetDeadline(time.Now().Add(30 * time.Second))

		switch message := message.(type) {
		case ClientMessageAuth:
			if p := Controller.auth(message.user, message.pw); p != nil {
				if player.id != 0 {
					log.Println("double login", player, message)
					player.conn.Close()
					break
				}
				player.id = p.Id
				player.name = message.user
				player.team = p.Team
				player.char = uint8(p.Char)
				player.marker = p.Marker
				player.area = uint8(p.Area)
				player.send(ServerMessageAccount{
					char: player.char,
				})
			} else {
				log.Println("user not logged in")
				player.conn.Close()
			}
		case ClientMessageJoin:
			player.char = message.char

			Controller.changeChar(player.id, player.char)

			player.updatePos()
			player.health = 100

			player.send(ServerMessageLoggedIn{
				id:   player.id,
				name: player.name,
				team: player.team,
				x:    player.x,
				y:    player.y,
				z:    player.z,
			})
			SM.AddPlayer(player)
			for _, item := range Controller.inventory(player.id) {
				player.send(ServerMessageItem{
					id:   player.id,
					item: item,
				})
			}
			for _, building := range player.buildings {
				player.sendServer(ServerMessageBld{
					id:    player.id,
					bldid: building.bldid,
					x:     building.x,
					y:     building.y,
					z:     building.z,
					r:     building.r,
					data:  building.data,
				})
			}
		case ClientMessageUpdatePlayer:
			player.lock.Lock()
			player.x = message.x
			player.y = message.y
			player.z = message.z
			player.rotation = message.rotation
			player.lock.Unlock()
			update := player.server.updatePlayerPacket(player)
			player.lock.RLock()
			player.sendUnreliable(update)
			player.lock.RUnlock()
		case ClientMessageAttack:
			player.sendServer(ServerMessageAttack{
				id:     player.id,
				target: message.target,
			})
		case ClientMessageEquip:
			player.sendServer(ServerMessageEquip{
				id:   player.id,
				item: message.item,
			})
		case ClientMessageFish:
			player.sendServer(ServerMessageFish{
				id: player.id,
			})
		case ClientMessageTryFlag:
			player.sendServer(ServerMessageTryFlag{
				id:   player.id,
				flag: message.flag,
			})
		case ClientMessageChat:
			player.sendServer(ServerMessageChat{
				id:      player.id,
				whisper: message.whisper,
				Msg:     message.msg,
			})
		case ClientMessageBldPlace:
			if message.bldid != 0x1337 {
				player.sendServer(ServerMessageBld{
					id:    player.id,
					bldid: message.bldid,
					x:     message.x,
					y:     message.y,
					z:     message.z,
					r:     message.rotation,
					data:  message.data,
				})
			}
		case ClientMessageInteract:
			player.sendServer(ServerMessageInteract{
				id:     player.id,
				target: message.id,
			})
		case ClientMessageTogglePVP:
			player.sendServer(ServerMessageTogglePVP{
				id: player.id,
			})
		}
	}

	player.kick()
}

func (player *Player) updatePos() {
	switch player.area {
	case 1:
		player.x = -36
		player.y = 10
		player.z = 46
	case 2:
		player.x = -743
		player.y = 11
		player.z = -302
	case 3:
		player.x = 493
		player.y = 11
		player.z = -579
	case 4:
		player.x = 661
		player.y = 6
		player.z = 431
	default:
		player.x = -380
		player.y = 7
		player.z = 650
	}
}

package ts

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"math"
	"math/rand"
	"net"
	"sync"
	"sync/atomic"
	"time"
)

type ServerMessage interface {
	_serverMessage(conn io.Writer) error
}

type ServerMessageJoin struct {
	id      uint64
	name    string
	team    string
	char    uint8
	x, y, z float64
	marker  []string
}

func (message ServerMessageJoin) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerJoin); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeString(w, message.name); err != nil {
		return err
	}
	if err := writeString(w, message.team); err != nil {
		return err
	}
	if err := writeUint8(w, message.char); err != nil {
		return err
	}
	if err := writeFloat64(w, message.x); err != nil {
		return err
	}
	if err := writeFloat64(w, message.y); err != nil {
		return err
	}
	if err := writeFloat64(w, message.z); err != nil {
		return err
	}
	if err := writeUint8(w, uint8(len(message.marker))); err != nil {
		return err
	}
	for _, m := range message.marker {
		if err := writeString(w, m); err != nil {
			return err
		}
	}
	return nil
}

type ServerMessageLeave struct {
	id uint64
}

func (message ServerMessageLeave) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerLeave); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	return nil
}

type ServerMessageUpdatePlayers []ServerMessageUpdatePlayer

func (message ServerMessageUpdatePlayers) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerUpdatePlayers); err != nil {
		return err
	}
	if err := writeUint8(w, uint8(len(message))); err != nil {
		return err
	}
	for _, message := range message {
		if err := writeUint64(w, message.id); err != nil {
			return err
		}
		if err := writeFloat64(w, message.x); err != nil {
			return err
		}
		if err := writeFloat64(w, message.y); err != nil {
			return err
		}
		if err := writeFloat64(w, message.z); err != nil {
			return err
		}
		if err := writeFloat64(w, message.rotation); err != nil {
			return err
		}
		if err := writeFloat64(w, message.health); err != nil {
			return err
		}
		if err := writeUint8(w, message.weapon); err != nil {
			return err
		}
	}
	return nil
}

type ServerMessageUpdatePlayer struct {
	id       uint64
	x, y, z  float64
	rotation float64
	health   float64
	weapon   uint8
}

func (message ServerMessageUpdatePlayer) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerUpdatePlayer); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeFloat64(w, message.x); err != nil {
		return err
	}
	if err := writeFloat64(w, message.y); err != nil {
		return err
	}
	if err := writeFloat64(w, message.z); err != nil {
		return err
	}
	if err := writeFloat64(w, message.rotation); err != nil {
		return err
	}
	if err := writeFloat64(w, message.health); err != nil {
		return err
	}
	if err := writeUint8(w, message.weapon); err != nil {
		return err
	}
	return nil
}

type ServerMessageAttack struct {
	id     uint64
	target uint64
}

func (message ServerMessageAttack) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerAttack); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint64(w, message.target); err != nil {
		return err
	}
	return nil
}

type ServerMessageLoggedIn struct {
	id         uint64
	x, y, z    float64
	name, team string
}

func (message ServerMessageLoggedIn) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerLoggedIn); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeFloat64(w, message.x); err != nil {
		return err
	}
	if err := writeFloat64(w, message.y); err != nil {
		return err
	}
	if err := writeFloat64(w, message.z); err != nil {
		return err
	}
	if err := writeString(w, message.name); err != nil {
		return err
	}
	if err := writeString(w, message.team); err != nil {
		return err
	}
	return nil
}

type ServerMessageFrame struct{}

func (message ServerMessageFrame) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerFrame); err != nil {
		return err
	}
	return nil
}

type ServerMessageDie struct {
	id uint64
}

func (message ServerMessageDie) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerDie); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	return nil
}

type ServerMessageEquip struct {
	id   uint64
	item uint8
}

func (message ServerMessageEquip) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerEquip); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint8(w, message.item); err != nil {
		return err
	}
	return nil
}

type ServerMessageDamage struct {
	id     uint64
	amount float64
	from   uint64
}

func (message ServerMessageDamage) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerDamage); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeFloat64(w, message.amount); err != nil {
		return err
	}
	if err := writeUint64(w, message.from); err != nil {
		return err
	}
	return nil
}

type ServerMessageItem struct {
	id   uint64
	item uint64
}

func (message ServerMessageItem) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerItem); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint64(w, message.item); err != nil {
		return err
	}
	return nil
}

type ServerMessageFish struct {
	id uint64
}

func (message ServerMessageFish) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerFish); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	return nil
}

type ServerMessageSolo struct {
	id uint64
}

func (message ServerMessageSolo) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerSolo); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	return nil
}

type ServerMessageTryFlag struct {
	id   uint64
	flag string
}

func (message ServerMessageTryFlag) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerTryFlag); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeString(w, message.flag); err != nil {
		return err
	}
	return nil
}

type ServerMessageFlag struct {
	id   uint64
	flag string
}

func (message ServerMessageFlag) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerFlag); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeString(w, message.flag); err != nil {
		return err
	}
	return nil
}

type ServerMessageChat struct {
	id      uint64
	whisper uint64
	Msg     string
}

func (message ServerMessageChat) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerChat); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint64(w, message.whisper); err != nil {
		return err
	}
	if err := writeString(w, message.Msg); err != nil {
		return err
	}
	return nil
}

type ServerMessageBld struct {
	id         uint64
	bldid      uint64
	x, y, z, r float64
	data       string
}

func (message ServerMessageBld) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerBld); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint64(w, message.bldid); err != nil {
		return err
	}
	if err := writeFloat64(w, message.x); err != nil {
		return err
	}
	if err := writeFloat64(w, message.y); err != nil {
		return err
	}
	if err := writeFloat64(w, message.z); err != nil {
		return err
	}
	if err := writeFloat64(w, message.r); err != nil {
		return err
	}
	if err := writeString(w, message.data); err != nil {
		return err
	}
	return nil
}

type ServerMessageBlds struct {
	id        uint64
	buildings []ServerMessageBld
}

func (message ServerMessageBlds) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerBlds); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	data := new(bytes.Buffer)
	for _, building := range message.buildings {
		if err := writeUint64(data, building.bldid); err != nil {
			return err
		}
		if err := writeFloat64(data, building.x); err != nil {
			return err
		}
		if err := writeFloat64(data, building.y); err != nil {
			return err
		}
		if err := writeFloat64(data, building.z); err != nil {
			return err
		}
		if err := writeFloat64(data, building.r); err != nil {
			return err
		}
		if err := writeString(data, building.data); err != nil {
			return err
		}
	}
	// todo: compress?
	if err := writeData(w, data.Bytes()); err != nil {
		return err
	}
	return nil
}

type ServerMessageSpawn struct {
	id      uint64
	typ     uint64
	x, y, z float64
}

func (message ServerMessageSpawn) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerSpawn); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint64(w, message.typ); err != nil {
		return err
	}
	if err := writeFloat64(w, message.x); err != nil {
		return err
	}
	if err := writeFloat64(w, message.y); err != nil {
		return err
	}
	if err := writeFloat64(w, message.z); err != nil {
		return err
	}
	return nil
}

type ServerMessageTarget struct {
	id      uint64
	x, y, z float64
}

func (message ServerMessageTarget) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerTarget); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeFloat64(w, message.x); err != nil {
		return err
	}
	if err := writeFloat64(w, message.y); err != nil {
		return err
	}
	if err := writeFloat64(w, message.z); err != nil {
		return err
	}
	return nil
}

type ServerMessageSpawnChest struct {
	id      uint64
	chest   string
	x, y, z float64
}

func (message ServerMessageSpawnChest) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerSpawnChest); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeString(w, message.chest); err != nil {
		return err
	}
	if err := writeFloat64(w, message.x); err != nil {
		return err
	}
	if err := writeFloat64(w, message.y); err != nil {
		return err
	}
	if err := writeFloat64(w, message.z); err != nil {
		return err
	}
	return nil
}

type ServerMessageMark struct {
	id   uint64
	mark string
}

func (message ServerMessageMark) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerMark); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeString(w, message.mark); err != nil {
		return err
	}
	return nil
}

type ServerMessageConch struct {
	id       uint64
	Distance float64
}

func (message ServerMessageConch) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerConch); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeFloat64(w, message.Distance); err != nil {
		return err
	}
	return nil
}

type ServerMessageInteract struct {
	id     uint64
	target uint64
}

func (message ServerMessageInteract) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerInteract); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint64(w, message.target); err != nil {
		return err
	}
	return nil
}

type ServerMessageTogglePVP struct {
	id uint64
}

func (message ServerMessageTogglePVP) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerTogglePVP); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	return nil
}

type ServerMessageAccount struct {
	char uint8
}

func (message ServerMessageAccount) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerAccount); err != nil {
		return err
	}
	if err := writeUint8(w, message.char); err != nil {
		return err
	}
	return nil
}

type ServerMessageChangeArea struct {
	id   uint64
	area uint8
}

func (message ServerMessageChangeArea) _serverMessage(w io.Writer) error {
	if err := writeUint8(w, MsgServerChangeArea); err != nil {
		return err
	}
	if err := writeUint64(w, message.id); err != nil {
		return err
	}
	if err := writeUint8(w, message.area); err != nil {
		return err
	}
	return nil
}

type Server struct {
	id         uint64
	outchan    chan ServerMessage
	players    map[uint64]*Player
	enemies    map[uint64]*Enemy
	playerLock sync.RWMutex
	conn       net.Conn
	ready      uint32
	solo       bool
	closed     chan struct{}
	area       uint8
}

func NewServer(conn net.Conn) *Server {
	s := &Server{
		id:      rand.Uint64(),
		outchan: make(chan ServerMessage, 300),
		conn:    conn,
		players: make(map[uint64]*Player),
		enemies: make(map[uint64]*Enemy),
		solo:    false,
		closed:  make(chan struct{}),
	}

	go func() {
		if err := s.writePump(); err != nil {
			s.conn.Close()
		}
	}()

	go func() {
		if err := s.handler(); err != nil {
			s.conn.Close()
			close(s.closed)
			close(s.outchan)
		}
	}()

	go func() { s.update() }()

	return s
}

func (s *Server) String() string {
	return fmt.Sprintf("[%s]", s.conn.RemoteAddr().String())
}

func (s *Server) send(msg ServerMessage) error {
	defer func() {
		if err := recover(); err != nil {
			log.Println("server dead")
		}
	}()

	select {
	case <-s.closed:
		return fmt.Errorf("server closed")
	default:
		s.outchan <- msg
		return nil
	}
}

func ReadServerMessage(conn net.Conn) (ServerMessage, error) {
	cmd, err := readUint8(conn)
	if err != nil {
		return nil, err
	}
	switch cmd {
	case MsgServerLoggedIn:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		x, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		name, err := readString(conn)
		if err != nil {
			return nil, err
		}
		team, err := readString(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageLoggedIn{
			id:   id,
			x:    x,
			y:    y,
			z:    z,
			name: name,
			team: team,
		}, nil
	case MsgServerJoin:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		name, err := readString(conn)
		if err != nil {
			return nil, err
		}
		team, err := readString(conn)
		if err != nil {
			return nil, err
		}
		char, err := readUint8(conn)
		if err != nil {
			return nil, err
		}
		x, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		size, err := readUint8(conn)
		if err != nil {
			return nil, err
		}
		var marker = make([]string, size)
		for i := uint8(0); i < size; i++ {
			m, err := readString(conn)
			if err != nil {
				return nil, err
			}
			marker[i] = m
		}
		return ServerMessageJoin{
			id:     id,
			name:   name,
			team:   team,
			char:   char,
			x:      x,
			y:      y,
			z:      z,
			marker: marker,
		}, nil
	case MsgServerUpdatePlayer:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		x, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		r, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		health, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		weapon, err := readUint8(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageUpdatePlayer{
			id: id,
			x:  x, y: y, z: z,
			rotation: r,
			health:   health,
			weapon:   weapon,
		}, nil
	case MsgServerUpdatePlayers:
		length, err := readUint8(conn)
		if err != nil {
			return nil, err
		}
		players := make([]ServerMessageUpdatePlayer, length)
		for i := range players {
			id, err := readUint64(conn)
			if err != nil {
				return nil, err
			}
			x, err := readFloat64(conn)
			if err != nil {
				return nil, err
			}
			y, err := readFloat64(conn)
			if err != nil {
				return nil, err
			}
			z, err := readFloat64(conn)
			if err != nil {
				return nil, err
			}
			r, err := readFloat64(conn)
			if err != nil {
				return nil, err
			}
			health, err := readFloat64(conn)
			if err != nil {
				return nil, err
			}
			weapon, err := readUint8(conn)
			if err != nil {
				return nil, err
			}
			players[i] = ServerMessageUpdatePlayer{
				id: id,
				x:  x, y: y, z: z,
				rotation: r,
				health:   health,
				weapon:   weapon,
			}
		}
		return ServerMessageUpdatePlayers(players), nil
	case MsgServerLeave:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageLeave{
			id: id,
		}, nil
	case MsgServerFrame:
		return ServerMessageFrame{}, nil
	case MsgServerDie:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageDie{
			id: id,
		}, nil
	case MsgServerEquip:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		item, err := readUint8(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageEquip{
			id:   id,
			item: item,
		}, nil
	case MsgServerAttack:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		target, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageAttack{
			id:     id,
			target: target,
		}, nil
	case MsgServerItem:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		item, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageItem{
			id:   id,
			item: item,
		}, nil
	case MsgServerDamage:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		amount, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		from, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageDamage{
			id:     id,
			amount: amount,
			from:   from,
		}, nil
	case MsgServerSolo:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageSolo{
			id: id,
		}, nil
	case MsgServerChat:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		whisper, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		msg, err := readString(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageChat{
			id:      id,
			whisper: whisper,
			Msg:     msg,
		}, nil
	case MsgServerFlag:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		flag, err := readString(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageFlag{
			id:   id,
			flag: flag,
		}, nil
	case MsgServerSpawn:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		typ, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		x, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageSpawn{
			id:  id,
			typ: typ,
			x:   x,
			y:   y,
			z:   z,
		}, nil
	case MsgServerTarget:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		x, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageTarget{
			id: id,
			x:  x,
			y:  y,
			z:  z,
		}, nil
	case MsgServerSpawnChest:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		chest, err := readString(conn)
		if err != nil {
			return nil, err
		}
		x, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		y, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		z, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageSpawnChest{
			id:    id,
			chest: chest,
			x:     x,
			y:     y,
			z:     z,
		}, nil
	case MsgServerMark:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		marker, err := readString(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageMark{
			id:   id,
			mark: marker,
		}, nil
	case MsgServerConch:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		distance, err := readFloat64(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageConch{
			id:       id,
			Distance: distance,
		}, nil
	case MsgServerBlds:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		buffer, err := readData(conn)
		if err != nil {
			return nil, err
		}
		buf := bytes.NewBuffer(buffer)
		var buildings []ServerMessageBld
		for {
			bldid, err := readUint64(buf)
			if err != nil {
				log.Println(err)
				break
			}
			x, err := readFloat64(buf)
			if err != nil {
				log.Println(err)
				break
			}
			y, err := readFloat64(buf)
			if err != nil {
				log.Println(err)
				break
			}
			z, err := readFloat64(buf)
			if err != nil {
				log.Println(err)
				break
			}
			r, err := readFloat64(buf)
			if err != nil {
				log.Println(err)
				break
			}
			data, err := readString(buf)
			if err != nil {
				log.Println(err)
				break
			}
			_ = data
			buildings = append(buildings, ServerMessageBld{
				bldid: bldid,
				x:     x,
				y:     y,
				z:     z,
				r:     r,
				// data:  data,
			})
		}
		return ServerMessageBlds{
			id:        id,
			buildings: buildings,
		}, nil
	case MsgServerAccount:
		char, err := readUint8(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageAccount{
			char: char,
		}, nil
	case MsgServerChangeArea:
		id, err := readUint64(conn)
		if err != nil {
			return nil, err
		}
		area, err := readUint8(conn)
		if err != nil {
			return nil, err
		}
		return ServerMessageChangeArea{
			id:   id,
			area: area,
		}, nil
	default:
		log.Println("Unknown command: ", cmd)
		return nil, fmt.Errorf("unknown command")
	}
}

func (s *Server) writePump() error {
	for message := range s.outchan {
		if _, ok := message.(ServerMessageUpdatePlayers); debug > 0 && !ok {
			log.Printf("server > game: %#v", message)
		} else if debug > 1 && ok {
			log.Printf("server > game: %#v", message)
		}
		if err := message._serverMessage(s.conn); err != nil {
			log.Printf("server > game: ERROR! %#v", err)
			return err
		}
	}
	return nil
}

func (s *Server) handler() error {
	for {
		message, err := ReadServerMessage(s.conn)
		if err != nil {
			return err
		}

		if _, ok := message.(ServerMessageFrame); debug > 0 && !ok {
			log.Printf("game > server: %#v", message)
		} else if debug > 1 && ok {
			log.Printf("game > server: %#v", message)
		}
		s.playerLock.RLock()
		switch message := message.(type) {
		case ServerMessageLeave:
			for _, p := range s.players {
				if p.id == message.id || !s.solo {
					p.send(message)
				}
			}
		case ServerMessageJoin:
			for _, p := range s.players {
				if p.id == message.id || !s.solo {
					p.send(message)
				}
			}
		case ServerMessageAttack:
			for _, p := range s.players {
				if p.id == message.id || (!s.solo && !p.solo) {
					p.send(message)
				}
			}
		case ServerMessageDamage:
			_, enemyDamage := s.enemies[message.id]
			if p, ok := s.players[message.id]; ok {
				p.lock.Lock()
				p.health = message.amount
				p.lock.Unlock()
			}
			for _, p := range s.players {
				if p.id == message.id || enemyDamage {
					p.send(message)
				}
			}
		case ServerMessageEquip:
			if p, ok := s.players[message.id]; ok {
				p.send(message)
				p.lock.Lock()
				p.weapon = message.item
				p.lock.Unlock()
			}
		case ServerMessageItem:
			if p, ok := s.players[message.id]; ok {
				go Controller.addItem(p.id, message.item)
				p.send(message)
			}
		case ServerMessageFlag:
			if p, ok := s.players[message.id]; ok {
				p.send(message)
			}
		case ServerMessageSpawnChest:
			if p, ok := s.players[message.id]; ok {
				p.send(message)
			}
		case ServerMessageMark:
			for _, p := range s.players {
				if p.id == message.id || (message.mark == "FLAG_BOAT" && !s.solo) {
					p.send(message)
				}
			}
			go Controller.addMarker(message.id, message.mark)
		case ServerMessageConch:
			if p, ok := s.players[message.id]; ok {
				p.send(message)
			}
		case ServerMessageSolo:
			if p, ok := s.players[message.id]; ok {
				p.lock.Lock()
				p.solo = !p.solo
				p.lock.Unlock()
			}
		case ServerMessageChat:
			whispered := false
			for _, p := range s.players {
				if message.whisper == 0 && !s.solo {
					p.send(message)
				} else if p.id == message.whisper {
					p.send(message)
					whispered = true
					break
				}
			}
			if message.whisper != 0 && !whispered {
				s.send(message)
			}
		case ServerMessageSpawn:
			s.enemies[message.id] = &Enemy{
				typ: message.typ,
				x:   message.x,
				y:   message.y,
				z:   message.z,
				tx:  message.x,
				ty:  message.y,
				tz:  message.z,
			}
			for _, p := range s.players {
				p.send(message)
			}
		case ServerMessageTarget:
			if _, ok := s.enemies[message.id]; ok {
				s.enemies[message.id].tx = message.x
				s.enemies[message.id].ty = message.y
				s.enemies[message.id].tz = message.z
				for _, p := range s.players {
					p.send(message)
				}
			}
		case ServerMessageDie:
			delete(s.enemies, message.id)
			for _, p := range s.players {
				p.send(message)
			}
		case ServerMessageFrame:
			atomic.StoreUint32(&s.ready, 1)
			if debug > 1 {
				log.Println("Server frame")
			}
		case ServerMessageBlds:
			if p, ok := s.players[message.id]; ok {
				p.send(message)
				p.lock.Lock()
				p.buildings = message.buildings
				p.lock.Unlock()
			}
		case ServerMessageChangeArea:
			if p, ok := s.players[message.id]; ok {
				p.lock.Lock()
				p.solo = false
				p.lock.Unlock()
				if p.area != message.area {
					go Controller.changeArea(message.id, message.area)
					p.area = message.area
					go SM.AddPlayer(p)
				}
			}
		}
		s.playerLock.RUnlock()
	}
}

func (s *Server) update() {
	ticker := time.NewTicker(50 * time.Millisecond)

	for {
		select {
		case <-ticker.C:
			if !atomic.CompareAndSwapUint32(&s.ready, 1, 0) {
				if debug > 1 {
					log.Println("server not ready for updates")
				}
				continue
			}
			update := s.updatePlayerPacket(nil)
			s.send(update)

		case <-s.closed:
			ticker.Stop()
			return
		}
	}
}

const distance = 30.

func (s *Server) updatePlayerPacket(player *Player) ServerMessageUpdatePlayers {
	s.playerLock.RLock()
	defer s.playerLock.RUnlock()

	update := make(ServerMessageUpdatePlayers, len(s.players))
	var i int
	for _, p := range s.players {
		if player != nil && s.solo {
			continue
		}
		if player != nil && player.team != p.team && (math.Abs(p.x-player.x) > distance || math.Abs(p.z-player.z) > distance) {
			continue
		}
		if player != nil && (player.solo || p.solo) && player.team != p.team {
			continue
		}
		p.lock.RLock()
		update[i] = ServerMessageUpdatePlayer{
			id:       p.id,
			x:        p.x,
			y:        p.y,
			z:        p.z,
			rotation: p.rotation,
			health:   p.health,
			weapon:   p.weapon,
		}
		p.lock.RUnlock()
		i++
	}
	return update[:i]
}

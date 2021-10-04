package ts

import (
	"encoding/binary"
	"fmt"
	"io"
	"log"
)

func init() {
	log.SetFlags(log.Ltime | log.Lmicroseconds | log.Lshortfile)
}

const (
	MsgClientAuth         uint8 = 0x00
	MsgClientJoin         uint8 = 0x22
	MsgClientUpdatePlayer uint8 = 0x45
	MsgClientAttack       uint8 = 0xfe
	MsgClientEquip        uint8 = 0x91
	MsgClientFish         uint8 = 0x96
	MsgClientTryFlag      uint8 = 0x76
	MsgClientChat         uint8 = 0x50
	MsgClientBldPlace     uint8 = 0x60
	MsgClientInteract     uint8 = 0x10
	MsgClientTogglePVP    uint8 = 0x77
	MsgClientPing         uint8 = 0x44

	MsgServerUpdatePlayer  uint8 = 0xff
	MsgServerUpdatePlayers uint8 = 0xfe
	MsgServerJoin          uint8 = 0x11
	MsgServerLeave         uint8 = 0x99
	MsgServerAttack        uint8 = 0x4b
	MsgServerLoggedIn      uint8 = 0x66
	MsgServerFrame         uint8 = 0xcc
	MsgServerDie           uint8 = 0x01
	MsgServerEquip         uint8 = 0x02
	MsgServerDamage        uint8 = 0x33
	MsgServerItem          uint8 = 0x74
	MsgServerFish          uint8 = 0xb0
	MsgServerSolo          uint8 = 0x0b
	MsgServerTryFlag       uint8 = 0x67
	MsgServerFlag          uint8 = 0x68
	MsgServerChat          uint8 = 0x51
	MsgServerBld           uint8 = 0x61
	MsgServerBlds          uint8 = 0x62
	MsgServerSpawn         uint8 = 0x6f
	MsgServerTarget        uint8 = 0x6e
	MsgServerSpawnChest    uint8 = 0x90
	MsgServerMark          uint8 = 0x98
	MsgServerConch         uint8 = 0x91
	MsgServerInteract      uint8 = 0x20
	MsgServerAccount       uint8 = 0x03
	MsgServerTogglePVP     uint8 = 0x55
	MsgServerChangeArea    uint8 = 0x56
)

const debug = 1

func readUint8(r io.Reader) (out uint8, err error) {
	err = binary.Read(r, binary.LittleEndian, &out)
	return
}

func readFloat64(r io.Reader) (out float64, err error) {
	err = binary.Read(r, binary.LittleEndian, &out)
	return
}

func readUint64(r io.Reader) (out uint64, err error) {
	err = binary.Read(r, binary.LittleEndian, &out)
	return
}

func readString(r io.Reader) (out string, err error) {
	var length uint8
	if err = binary.Read(r, binary.LittleEndian, &length); err != nil {
		return
	}
	buf := make([]byte, length)
	var total int
	n, err := r.Read(buf)
	for {
		total += n
		if err != nil {
			return "", err
		}
		if total >= int(length) {
			return string(buf[:length]), nil
		}
		tmp := make([]byte, 1)
		n, err = r.Read(tmp)
		buf = append(buf, tmp...)
	}
}

func readData(r io.Reader) (out []byte, err error) {
	var length uint64
	if err = binary.Read(r, binary.LittleEndian, &length); err != nil {
		return
	}
	if length > 1024 {
		return nil, fmt.Errorf("%d is too long", length)
	}
	buf := make([]byte, length)
	var total int
	n, err := r.Read(buf)
	for {
		total += n
		if err != nil {
			return nil, err
		}
		if total >= int(length) {
			return buf[:length], nil
		}
		tmp := make([]byte, 1)
		n, err = r.Read(tmp)
		buf = append(buf, tmp...)
	}
}

func writeUint8(r io.Writer, data uint8) error {
	return binary.Write(r, binary.LittleEndian, data)
}

func writeUint64(r io.Writer, data uint64) error {
	return binary.Write(r, binary.LittleEndian, data)
}

func writeFloat64(r io.Writer, data float64) error {
	return binary.Write(r, binary.LittleEndian, data)
}

func writeString(r io.Writer, data string) error {
	if err := binary.Write(r, binary.LittleEndian, uint8(len(data))); err != nil {
		return err
	}

	_, err := r.Write([]byte(data))
	return err
}

func writeData(r io.Writer, data []byte) error {
	if err := binary.Write(r, binary.LittleEndian, uint64(len(data))); err != nil {
		return err
	}

	_, err := r.Write([]byte(data))
	return err
}

func contains(haystack []string, needle string) bool {
	for _, s := range haystack {
		if s == needle {
			return true
		}
	}
	return false
}

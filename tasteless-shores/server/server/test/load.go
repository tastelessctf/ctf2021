package main

import (
	"encoding/binary"
	"fmt"
	"log"
	"net"
	"os"
	"runtime"
	"strconv"
	"sync/atomic"
	"time"
)

func main() {
	runtime.GOMAXPROCS(2)

	n, _ := strconv.Atoi(os.Args[1])

	for i := 0; i < n; i++ {
		go player(i)
		time.Sleep(20 * time.Millisecond)
	}

	log.Println("all spawned")

	time.Sleep(1000 * time.Second)
}

var count int32

func player(i int) {
	c, err := net.Dial("tcp", "127.0.0.1:31337")
	if err != nil {
		log.Println(i, err)
		return
	}

	fmt.Fprintf(c, "pirates!\x00\x08test1234\x00")
	fmt.Fprintf(c, "\x22\x08")

	atomic.AddInt32(&count, 1)
	log.Println("joined: ", count)

	var buf = make([]byte, 100)
	go func() {
		for {
			if n, err := c.Read(buf); err != nil {
				log.Println(n, err)
				c.Close()
				return
			}
		}
	}()

	time.Sleep(10 * time.Millisecond)

	j := i % 100
	for {
		j++
		if j > 100 {
			j = 0
		}
		binary.Write(c, binary.LittleEndian, uint8(0x45))
		binary.Write(c, binary.LittleEndian, float64(-380+(float64(j))))
		binary.Write(c, binary.LittleEndian, float64(7))
		binary.Write(c, binary.LittleEndian, float64(655+(i%100)))
		binary.Write(c, binary.LittleEndian, float64(j))

		time.Sleep(50 * time.Millisecond)
	}
}

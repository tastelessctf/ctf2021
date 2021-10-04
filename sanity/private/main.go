package main

import (
	"fmt"
	"net"
	"os"
)

var flag = os.Getenv("FLAG")

func handle(c net.Conn) {
	defer c.Close()

	fmt.Fprintf(c, "welcome to tasteless ctf 2021\n%s", flag)
}

func main() {
	l, err := net.Listen("tcp", ":10000")
	if err != nil {
		panic(err)
	}

	for {
		c, err := l.Accept()
		if err != nil {
			panic(err)
		}
		handle(c)
	}
}

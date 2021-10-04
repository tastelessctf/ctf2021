package main

import (
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var pr = regexp.MustCompile(`sha1\(([a-f0-9]+), input\) prefix = ([a-f0-9]+)...`)
var verbose = false

func parse(in string) (string, string) {
	r := pr.FindStringSubmatch(in)
	return r[1], r[2]
}

func solve(prefix, suffix string) string {
	for i := 0; ; i++ {
		h := sha1.New()
		h.Write([]byte(prefix + strconv.Itoa(i)))
		if strings.HasPrefix(hex.EncodeToString(h.Sum(nil)), suffix) {
			return strconv.Itoa(i)
		}
		if verbose && (i%1000000) == 0 {
			fmt.Fprintf(os.Stderr, ".")
		}
	}
}

func connect(addr string, in io.ReadCloser, out io.WriteCloser) {
	up, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatal(err)
	}
	defer up.Close()

	pow := ""
	b := make([]byte, 1)
	// poor mans bufio scanner
	for {
		if n, err := up.Read(b); n == 0 || err != nil {
			return
		}
		if b[0] == '\n' {
			break
		}
		pow += string(b)
		if len(b) > 500 {
			log.Fatal("can not work with this endpoint, no POW?")
		}
	}

	start := time.Now()
	if verbose {
		fmt.Fprintf(os.Stderr, "solving %q\n", pow)
	}
	a := solve(parse(pow))
	if verbose {
		fmt.Fprintf(os.Stderr, "solved: %q in %fs\n", a, time.Since(start).Seconds())
	}
	up.Write([]byte(a + "\n"))

	errc := make(chan error, 1)

	go func() {
		_, err := io.Copy(out, up)
		errc <- err
		out.Close()
	}()
	go func() {
		_, err := io.Copy(up, in)
		errc <- err
		in.Close()
	}()

	<-errc
}

func main() {
	if len(os.Args) == 3 {
		fmt.Println(solve(os.Args[1], os.Args[2]))
	} else if len(os.Args) == 2 {
		// parse sha1(d616656ece36eb66, input) prefix = 00000...
		fmt.Println(solve(parse(os.Args[1])))
	} else if len(os.Args) == 4 {
		connect(os.Args[2]+":"+os.Args[3], os.Stdin, os.Stdout)
	} else if len(os.Args) == 5 {
		verbose = true
		l, err := net.Listen("tcp", os.Args[2])
		if err != nil {
			log.Fatal(err)
		}

		for {
			c, err := l.Accept()
			if err != nil {
				log.Fatal(err)
			}
			fmt.Fprintf(os.Stderr, "accepted %s\n", c.RemoteAddr().String())
			go connect(os.Args[3]+":"+os.Args[4], c, c)
		}
	} else {
		fmt.Println("TCTF21 OK Boomer")
		fmt.Println()
		fmt.Println("Use this tool to automagically connect to challenges protected by a Proof of Work")
		fmt.Println()
		fmt.Println("Most likely you will use it like netcat, or start it as a local server")
		fmt.Println()
		fmt.Println("usage")
		fmt.Println("\nnetcat mode:")
		fmt.Println("\tThis connects you to the challenge just like netcat")
		fmt.Printf("Usage: %s connect <host> <port>\n", os.Args[0])
		fmt.Printf("Usage: %s connect hyper.tasteless.eu 10001\n", os.Args[0])
		fmt.Println("\nserver mode:")
		fmt.Println("\tThis starts a local server, which solves the pow on connect")
		fmt.Printf("Usage: %s listen <:port> <host> <port>\n", os.Args[0])
		fmt.Printf("Usage: %s listen :12345 okboomer.tasteless.eu 10001\n", os.Args[0])
		fmt.Println("Then you can use 'nc localhost 12345'")
		fmt.Println("\nsolve provided args:")
		fmt.Printf("Usage: %s <prefix> <hash>\n", os.Args[0])
		fmt.Printf("Usage: %s d616656ece36eb66 00000\n", os.Args[0])
		fmt.Println("\nsolve serverresponse:")
		fmt.Printf("Usage: %s '<serverresponse>'\n", os.Args[0])
		fmt.Printf("Usage: %s 'sha1(d616656ece36eb66, input) prefix = 00000...'\n", os.Args[0])
		os.Exit(1)
	}
}

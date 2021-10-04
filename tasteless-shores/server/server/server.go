package main

import (
	"log"
	"net"
	"runtime"

	"sync"
	"ts/server/ts"

	"golang.org/x/time/rate"
)

// IPRateLimiter .
type IPRateLimiter struct {
	ips map[string]*rate.Limiter
	mu  *sync.RWMutex
	r   rate.Limit
	b   int
}

var limiter = NewIPRateLimiter(1, 1)

// NewIPRateLimiter .
func NewIPRateLimiter(r rate.Limit, b int) *IPRateLimiter {
	i := &IPRateLimiter{
		ips: make(map[string]*rate.Limiter),
		mu:  &sync.RWMutex{},
		r:   r,
		b:   b,
	}

	return i
}

// AddIP creates a new rate limiter and adds it to the ips map,
// using the IP address as the key
func (i *IPRateLimiter) AddIP(ip string) *rate.Limiter {
	i.mu.Lock()
	defer i.mu.Unlock()

	limiter := rate.NewLimiter(i.r, i.b)

	i.ips[ip] = limiter

	return limiter
}

// GetLimiter returns the rate limiter for the provided IP address if it exists.
// Otherwise calls AddIP to add IP address to the map
func (i *IPRateLimiter) GetLimiter(ip string) *rate.Limiter {
	i.mu.Lock()
	limiter, exists := i.ips[ip]

	if !exists {
		i.mu.Unlock()
		return i.AddIP(ip)
	}

	i.mu.Unlock()

	return limiter
}

func main() {
	runtime.GOMAXPROCS(2)

	slistener, err := net.Listen("tcp", ":33330")
	if err != nil {
		log.Fatal(err)
	}

	go func() {
		for {
			conn, err := slistener.Accept()
			if err != nil {
				log.Printf("Error accepting connection: %v", err)
				continue
			}
			log.Printf("Accepted Server connection: %v", conn)
			ts.SM.Add(ts.NewServer(conn))
		}
	}()

	listener, err := net.Listen("tcp", ":31337")
	if err != nil {
		log.Fatal(err)
	}

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("Error accepting connection: %v", err)
			continue
		}
		log.Printf("Accepted connection: %v", conn)
		limiter := limiter.GetLimiter(conn.RemoteAddr().(*net.TCPAddr).IP.String())
		if !limiter.Allow() {
			conn.Write([]byte("slow down, please"))
			conn.Close()
			continue
		}
		go ts.HandlePlayerConn(conn)
	}
}

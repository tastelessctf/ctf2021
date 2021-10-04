package main

import (
	"fmt"
	"test.com/vp8l"
	"os"
)

func main() {
	f, err := os.Open("stego.webp")
	if err != nil {
		panic(err)
	}

	_, err = f.Seek(0x14, 0)

	_, err = vp8l.Decode(f)
	fmt.Println(err)
}

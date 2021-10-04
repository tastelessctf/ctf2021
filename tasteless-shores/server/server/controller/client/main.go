package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"io/ioutil"
	"log"
	"ts/server/controller/api"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

var (
	list     *tview.List
	userlist *tview.List
)

func main() {
	certificate, err := tls.LoadX509KeyPair(
		"auth/admin.ts.tasteless.eu.crt",
		"auth/admin.ts.tasteless.eu.key",
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

	cc, err := grpc.Dial("35.159.19.200:1337", dialOption)
	if err != nil {
		panic(err)
	}

	c := api.NewAdminClient(cc)

	log.Println(c.Users(context.TODO(), &api.EmptyRequest{}))

	events := tview.NewTextView()
	events.SetMaxLines(30)

	servertree := tview.NewTreeNode("server")
	app := tview.NewApplication()
	e, err := c.Events(context.Background(), &api.EmptyRequest{})
	if err != nil {
		panic(err)
	}
	go func() {
		for {
			event, err := e.Recv()
			if err != nil {
				panic(err)
			}
			events.Write([]byte(event.String() + "\n"))
			switch event.Event {
			case "addServer":
				found := false
				for _, c := range servertree.GetChildren() {
					if c.GetText() == event.Host {
						found = true
						break
					}
				}
				if !found {
					servertree.AddChild(tview.NewTreeNode(event.Data))
				}
			case "rmServer":
				for _, c := range servertree.GetChildren() {
					if c.GetText() == event.Host {
						servertree.RemoveChild(c)
						break
					}
				}
			case "addShard":
				for _, p := range servertree.GetChildren() {
					if p.GetText() == event.Host {
						found := false
						for _, c := range p.GetChildren() {
							if c.GetText() == event.Data {
								found = true
								break
							}
						}
						if !found {
							p.AddChild(tview.NewTreeNode(event.Data))
						}
						break
					}
				}
			case "rmShard":
				for _, p := range servertree.GetChildren() {
					if p.GetText() == event.Host {
						for _, c := range p.GetChildren() {
							if c.GetText() == event.Data {
								p.RemoveChild(c)
								break
							}
						}
						break
					}
				}
			case "moveShard":
				for _, p := range servertree.GetChildren() {
					if p.GetText() == event.Host {
						for _, c := range p.GetChildren() {
							if c.GetText() == event.Data {
								p.SetText(event.Data)
								break
							}
						}
						break
					}
				}
			}
			app.Draw()
		}
	}()

	grid := tview.NewGrid().SetRows(1, 0, 1).SetColumns(0, 0, 0).SetBorders(true)

	grid.AddItem(
		tview.NewTextView().SetTextAlign(tview.AlignCenter).SetText("🏴‍☠️ ~~ Tasteless Shores ~~ 🏴‍☠️"),
		0, 0, 1, 3, 0, 0, false)

	grid.AddItem(
		events,
		1, 0, 1, 1, 0, 0, false)

	grid.AddItem(
		tview.NewTreeView().SetRoot(servertree).SetCurrentNode(servertree),
		1, 1, 1, 1, 0, 0, false)

	var input *tview.InputField
	input = tview.NewInputField().
		SetLabel("Command").
		SetFieldWidth(0).
		SetDoneFunc(func(key tcell.Key) {
			events.Write([]byte(input.GetText() + "\n"))
			c.Command(context.Background(), &api.CommandRequest{Cmd: input.GetText()})
			input.SetText("")
		})

	grid.AddItem(
		input,
		2, 0, 1, 3, 0, 0, false)

	if err := app.SetRoot(grid, true).EnableMouse(true).Run(); err != nil {
		panic(err)
	}
}

# Tasteless Shores

You find a readme, manual and server side parts here.

The games source files are included, but due to licensing, no assets. You can still download the game, see below.

## Challenges

Flags are obtainable by opening chests while standing nearby.

The server keeps track of accessable flags by setting the markers on the client, which also makes the chests appear.

### Boat

Fishing in the `lake'o'despair` requires to patch the fishing rod.

Relevant code at `game/items/fishing_rod.gd`.

Calling `Client.start_fish()` has an argument which is unused, so the `lake'o'despair` method does not have to exist at all.

Doing `Client.start_fish()` sets the `FLAG_BOAT` which allows you to open the boat flag. It also allows you to use the boat and not drown.

### Eyes

This was the only quest which is always accessable.

The chest is in the left eye of the skull. Teleport there and grab it.

### Blackbeard

Blackbeard is not invulnerable, but needs to be dealt 1000 damage from the player. However, he heals really fast, so with normal weapons this is impossible, because the weapons have ca. 2 second cooldowns.

`game/items/items.gd` will always create a new instance when a weapon is looked up. When the player equips a weapon in `game/player/player.gd` you get a new instance with a resetted cooldown every time.
Also the game server in `game/net/server2.gd` will process updates sequentially. To solve this, e.g. with the musket pistol (strongest weapon, server never verifies if you actually own it), one sends
```
ClientMsgEquip, 5    # equip musket
ClientMsgAttack, 666 # attack blackbeard
ClientMsgEquip, 5    # equip musket
ClientMsgAttack, 666 # attack blackbeard
ClientMsgEquip, 5    # equip musket
ClientMsgAttack, 666 # attack blackbeard
ClientMsgEquip, 5    # equip musket
ClientMsgAttack, 666 # attack blackbeard
ClientMsgEquip, 5    # equip musket
ClientMsgAttack, 666 # attack blackbeard
...
```
repeated a couple times to kill blackbeard.

### Guybrush

Guybrush used the simplest 8-bit PRNG I could google match your comebacks to his insults.

You need, however, whisper to him, a feature which is not implemented in the game client. Essentially you only have to change the `whisper` argument from 0 (nobody) to 31337 (guybrush).

There are various techniques using s3 or bruteforce to recover the prng state and then solve it.

### Conch

The conch challenge was based on pokemon go, back when they launched they had a feature to show distance to pokemons (not their coordinates though).

The conch will only send the distance to the correct point, but no coordinates.

To solve it you need to triliterate (or triangulate twice with x,y and x,z, set the third plane to 0 to cancel it). Then you can teleport to the position and use the conch to spawn the chest.

Sorry for not having time to add the actual rabbit :(

### Home

Home was probably the hardest challenge, a little harder than anticipated.

You are supposed to build a building with id 0x1337. However, the main server will not allow that id to be used. You can observe it in a local setup via wireshark, or reverse the server.

When you join or respawn on a server, the main server syncs your building from it's session-state to the game server. It is not persistence because if haven't had time to finish persistence.

The game server trusts the main server, so you need to make the main server's state corrupted to send the 0x1337 building.

The stack building in `island/home/obj/stack.gd` will trigger an overflow in the unused data attribute of the bulding. By placing a stack with 255 bytes of data this will overflow the string length.

Game Server and Main Server will pack the building list in an extra data blob, so you can destroy the message bounds in there and inject a building with ID 0x1337 when the game server sends the buildings to the main server, thus poisoning the main servers state.

Once you rejoin/respawn (not reconnect!) it will then make the main server send building 0x1337 to the game server and you can get the FLAG_HOME, which allows you to open the home chest.

## Server

The `server` folder contains the relevant server files.

### server

The main server which both the game server and the clients connect to.

It usually runs in standalone mode, but can connect to a controller server for auth, persistence, etc.

Once running it accepts client connections via port 31337, using a TCP protocol.

Game servers connect via port 33330 and communicate via server messages. The main server takes care of sharding, balancing, etc.

### server/controller

The controller responsible for authentication, persistence, account handling, server listing etc.

### server/controller/client

A client for the controller. More broken than working.

### server/test

A load testing tool

### server/test/exploits

Exploits

## Game

### Linux

Download: https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/tasteless-shores.x86_64 and https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/tasteless-shores.pck

Run `./tasteless-shores.x86_64` in the folder where the `tasteless-shores.pck` exists.

### Windows

Download: https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/tasteless-shores.exe and https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/tasteless-shores.pck

Run `tasteless-shores.exe` in the folder where the `tasteless-shores.pck` exists.

### Mac OS

Download: https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/tasteless-shores.dmg

Move `Tasteless Shores.app` to a local folder and clean the quarantine `xattr -r -d com.apple.quarantine Tasteless Shores.app`

### Known Issues

- PVP is broken, sorry for that.
- Kali VM is not working for the game, appearently
- VMWare mouse (thx to idkkkkkkkkkkkkk!): https://stackoverflow.com/questions/45390414/3d-acceleration-vmware-drag-mouse-issues
> Under general mouse and keyboard settings set Gaming to "Always optimize mouse for games" . So VMware options -> keyboard + mouse settings, edit the profile, then click on the General tab.

### Controls

Mouse to look around

W, A, S, D to move

E to interact

TAB to open inventory

Left mouse click to attack/use item

Right mouse for secondary action (if available)

ENTER to write into chat

### Local Setup

Download the main-server:

Linux: https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/server

Windows: https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/server.exe

Mac OS: https://s3.eu-central-1.amazonaws.com/tstlss.tasteless.eu/server.osx

#### Run local setup:

Mainserver: `./server`

Gameserver: `./tasteless-shores.x86_64 server`

Game: `./tasteless-shores.x86_64 local`

### Checksums

```
MD5 (tasteless-shores.dmg) = 20471dd54b5576660c7c17103fcb7b84
MD5 (tasteless-shores.exe) = 68cc9fb0be256548e1bcfbd986751829
MD5 (tasteless-shores.pck) = 699fa1810daa1aa577589ee9326642b8
MD5 (tasteless-shores.x86_64) = 9fd25146e339cba3c91a414e9865d19e
MD5 (server) = ac2ef6a92052ebe1e25a26785103f495
MD5 (server.exe) = fece04b8dfd3fe316f55b69f63a18be9
MD5 (server.osx) = 43cde1b4d1bc6124793f8b036d06dcf8
```

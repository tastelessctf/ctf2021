This challenge is locked down.

Locked down challenges will require a proof-of-work like this: sha1(abc123, input) prefix = 000000... you need to respond with a single line suffix to abc123, so that sha1(abc123[input]) has a 000000 prefix example: sha(abc12344739190).hexdigest = 000000872D5625DEE5FD0EA44B230D7A98C1B2CA

you can use go run pow.go abc123 000000 or python pow.py abc123 000000 to generate your own.

Connect at hyper.tasteless.eu:10001 to retrieve your flag!

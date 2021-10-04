#!/bin/sh

echo "Starting challenge, please stand by..."
reset
echo "================================================="
reset
echo "================================================="
echo "=== Please Provide Pretentious Python Program ==="
echo "===    (Terminate input by sending 'EOF'.)    ==="
echo "================================================="

while IFS='$\n' read line ; do
    if [ "$line" == 'EOF' ]; then
        echo "Received all, starting your program!"
        break
    else
        echo "$line" >> /home/user1/script.py
        echo "$line" >> /home/user2/script.py
    fi
done

su - user2 1>/dev/null 2>/dev/null &
su - user1 

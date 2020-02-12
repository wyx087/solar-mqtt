rm pc.exe

gcc -std=gnu99 -Iinclude pc.c src/mqtt.c src/mqtt_pal.c -lpthread -o pc.exe

./pc.exe


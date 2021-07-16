rm solar_mqtt

gcc -std=gnu99 -Iinclude -Wno-unused-variable -Wno-duplicate-decl-specifier solar_mqtt.c src/mqtt.c src/mqtt_pal.c -lpthread -o solar_mqtt

./solar_mqtt


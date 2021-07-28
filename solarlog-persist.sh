#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/mnt/ramdisk/ramdisk_solarsync.log 2>&1
# Everything below will go to the log file

case "$1" in
  run)
    echo [`date +"%Y-%m-%d %H:%M:%S"`] !! Copying files to ramdisk
    rsync -av /docker/solar/ramdisk/ /mnt/ramdisk/
    echo [`date +"%Y-%m-%d %H:%M:%S"`] !! Ramdisk Synched from HD
    echo [`date +"%Y-%m-%d %H:%M:%S"`] !! Starting Owl log trim script

    /docker/solar/solar_mqtt >> /mnt/ramdisk/solar_mqtt.log &

    filein=/mnt/ramdisk/solar_graph.log
    fileout=/mnt/ramdisk/solar_graphshort.log
    size=250
    while [ 1 ]; do
      if [ -f "$filein" ]
      then
        tail -n $size $filein > $fileout
      fi
      sleep 8
    done
    ;;
  sync)
    echo [`date +"%Y-%m-%d %H:%M:%S"`] !! Synching files from ramdisk
    rsync -av --delete --recursive --force /mnt/ramdisk/solar*.log /docker/solar/ramdisk/
    echo [`date +"%Y-%m-%d %H:%M:%S"`] !! Ramdisk Synched to HD
    ;;
  *)
    echo "Usage: solarlog-persist {run|sync}"
    exit 1
    ;;
esac

exit 0


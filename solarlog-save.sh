#!/bin/bash

#   Save CSV log file archive to disk

file=/mnt/ramdisk/solar_graph.log
DATE=$(date +%Y-%m-%d)
cat $file >> /docker/solar/log/solar_$DATE.csv

sudo rm $file

#!/bin/bash

ssh pi@192.168.4.1
echo "mypi"
cd ~/Documents/LabjackPython/Source/Examples/
python daqStreamFull.py

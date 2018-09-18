#!/bin/bash

ps -ef | grep "python daqStreamFull.py" | grep -v grep | awk '{print $2}' | xargs kill


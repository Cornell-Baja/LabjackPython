"""
Demonstrates how to stream using the eStream functions.

"""

from labjack import ljm
import time
import sys
from datetime import datetime
import numpy as np
import signal
import sys
import csv
def signal_handler(signal, frame):
    global handle
    print("\nStop Stream")
    ljm.eStreamStop(handle)

    # Close handle
    ljm.close(handle)
    print('You pressed Ctrl+C!')
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)


MAX_REQUESTS = 50 # The number of eStreamRead calls that will be performed.

# Open first found LabJack
handle = ljm.open(ljm.constants.dtANY, ljm.constants.ctANY, "ANY")
#handle = ljm.openS("ANY", "ANY", "ANY")

info = ljm.getHandleInfo(handle)
print("Opened a LabJack with Device type: %i, Connection type: %i,\n" \
    "Serial number: %i, IP address: %s, Port: %i,\nMax bytes per MB: %i" % \
    (info[0], info[1], info[2], ljm.numberToIP(info[3]), info[4], info[5]))

# Stream Configuration
aScanListNames = ["AIN0", "CORE_TIMER","STREAM_DATA_CAPTURE_16"] #Scan list names to stream
numAddresses = len(aScanListNames)
aScanList = ljm.namesToAddresses(numAddresses, aScanListNames)[0]
scanRate = 50
scansPerRead = int(scanRate/2)
clock_divisor = 64

try:
    # Configure the analog inputs' negative channel, range, settling time and
    # resolution.
    # Note when streaming, negative channels and ranges can be configured for
    # individual analog inputs, but the stream has only one settling time and
    # resolution.
    

    aNames = ["AIN0_NEGATIVE_CH",
                "DIO_EF_CLOCK0_ENABLE",
                "DIO_EF_CLOCK0_DIVISOR",
                "DIO_EF_CLOCK0_ROLL_VALUE",
                "DIO_EF_CLOCK0_ENABLE"
                ]
    aValues = [ljm.constants.GND,
               0,
               clock_divisor,
               0,
               1
                ]

    ljm.eWriteNames(handle, len(aNames), aNames, aValues)

    # Configure and start stream
    scanRate = ljm.eStreamStart(handle, scansPerRead, numAddresses, aScanList, scanRate)
    print("\nStream started with a scan rate of %0.0f Hz." % scanRate)

    print("\nPerforming %i stream reads." % MAX_REQUESTS)
    start = datetime.now()
    totScans = 0
    totSkip = 0 # Total skipped samples

    output_names=['clock', 'weight']
    cur_log="dyno"+"_"+str(start.month)+"_"+str(start.day)+"_"+str(start.year)+"_"+str(start.hour)+"_"+str(start.minute)+"_"+str(start.second)+".csv"

    with open("test_dyno.csv", "w") as f:
        writer = csv.writer(f)
        writer.writerow(output_names)

    with open(cur_log, "w") as f:
        writer = csv.writer(f)
        writer.writerow(output_names)
    
    while True:
        print ("logging")
        ret = ljm.eStreamRead(handle)
        
        data = ret[0]
        data_intermediate = np.reshape(data, (scansPerRead, len(aScanListNames)))

        a = data_intermediate[:, 0]
        b = data_intermediate[:, 1]
        c = data_intermediate[:, 2]

        weight = -0.00507 + a/0.108
        clock = (b + c * 65536) / (80000000 / 2)


        output_data = np.array([clock, weight]).transpose()
        print(clock.shape)
        print(weight.shape)
        print(clock[len(clock)-1], weight[len(weight)-1])
        
        print(output_data.shape)
        f = open('test_dyno.csv', 'a')
        np.savetxt(f, output_data, delimiter=',')
        f.close()

        f = open(cur_log, 'a')
        np.savetxt(f, output_data, delimiter=',')
        f.close()

    end = datetime.now()



except ljm.LJMError:
    ljme = sys.exc_info()[1]
    print(ljme)
except Exception:
    e = sys.exc_info()[1]
    print(e)



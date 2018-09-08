"""
Generic Setup for LabJack Data streaming
"""

import sys
sys.path.append('C:\\Users\BAJA\Desktop\labjack\LabjackPython\Source')
from labjack import ljm
import time
from datetime import datetime
import numpy as np
import signal
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
#handle = ljm.open(ljm.constants.dtANY, ljm.constants.ctANY, "ANY")
handle = ljm.openS("ANY", "ANY", "ANY")

info = ljm.getHandleInfo(handle)
print("Opened a LabJack with Device type: %i, Connection type: %i,\n" \
    "Serial number: %i, IP address: %s, Port: %i,\nMax bytes per MB: %i" % \
    (info[0], info[1], info[2], ljm.numberToIP(info[3]), info[4], info[5]))

# Stream Configuration
# starting with 8 analog in and four digital in
# digital in are configured to read the average period between falling edges on the input
# so this wil be the time between gear teeth
# read_a_and_reset reads from register a of the dio pin (https://labjack.com/support/datasheets/t-series/digital-io/extended-features/interrupt-frequency)
#     and then resets inbetween measurement criteria. this way if the gear stops, the hall effect sensor returns 0 instead of increasing the period forever
# stream_data_caputre allows for full float32 data types to be sent over streaming. it holds the Most Significant 16bits associated with the proceeding scan name
aScanListNames = ["AIN0", "AIN1", "AIN2","AIN3", "AIN4", "AIN5", "AIN6","AIN7",
                    "DIO0_EF_READ_A_AND_RESET", "STREAM_DATA_CAPTURE_16", "DIO1_EF_READ_A_AND_RESET", "STREAM_DATA_CAPTURE_16", 
                    "DIO2_EF_READ_A_AND_RESET", "STREAM_DATA_CAPTURE_16", "DIO3_EF_READ_A_AND_RESET", "STREAM_DATA_CAPTURE_16"] #Scan list names to stream
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
    
                                             

    aNames = ["AIN_ALL_NEGATIVE_CHANNEL",  # setting all analog in terminals to single eneded, see https://labjack.com/support/datasheets/t-series/ain for details
              "AIN0_RANGE",                # register reference for AIN0 range
              "AIN1_RANGE",                # register reference for AIN1 range
              "AIN2_RANGE",                # register reference for AIN2 range
              "AIN3_RANGE",                # register reference for AIN3 range
              "AIN4_RANGE",                # register reference for AIN4 range
              "AIN5_RANGE",                # register reference for AIN5 range
              "AIN6_RANGE",                # register reference for AIN6 range
              "AIN7_RANGE",                # register reference for AIN7 range
              "DIO0_EF_ENABLE",            # initially need to diable all extended functionality for configuration
              "DIO1_EF_ENABLE",
              "DIO2_EF_ENABLE",
              "DIO3_EF_ENABLE",
              "DIO0_EF_INDEX",             # set these channels to function interrupt frequency streams
              "DIO1_EF_INDEX",
              "DIO2_EF_INDEX",
              "DIO3_EF_INDEX",
              "DIO0_EF_ENABLE",            # then need to re-enable all of the extended functionality
              "DIO1_EF_ENABLE",
              "DIO2_EF_ENABLE",
              "DIO3_EF_ENABLE"]


    aValues = [199,                        # write value 199 to set all channels to single ended measurement
               10,                         # set analog input range to +/-10 V, adjust if different range is needed (1, .1, .01)
               10,
               10,
               10,
               10,
               10,
               10,
               10,
               0,                         # disable ef for dio channels to config
               0,
               0,
               0,
               11,                        # set channels to stream average interrupt frequency
               11,
               11,
               11,
               1,                         # enable ef for dio channels to streaming
               1,
               1,
               1]

    # in the order they are written, write the values in aValues to the registers referenced by elements of aNames
    ljm.eWriteNames(handle, len(aNames), aNames, aValues)

    # Configure and start stream
    scanRate = ljm.eStreamStart(handle, scansPerRead, numAddresses, aScanList, scanRate)
    print("\nStream started with a scan rate of %0.0f Hz." % scanRate)

    print("\nPerforming %i stream reads." % MAX_REQUESTS)
    start = datetime.now()
    totScans = 0
    totSkip = 0 # Total skipped samples

    output_names = ['AIN0', 'AIN1','AIN2', 'AIN3', 'AIN4', 'AIN5', 'AIN6', 'AIN7', 'DIO0', 'DIO1', 'DIO2', 'DIO3']

    with open("stream_test.csv", "w") as f:
        write = csv.write(f)
        write.writerow(output_names)

    while True:
        print ("logging")
        streamRead = ljm.eStreamRead(handle)

        data = streamRead[0]
        data = np.reshape(data, (scansPerRead, len(aScanListNames)))

        ain0 = data[:, 0]
        ain1 = data[:, 1]
        ain2 = data[:, 2]
        ain3 = data[:, 3]
        ain4 = data[:, 4]
        ain5 = data[:, 5]
        ain6 = data[:, 6]
        ain7 = data[:, 7]

        dio0 = data[:, 8] + 65536*data[:, 9]
        dio1 = data[:, 10] + 65536*data[:, 11]
        dio2 = data[:, 12] + 65536*data[:, 13]
        dio3 = data[:, 14] + 65536*data[:, 15]

        output_data = np.array([ain0, ain1, ain2, ain3, ain4, ain5, ain6, ain7, dio1, dio2, dio3, dio4]).transpose()

        print (output_data)

        f = open('stream_test.csv', 'a')
        np.savetxt(f, output_data, delimiter=',')
        f.close()

except ljm.LJMError:
	  ljme = sys.exc_info()[1]
	  print(ljme)
except Exception:
	  e = sys.exc_info()[1]
	  print(e)
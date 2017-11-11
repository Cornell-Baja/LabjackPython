import tkinter
import time
from tkinter import *

FREQ = 2500
DUR = 150

after_id = None
secs = 0


def beeper():
    global after_id
    global secs
    secs += 1
    if secs % 2 == 0:  # every other second
        print ("hello")
    after_id = top.after(1000, beeper)  # check again in 1 second

def start():
    global secs
    secs = 0
    var.set("Running")
    label.config(bg="green")
    beeper()  # s


def stop():
    global after_id
    if after_id:
        top.after_cancel(after_id)
        after_id = None
        var.set("Stopped")
        label.config(bg="red")


top = tkinter.Tk()
var = tkinter.StringVar()
top.title('CVT Dyno')
top.geometry('200x125')

startButton = tkinter.Button(top, height=2, width=20, text="Start",
                             command=start, highlightbackground="green")
stopButton = tkinter.Button(top, height=2, width=20, text="Stop",
                            command=stop,highlightbackground="red")
label = tkinter.Label( top, textvariable=var, relief=RAISED , justify ="center",bg="red",pady=5)

var.set("Stopped")
startButton.pack()
stopButton.pack()
label.pack()
top.mainloop()

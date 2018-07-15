
![](https://raw.githubusercontent.com/loveencounterflow/interflug/master/artwork/Interflug.svg.png)

# Interflug

## Prerequisites

*Interflug* uses the `wmctrl` and `xte` command line tools for window management and
sending keystrokes; on many systems, these can be installed as:

```
sudo apt install xautomation wmctrl
```

## Demos

### Demo One

From the command line, execute `node lib/demos/demo1.js`.

Create an *Interflug* context module and set window IDs. This records the window
ID of the currently active window—in this case the window of the terminal
emulator—and prompt the user to switch to aome other application and click into
that window. That window ID—the target ID—will subsequently be used to send text
to:

```
ifl = IFL.new()
IFL.set_window_ids ifl
```


<!--

###

List Windows with handles, titles: `wmctrl -l`
Getting a list of windows with PID and geometry information: `wmctrl -p -G -l | less -SR`

Switch to application window with string in title or ID:

```
wmctrl -a Sublime
wmctrl -i -a 0x05800001
```

Switch to application and send Ctrl-V:

```
wmctrl -a Sublime && xte 'usleep 250000' 'keydown Control_L' 'key v' 'keyup Control_L'
```

              The window name string :SELECT: is treated specially. If this window name is used then
              wmctrl waits for the user to select the target window by clicking on it.

              The  window  name  string :ACTIVE: may be used to instruct wmctrl to use the currently
              active window for the action.


Obtain the numeric handle of the currently active window with `wmctrl -v -a :ACTIVE:`

Output:

```
envir_utf8: 1
Using window: 0x05000005
```

Let user select a window, get back its handle with `wmctrl -v -a :SELECT:`

Output:

```
envir_utf8: 1
Using window: 0x05000005
```

wmctrl -i -a 0x06c00001
wmctrl -i -a 0x05000005



###



###

xte
part of `sudo apt install xautomation`

xte v1.09
Generates fake input using the XTest extension, more reliable than xse
Author: Steve Slaven - http://hoopajoo.net

usage: xte [-h] [-i xinputid] [-x display] [arg ..]

  -h  this help
  -i  XInput2 device to use. List devices with 'xinput list'
  -x  send commands to remote X server.  Note that some commands
      may not work correctly unless the display is on the console,
      e.g. the display is currently controlled by the keyboard and
      mouse and not in the background.  This seems to be a limitation
      of the XTest extension.
  arg args instructing the little man on what to do (see below)
      if no args are passed, commands are read from stdin separated
      by newlines, to allow a batch mode

 Commands:
  key k          Press and release key k
  keydown k      Press key k down
  keyup k        Release key k
  str string     Do a bunch of key X events for each char in string
  mouseclick i   Click mouse button i
  mousemove x y  Move mouse to screen position x,y
  mousermove x y Move mouse relative from current location by x,y
  mousedown i    Press mouse button i down
  mouseup i      Release mouse button i
  sleep x        Sleep x seconds
  usleep x       uSleep x microseconds

Some useful keys (case sensitive)
  Home
  Left
  Up
  Right
  Down
  Page_Up
  Page_Down
  End
  Return
  BackSpace
  Tab
  Escape
  Delete
  Shift_L
  Shift_R
  Control_L
  Control_R
  Meta_L
  Meta_R
  Alt_L
  Alt_R
  Multi_key

Depending on your keyboard layout, the "Windows" key may be one of the
Super_ keys or the Meta_ keys.

Sample, drag from 100,100 to 200,200 using mouse1:
  xte 'mousemove 100 100' 'mousedown 1' 'mousemove 200 200' 'mouseup 1'

xte 'sleep 3' 'keydown Control_L' 'key v' 'keyup Control_L'
foo
xte 'sleep 3' 'keydown Control_L' 'key v' 'keyup Control_L'


-->

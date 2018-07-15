




'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERFLUG/main'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# PATH                      = require 'path'
#...........................................................................................................
# parallel                  = require './parallel-promise'
# DB                        = require './db'
#...........................................................................................................
# require '../exception-handler'
#...........................................................................................................
# INTERSHOP                 = require '../../intershop'
# O                         = INTERSHOP.settings
# PTVR                      = INTERSHOP.PTV_READER
#...........................................................................................................
CLIPBOARD                 = require 'clipboardy'
CP                        = require 'child_process'


#-----------------------------------------------------------------------------------------------------------
@new = ->
  R =
    '~isa':   'INTERFLUG/state'

#-----------------------------------------------------------------------------------------------------------
@send_text = ( S, text = null ) ->
  CLIPBOARD.write text if text?
  # command = """wmctrl -a Sublime && xte 'usleep 250000' 'keydown Control_L' 'key v' 'keyup Control_L'"""
  command = """wmctrl -i -a 0x06c00001 && xte 'usleep 250000' 'keydown Control_L' 'key v' 'keyup Control_L' && wmctrl -i -a 0x05000005"""
  CP.execSync command
  return null

#-----------------------------------------------------------------------------------------------------------
@switch_to_window_by_id = ( id ) ->
  command = """wmctrl -i -a #{id}"""
  message = CP.execSync command, { encoding: 'utf-8', }
  return null

#-----------------------------------------------------------------------------------------------------------
@get_id_of_active_window = ->
  command = """wmctrl -v -a :ACTIVE: 2>&1"""
  message = CP.execSync command, { encoding: 'utf-8', }
  return message.replace /^.*window:\s*(\S+)\s*$/gs, '$1'

#-----------------------------------------------------------------------------------------------------------
@get_id_of_selected_window = ->
  command = """wmctrl -v -a :SELECT: 2>&1"""
  message = CP.execSync command, { encoding: 'utf-8', }
  return message.replace /^.*window:\s*(\S+)\s*$/gs, '$1'

# @send_text '𢊟𨮘賔𩯭𩯫𩦿'
# @send_text null
help own_id = @get_id_of_active_window()
urge "switch to the target window and click into it"
help target_id = @get_id_of_selected_window()
@switch_to_window_by_id own_id
# @switch_to_window_by_id target_id

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


###
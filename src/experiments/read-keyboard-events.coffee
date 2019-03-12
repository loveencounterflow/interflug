
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = '明快打字机/EXPERIMENTS/KB'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND
L                         = @
CP                        = require 'child_process'
IFL                       = require 'interflug'


f = ->
  ifl = IFL.new()
  IFL.set_window_ids              ifl
  # IFL.switch_to_own_window        ifl
  IFL.switch_to_target_window     ifl
  # IFL.send_text_to_target_window  ifl, "demonstrating Unicode: äöü 书争事𫞖𫠠𫠣"
  # IFL.switch_to_own_window        ifl
  debug ifl
  g()

#-----------------------------------------------------------------------------------------------------------
@read_xmodmap = ->
  #.........................................................................................................
  $read_entry = =>
    pattern = /// ^ keycode \s+ (?<code> [0-9]+ ) \s+ = \s+ (?<names> .+? ) \s* $ ///
    return $ ( d, send ) =>
      return unless ( match = d.match pattern )?
      code          = parseInt match.groups.code, 10
      names         = match.groups.names.split /\s+/
      names[ idx ]  = name.toLowerCase() for name, idx in names
      send { code, names, }
  #.........................................................................................................
  $assemble = =>
    R     = {}
    last  = Symbol 'last'
    return $ { last, }, ( d, send ) =>
      if d is last
        R[ key ] = [ value..., ] for key, value of R
        delete R[ 'nosymbol' ]
        return send R
      ( R[ name ]?= new Set() ).add d.code for name in d.names
  #.........................................................................................................
  return new Promise ( resolve ) ->
    path      = PATH.resolve PATH.join __dirname, '../../src/experiments/xmodmap'
    pipeline  = []
    source    = PD.read_from_file path
    pipeline.push source
    pipeline.push PD.$split()
    pipeline.push $read_entry()
    pipeline.push $assemble()
    pipeline.push $ ( d, send ) -> resolve d
    pipeline.push PD.$drain()
    PD.pull pipeline...
    return null

#-----------------------------------------------------------------------------------------------------------
@read_xevevents = ->
  #.........................................................................................................
  is_blank_line = ( line ) => ( line.match /^\s*$/ )?
  #.........................................................................................................
  $group_lines = =>
    last  = Symbol 'last'
    block = null
    return $ { last, }, ( d, send ) =>
      if d is last
        send block if block?
      else if is_blank_line d
        send block if block?
        block = []
      else
        ( block ?= [] ).push d.trim()
      return null
  #.........................................................................................................
  $filter_keypress_events = => PD.$filter ( d ) => d[ 0 ].startsWith 'KeyPress'
  $declutter              = => $ ( d, send ) => send d[ 2 ... d.length - 1 ].join '\n'
  #.........................................................................................................
  $parse_event_text = =>
    ### Source looks like this:
    ```
    state 0x0, keycode 16 (keysym 0x37, 7), same_screen YES,
    XLookupString gives 1 bytes: (37) "7"
    XmbLookupString gives 1 bytes: (37) "7"
    ```
    ###
    keycode_pattern       = /// \s+ keycode \s+ (?<value> [0-9]+ ) ///m
    state_pattern         = /// ^ state \s+ 0x (?<value> [0-9a-f]+ ) ///m
    x_pattern             = /// ^ XLookupString \s+ gives \s+ .* " (?<value> .+? ) " $ ///m
    modifiers             = []
    modifier_bitpattterns =
      alt:        0b00001000 # 0x08
      altgr:      0b10000000 # 0x80
      control:    0b00000100 # 0x04
      meta:       0b01000000 # 0x40
      shift:      0b00000001 # 0x01
    return $ ( d0, send ) =>
      d = { key: '^xev', }
      #.....................................................................................................
      if ( match = d0.match keycode_pattern )?
        ### higher level software uses system keycode + 8, for whatever reason ###
        d.code = ( parseInt match.groups.value, 10 ) - 8
      #.....................................................................................................
      if ( match = d0.match state_pattern )?
        modifiers.length  = 0
        modifier_bits     = parseInt match.groups.value, 16
        for name in [ 'alt', 'altgr', 'ctrl', 'meta', 'shift', ]
          continue if ( modifier_bitpattterns[ name ] & modifier_bits ) is 0
          d[ name ] = true
          modifiers.push name
        d.modifiers = modifiers.join '+' if modifiers.length > 0
      #.....................................................................................................
      if ( match = d0.match x_pattern )?
        d.text  = match.groups.value
      #.....................................................................................................
      return unless d.code?
      return unless d.text?
      d.id = "#{d.modifiers ? 'null'}-#{d.code}"
      #.....................................................................................................
      send d
  #.........................................................................................................
  $assemble = =>
    R     = {}
    last  = Symbol 'last'
    return $ { last, }, ( d, send ) =>
      return send R if d is last
      R[ d.id ] = d
      return null
  #.........................................................................................................
  return new Promise ( resolve ) ->
    path      = PATH.resolve PATH.join __dirname, '../../src/experiments/xev-events'
    pipeline  = []
    source    = PD.read_from_file path
    pipeline.push source
    pipeline.push PD.$split()
    pipeline.push $group_lines()
    pipeline.push $filter_keypress_events()
    pipeline.push $declutter()
    pipeline.push $parse_event_text()
    pipeline.push $assemble()
    # pipeline.push PD.$show title: '33873-1'
    pipeline.push $ ( d, send ) -> resolve d
    pipeline.push PD.$drain()
    PD.pull pipeline...
    return null

#-----------------------------------------------------------------------------------------------------------
@$decode_keyboard_event_buffer = ->
  keycodes      = require './key-event-codes'
  return $ ( buffer, send ) ->
    return null unless ( type = buffer.readUInt16LE 16 ) is 1
    code  = buffer.readUInt16LE 18
    value = buffer.readInt32LE  20
    move  = if value is 1 then 'down' else 'up'
    name  = keycodes[ code ] ? null
    send { key: '^key', name, code, move, }
    return null

#-----------------------------------------------------------------------------------------------------------
@$capture_modifiers = ->
  modifiers = []
  state     =
    shift:      false
    control:    false
    meta:       false
    alt:        false
    altgr:      false
  #.........................................................................................................
  return $ ( d, send ) ->
    switch d.name
      when 'leftshift', 'rightshift'  then state.shift  = ( d.move is 'down' )
      when 'leftmeta',  'rightmeta'   then state.meta   = ( d.move is 'down' )
      when 'leftctrl',  'rightctrl'   then state.ctrl   = ( d.move is 'down' )
      when 'leftalt'                  then state.alt    = ( d.move is 'down' )
      when 'rightalt'                 then state.altgr  = ( d.move is 'down' )
      else
        modifiers.length = 0
        for name in [ 'alt', 'altgr', 'ctrl', 'meta', 'shift', ]
          continue unless state[ name ]
          d[ name ] = true
          modifiers.push name
        d.modifiers = modifiers.join '+' if modifiers.length > 0
        d.id = "#{d.modifiers ? 'null'}-#{d.code}"
        send d
    return null

#-----------------------------------------------------------------------------------------------------------
@$map_keyboard_events = ( keyboard_mapping ) ->
  return $ ( d, send ) ->
    d.text = mapping.text if ( mapping = keyboard_mapping[ d.id ] )?
    send d

#-----------------------------------------------------------------------------------------------------------
@read_from_keyboard = ( keyboard_mapping ) ->
  path      = '/dev/input/by-path/platform-i8042-serio-0-event-kbd'
  source    = PD.read_chunks_from_file path, 24
  pipeline  = []
  pipeline.push source
  pipeline.push @$decode_keyboard_event_buffer()
  pipeline.push @$capture_modifiers()
  pipeline.push @$map_keyboard_events keyboard_mapping
  #.........................................................................................................
  return PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@$compose_keys = ->
  start_compose_id  = 'null-13' # tick ('´')
  stop_compose_id   = 'null-57' # space
  collector         = []
  composing         = false
  return $ ( d, send ) =>
    return send d unless ( select d, '^key' ) and ( d.move is 'down' )
    switch d.id
      when start_compose_id
        ### flush collected characters so far ###
        debug '39383', 'start_compose_id'
        composing         = true
        collector.length  = 0
      when stop_compose_id
        composing         = false
        return send d unless collector.length > 0
        composed_txt = "#{collector.join ''}"
        translations = {
          omega:  'ω'
          Omega:  'Ω' }
        composed_txt = translations[ composed_txt ] ? composed_txt
        debug '39383', 'stop_compose_id', rpr composed_txt
        CLIPBOARD                 = require 'clipboardy'
        CLIPBOARD.writeSync composed_txt
        # IFL.copy null, collector.join ''
        @send_backspace()
        @send_backspace() for _ in collector
        @send_backspace()
        @send_paste()
        collector.length = 0
      else
        if composing
          debug '39383', 'composing'
          collector.push d.text
        else
          send d
    return null

###
dsdfsdf´[omega]
dgdfgdf´1[1234}´oe[oemga}

dfsdfsdf[1234][omega]\omega [omega]
helo ω and Ω!!
xxxx23423423423423
sdhjsdhg jshd fkjsdhfkjfk jsjhajfh kjhs

dfadgdfgdfg ω
abcxr

###


#-----------------------------------------------------------------------------------------------------------
@send_backspace = ->
  # wmctrl -i -a #{S.windows.target} &&
  # xte 'usleep 250000' 'keydown Control_L' 'key v' 'keyup Control_L' &&
  # wmctrl -i -a #{S.windows.self}""".replace /\s+/gs, ' '
  # CP.execSync """xte 'keydown BackSpace' 'keyup BackSpace' 'usleep 250000'"""
  CP.execSync """xte 'keydown BackSpace' 'keyup BackSpace'"""

#-----------------------------------------------------------------------------------------------------------
@send_paste = ->
  CP.execSync """xte 'keydown Control_L' 'key v' 'keyup Control_L'"""


#-----------------------------------------------------------------------------------------------------------
@demo = ->
  warn "in case an EACCES error is raised, remember to run the keylogger with `sudo`"
  return new Promise ( resolve, reject ) =>
    keyboard_mapping  = await L.read_xevevents()
    source            = @read_from_keyboard keyboard_mapping
    pipeline          = []
    pipeline.push source
    pipeline.push @$compose_keys()
    # pipeline.push PD.$show()
    pipeline.push PD.$drain -> resolve()
    PD.pull pipeline...
    return null



############################################################################################################
unless module.parent?
  # f()
  L = @
  do ->
    # info '23883', keyboard_mapping
    # await L.read_xmodmap()
    await L.demo()

###

dumpkeys
loadkeys -C /dev/console -c
sudo loadkeys -C /dev/console -c
man loadkeys
loadkeys -c ./.XCompose
sudo dumpkeys
sudo evtest /dev/input/event3

 9976  ~/.local/bin/kbdgen
 9977  history | less -SR +G
 9978  xkbcomp -a

`pip3 install kbdgen` is a program to write xkb configurations; not yet
been able to use it successfully


`xev` shows same keycodes as used by xmodmap

110 without fn
112 with fn

~/.Xmodmap

###













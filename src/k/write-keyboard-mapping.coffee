
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERFLUG/K/read-keyboard-mapping'
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
{ XE
  $
  $async
  select }                = PD
{ assign
  jr }                    = CND

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
    path      = PATH.resolve __dirname, '../../src/k/xmodmap'
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
@write_keyboard_mapping = ->
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
  return new Promise ( resolve, reject ) =>
    input_path  = PATH.resolve  __dirname, '../../src/k/xev-events'
    output_path = PATH.resolve  __dirname, '../../src/k/keyboard-map.json'
    debug 'µ36633', "input path   ", input_path
    debug 'µ36633', "output path  ", output_path
    pipeline    = []
    pipeline.push PD.read_from_file input_path
    pipeline.push PD.$split()
    pipeline.push $group_lines()
    pipeline.push $filter_keypress_events()
    pipeline.push $declutter()
    pipeline.push $parse_event_text()
    pipeline.push $assemble()
    # pipeline.push PD.$show title: '33873-1'
    pipeline.push $ ( d, send ) -> send JSON.stringify d, null, '  '
    pipeline.push PD.write_to_file output_path
    PD.pull pipeline...
    return null

############################################################################################################
unless module.parent?
  do => await @write_keyboard_mapping()



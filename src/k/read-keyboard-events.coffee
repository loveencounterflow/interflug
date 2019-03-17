
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERFLUG/K'
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
CP                        = require 'child_process'
# IFL                       = require '../..'


#===========================================================================================================
# READ KEYBOARD
#-----------------------------------------------------------------------------------------------------------
@new_keyboard_event_source = ( keyboard_map = null ) ->
  # path      = '/dev/input/by-path/platform-i8042-serio-0-event-kbd'
  # source    = PD.read_chunks_from_file path, 24
  keyboard_map     ?= require PATH.resolve __dirname, '../../src/k/keyboard-map.json'
  source            = @_new_keyboard_bytestream()
  pipeline          = []
  pipeline.push source
  # pipeline.push PD.$watch ( x ) -> debug 'µ29982', ( CND.type_of x ), x?.length ? null
  pipeline.push @_$rechunk_buffer 24
  pipeline.push @_$decode_keyboard_event_buffer()
  pipeline.push @_$capture_levels()
  # pipeline.push @_$simplify_levels()
  pipeline.push @_$capture_modifiers()
  pipeline.push @_$map_keyboard_events keyboard_map
  #.........................................................................................................
  return PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@_$rechunk_buffer = ( bytecount ) ->
  return $ ( d, send ) =>
    unless ( type = CND.type_of d ) is 'buffer'
      throw new Error "expected a buffer, got a #{type}"
    unless ( d.length %% bytecount ) is 0
      throw new Error "not a multiple of #{bytecount}: #{d.length}"
    #.......................................................................................................
    for n in [ 0 ... d.length // bytecount ]
      start = n * bytecount
      stop  = start + bytecount
      send d.slice start, stop
    return null

#-----------------------------------------------------------------------------------------------------------
@_$decode_keyboard_event_buffer = ->
  keycodes      = require './_key-event-codes.data'
  return $ ( buffer, send ) ->
    return null unless ( type = buffer.readUInt16LE 16 ) is 1
    code  = buffer.readUInt16LE 18
    value = buffer.readInt32LE  20
    move  = if value is 1 then 'down' else 'up'
    name  = keycodes[ code ] ? null
    send PD.new_event '^keypress', { name, code, move, }
    return null

#-----------------------------------------------------------------------------------------------------------
@_$capture_levels = ->
  nested_levels = false
  prv_level     = null
  state         =
    shift:        false
    meta:         false
    ctrl:         false
    alt:          false
    altgr:        false
    capslock:     false
    numlock:      false
    insert:       false
    compose:      false
  #.........................................................................................................
  return $ ( d, send ) ->
    # debug '26622', d, prv_level
    v               = d.value
    level           = v.name.replace 'rightalt', 'altgr'
    level           = level.replace /^(left|right)/, ''
    is_within_level = state[ level ]
    is_shift        = is_within_level?
    if is_shift
      if v.move is 'down'
        prv_level = level
      else if level is prv_level
        unless nested_levels
          for name, toggle of state
            continue if name is level
            if toggle
              state[ name ] = false
              send PD.new_event '>keyboard-level', { name, }
        key             = if is_within_level then '>keyboard-level' else '<keyboard-level'
        state[ level ] = not state[ level ]
        send PD.new_event key, { name: level, }
    else
      prv_level = null
    send d

# #-----------------------------------------------------------------------------------------------------------
# @_$simplify_levels = ->
#   state         =
#     shift:        false
#     meta:         false
#     ctrl:         false
#     alt:          false
#     capslock:     false
#     numlock:      false
#     insert:       false
#     compose:      false
#   return $ ( d, send ) ->
#     return send d unless ( select d, '<keyboard-level' ) or ( select d, '>keyboard-level' )
#     v             = d.value
#     name          = v.name.replace /^(left|right)/, ''
#     state[ name ] = not state[ name ]
#     if state[ name ] then send PD.new_event '<keyboard-level', { name, }
#     else                  send PD.new_event '>keyboard-level', { name, }
#     return null

#-----------------------------------------------------------------------------------------------------------
@_$capture_modifiers = ->
  modifiers = []
  state     =
    shift:      false
    control:    false
    meta:       false
    alt:        false
    altgr:      false
    capslock:   false
  #.........................................................................................................
  return $ ( d, send ) ->
    return send d unless d.key is '^keypress'
    v = d.value
    switch v.name
      when 'leftshift', 'rightshift'  then state.shift    = ( v.move is 'down' )
      when 'leftmeta',  'rightmeta'   then state.meta     = ( v.move is 'down' )
      when 'leftctrl',  'rightctrl'   then state.ctrl     = ( v.move is 'down' )
      when 'leftalt'                  then state.alt      = ( v.move is 'down' )
      when 'rightalt'                 then state.altgr    = ( v.move is 'down' )
      when 'capslock'                 then state.capslock = ( v.move is 'down' )
      else
        modifiers.length = 0
        for name in [ 'alt', 'altgr', 'ctrl', 'meta', 'shift', 'capslock', ]
          continue unless state[ name ]
          v[ name ] = true
          modifiers.push name
        v.modifiers = modifiers.join '+' if modifiers.length > 0
        v.id        = "#{v.modifiers ? 'null'}-#{v.code}"
        send d
    return null

#-----------------------------------------------------------------------------------------------------------
@_$map_keyboard_events = ( keyboard_map ) ->
  return $ ( d, send ) ->
    d.text = mapping.text if ( mapping = keyboard_map[ d.id ] )?
    send d


#===========================================================================================================
@_new_keyboard_bytestream = ->
  path      = PATH.resolve __dirname, 'pipe-keyboard-to-stdout.js'
  command   = [ 'sudo', 'node', path, ]
  cp        = CP.spawn command[ 0 ], command[ 1 .. ], { shell: false, encoding: 'buffer', }
  @_new_stderr_catcher command, cp
  return PD.read_from_nodejs_stream cp.stdout

#-----------------------------------------------------------------------------------------------------------
@_new_stderr_catcher = ( command, cp ) ->
  source    = PD.read_from_nodejs_stream cp.stderr
  lines     = []
  pipeline  = []
  #.........................................................................................................
  cp.on 'exit', ( code ) ->
    if code isnt 0
      lines   = lines.join '\n'
      message = "#{lines}\nchild process #{jr command} exited with code #{code}"
      throw new Error message
    return null
  #.........................................................................................................
  pipeline.push source
  pipeline.push PD.$split()
  pipeline.push PD.$watch ( line ) -> lines.push line
  pipeline.push PD.$drain()
  PD.pull pipeline...
  return null



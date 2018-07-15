




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
CLIPBOARD                 = require 'clipboardy'
CP                        = require 'child_process'
#...........................................................................................................
is_tty                    = process.stdout.isTTY

#-----------------------------------------------------------------------------------------------------------
@new = ->
  R =
    '~isa':   'INTERFLUG/state'
    windows:
      self:     null
      target:   null

#-----------------------------------------------------------------------------------------------------------
@copy = ( S, text ) ->
  CLIPBOARD.write text.toString()
  return null

#-----------------------------------------------------------------------------------------------------------
@send_text = ( S, text = null ) ->
  @copy text if text?
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
@_get_id_of_active_window = ->
  command = """wmctrl -v -a :ACTIVE: 2>&1"""
  message = CP.execSync command, { encoding: 'utf-8', }
  return message.replace /^.*window:\s*(\S+)\s*$/gs, '$1'

#-----------------------------------------------------------------------------------------------------------
@_get_id_of_selected_window = ->
  command = """wmctrl -v -a :SELECT: 2>&1"""
  message = CP.execSync command, { encoding: 'utf-8', }
  return message.replace /^.*window:\s*(\S+)\s*$/gs, '$1'

#-----------------------------------------------------------------------------------------------------------
@set_window_ids = ( S ) ->
  urge "switch to the target window and click into it" if is_tty
  S.windows.self    = @_get_id_of_active_window()
  S.windows.target  = @_get_id_of_selected_window()
  @switch_to_window_by_id S.windows.self






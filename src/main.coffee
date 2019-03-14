




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
    command:    null
    windows:
      self:     null
      target:   null

#-----------------------------------------------------------------------------------------------------------
@copy = ( S, text ) ->
  CLIPBOARD.write text.toString()
  return null

#-----------------------------------------------------------------------------------------------------------
@send_text_to_target_window = ( S, text = null ) ->
  @copy S, text if text?
  S.command = """
    wmctrl -i -a #{S.windows.target} &&
    xte 'usleep 250000' 'keydown Control_L' 'key v' 'keyup Control_L' &&
    wmctrl -i -a #{S.windows.self}""".replace /\s+/gs, ' '
  CP.execSync S.command
  return null

#-----------------------------------------------------------------------------------------------------------
@switch_to_own_window     = ( S ) -> @_switch_to_window_by_id S, S.windows.self
@switch_to_target_window  = ( S ) -> @_switch_to_window_by_id S, S.windows.target

#-----------------------------------------------------------------------------------------------------------
@_switch_to_window_by_id = ( S, id ) ->
  S.command = """wmctrl -i -a #{id}"""
  message = CP.execSync S.command, { encoding: 'utf-8', }
  return null

#-----------------------------------------------------------------------------------------------------------
@_get_id_of_active_window = ( S ) ->
  S.command = """wmctrl -v -a :ACTIVE: 2>&1"""
  message = CP.execSync S.command, { encoding: 'utf-8', }
  return message.replace /^.*window:\s*(\S+)\s*$/gs, '$1'

#-----------------------------------------------------------------------------------------------------------
@_get_id_of_selected_window = ( S ) ->
  S.command = """wmctrl -v -a :SELECT: 2>&1"""
  message = CP.execSync S.command, { encoding: 'utf-8', }
  return message.replace /^.*window:\s*(\S+)\s*$/gs, '$1'

#-----------------------------------------------------------------------------------------------------------
@set_window_ids = ( S ) ->
  urge "switch to the target window and click into it" if is_tty
  S.windows.self    = @_get_id_of_active_window   S
  S.windows.target  = @_get_id_of_selected_window S
  @_switch_to_window_by_id S, S.windows.self

#-----------------------------------------------------------------------------------------------------------
@_read_pids_and_window_ids    = ( require './wid-from-pid' )._read_pids_and_window_ids.bind   @
@get_pids_and_window_ids      = ( require './wid-from-pid' ).get_pids_and_window_ids.bind     @
@window_id_from_pid           = ( require './wid-from-pid' ).window_id_from_pid.bind          @
@wait_for_window_id_from_pid  = ( require './wid-from-pid' ).wait_for_window_id_from_pid.bind @




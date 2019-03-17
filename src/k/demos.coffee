
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERFLUG/K/DEMO'
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
IFL                       = require '../..'
IFL.K                     = require './read-keyboard-events'


#===========================================================================================================
# DEMOS
#-----------------------------------------------------------------------------------------------------------
@$demo_compose_keys = ->
  start_compose_id  = 'null-13' # tick ('´')
  stop_compose_id   = 'null-57' # space
  collector         = []
  composing         = false
  return $ ( d, send ) =>
    return send d unless ( select d, '^key' ) and ( d.move is 'down' )
    switch d.id
      when start_compose_id
        ### flush collected characters so far ###
        # debug '39383', 'start_compose_id'
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
        # debug '39383', 'stop_compose_id', rpr composed_txt
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
          # debug '39383', 'composing'
          collector.push d.text
        else
          send d
    return null

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
@$emit = -> PD.$watch ( d ) -> XE.emit d
# XE.listen_to_all ( key, d ) =>
#   ( if d.key is '^key' then whisper else urge ) 'µ52982', jr d

#-----------------------------------------------------------------------------------------------------------
@demo_keyboard_bytestream = ->
  source    = L._new_keyboard_bytestream()
  pipeline  = []
  pipeline.push source
  # pipeline.push PD.$show()
  pipeline.push PD.$drain()
  PD.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@demo = ->
  source            = IFL.K.new_keyboard_event_source()
  pipeline          = []
  pipeline.push source
  pipeline.push @$demo_compose_keys()
  pipeline.push @$emit()
  pipeline.push PD.$show()
  pipeline.push PD.$drain()
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





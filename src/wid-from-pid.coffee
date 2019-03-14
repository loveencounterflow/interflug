
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERFLUG/WID-FROM-PID'
# debug                     = CND.get_logger 'debug',     badge
# warn                      = CND.get_logger 'warn',      badge
# info                      = CND.get_logger 'info',      badge
# urge                      = CND.get_logger 'urge',      badge
# help                      = CND.get_logger 'help',      badge
# whisper                   = CND.get_logger 'whisper',   badge
# echo                      = CND.echo.bind CND
#...........................................................................................................
CP                        = require 'child_process'


#-----------------------------------------------------------------------------------------------------------
@_read_pids_and_window_ids = ( pid = null ) ->
  ### Associate process IDs (PIDs) and GUI window IDs (WIDs) using `wmctrl`. When no `pid` is given, return
  a POD that maps PIDs to WIDs; if a `pid` is given, return either the matching WID or `null` if none was
  found. Instead of using this method directly, use `get_pids_and_window_ids()` and `window_id_from_pid pid`
  instead because of their clearer semantics. ###
  line_pattern  = /// ^ (?<wid> \S+ ) \s+ (?: \S+ ) \s+ (?<pid> \S+ ) \s+ ///
  R             = if pid? then null else {}
  command       = "wmctrl -lp"
  #.........................................................................................................
  split_line = ( line ) ->
    groups = ( line.match line_pattern ).groups
    # return { wid: groups.wid, pid: ( parseInt groups.pid, 10 ), }
    return [ ( parseInt groups.pid, 10 ), groups.wid, ]
  #.........................................................................................................
  message       = CP.execSync command, { encoding: 'utf-8', }
  lines         = message.split /\n/
  for line in lines
    continue if line is ''
    [ that_pid, that_wid, ] = split_line line
    if pid?
      return that_wid if pid is that_pid
      continue
    R[ that_pid ] = that_wid
  return R

#-----------------------------------------------------------------------------------------------------------
@get_pids_and_window_ids  =         -> @_read_pids_and_window_ids()
@window_id_from_pid       = ( pid ) -> @_read_pids_and_window_ids pid

#-----------------------------------------------------------------------------------------------------------
@wait_for_window_id_from_pid = ( pid, dtms = 500 ) ->
  return new Promise ( resolve, reject ) =>
    probe_wid = =>
      R = @window_id_from_pid pid
      if R?
        clearInterval tid
        resolve R
      return null
    tid = setInterval probe_wid, dtms
    return null


############################################################################################################
unless module.parent?
  L = @
  do ->
    info L.get_pids_and_window_ids()
    info L.window_id_from_pid 26418
    info L.window_id_from_pid 1111111
    return null




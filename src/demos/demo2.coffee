




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
IFL                       = require '../..'


# IFL.send_text '𢊟𨮘賔𩯭𩯫𩦿'
# IFL.send_text null

ifl = IFL.new()
IFL.set_window_ids              ifl
# IFL.switch_to_own_window        ifl
# IFL.switch_to_target_window     ifl
IFL.send_text_to_target_window  ifl, "demonstrating Unicode: äöü 书争事𫞖𫠠𫠣"
# IFL.switch_to_own_window        ifl
debug ifl

# help own_id = IFL.get_id_of_active_window()
# urge "switch to the target window and click into it"
# help target_id = IFL.get_id_of_selected_window()
# IFL.switch_to_window_by_id own_id
# # IFL.switch_to_window_by_id target_id





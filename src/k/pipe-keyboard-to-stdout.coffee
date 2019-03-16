

### TAINT make path configurable ###

'use strict'

FS    = require 'fs'
path  = '/dev/input/by-path/platform-i8042-serio-0-event-kbd'

( FS.createReadStream path ).pipe process.stdout







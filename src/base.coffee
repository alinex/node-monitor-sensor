# Ping test class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
object = require('alinex-util').object
colors = require 'colors'
{spawn} = require 'child_process'
util = require 'util'

# Sensor class
# -------------------------------------------------
# This class contains all the basics for each sensor.
class Sensor

  # ### Create instance
  constructor: (@config, @debug) ->
    unless @config
      throw new Error "Could not initialize sensor without configuration."

  # ### Protocol new start
  _start: ->
    @debug 'start check'
    @result =
      date: new Date
      status: 'running'
      value: {}

  # ### Protocol end of sensor run
  _end: (status, message, cb) ->
    # store overall status
    @result.status = status
    @result.message = message if message
    # report results
    out = {}
    for key, val of @config
      out[key] = val if val?
    @debug 'result values', util.inspect(@result.value).replace(/\s+/g, ' ').grey
    @debug 'check config', util.inspect(out).replace(/\s+/g, ' ').grey
    # return
    cb null, @

  # ### Helper to work with local commands
  _spawn: (cmd, args = [], options = [], cb) ->
    # create new subprocess
    @debug "exec> #{cmd} #{args.join ' '}"
    proc = spawn cmd, args, options
    # collect output
    stdout = stderr = ''
    proc.stdout.setEncoding "utf8"
    proc.stdout.on 'data', (data) =>
      stdout += (text = data.toString())
      for line in text.trim().split /\n/
        @debug line.grey
    proc.stderr.setEncoding "utf8"
    proc.stderr.on 'data', (data) =>
      stderr += (text = data.toString())
      for line in text.trim().split /\n/
        @debug line.magenta
    # error management
    error = null
    proc.on 'error', (err) =>
      @debug err.toString().red
      error = err
    # process finished
    proc.on 'close', (code) =>
      # get the success for the command
      @result.value.success = code is 0
      cb error, stdout, stderr, code


# Export class
# -------------------------------------------------
module.exports = Sensor

# Ping test class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
chalk = require 'chalk'
{spawn} = require 'child_process'
util = require 'util'
math = require 'mathjs'
# include other alinex modules
object = require('alinex-util').object
string = require('alinex-util').string

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
    @debug 'result values', chalk.grey util.inspect(@result.value).replace(/\s+/g, ' ')
    @debug 'check config', chalk.grey util.inspect(out).replace(/\s+/g, ' ')
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
        @debug chalk.grey line
    proc.stderr.setEncoding "utf8"
    proc.stderr.on 'data', (data) =>
      stderr += (text = data.toString())
      for line in text.trim().split /\n/
        @debug chalk.magenta line
    # error management
    error = null
    proc.on 'error', (err) =>
      @debug chalk.red err.toString()
      error = err
    # process finished
    proc.on 'close', (code) =>
      # get the success for the command
      @result.value.success = code is 0
      cb error, stdout, stderr, code

  # ### Format last result
  format: ->
    meta = @constructor.meta
    text = """
      #{meta.description}\n\nLast check results are:

      |       RESULT       |  VALUE                                             |
      | ------------------ | -------------------------------------------------: |\n"""
    # table of values
    for name, set of meta.values
      val = ''
      if @result.value[name]?
        val = switch set.type
          when 'percent'
            (Math.round(@result.value[name] * 100) / 100).toString() + ' %'
          when 'byte'
            byte = math.unit @result.value[name], (set.unit ? 'B')
            byte.format 3
          when 'interval'
            interval = math.unit @config[name], set.unit
            interval.format 3
          else
            val = @result.value[name]
            val += " #{set.unit}" if val and set.unit
            val
      text += "| #{string.rpad set.title, 18}
      | #{string.lpad val.toString(), 50} |\n"
    # configuration settings
    text += """
      \nAnd the following configuration was used:

      |       CONFIG       |  VALUE                                             |
      | ------------------ | -------------------------------------------------: |\n"""
    for name, set of meta.config.entries
      val = ''
      continue unless @config[name]?
      val = switch set.type
        when 'percent'
          (Math.round(@config[name] * 100) / 100).toString() + ' %'
        when 'byte'
          byte = math.unit @config[name], 'B'
          byte.format 3
        when 'interval'
          interval = math.unit @config[name], set.unit
          interval.format 3
        else
          val = @config[name]
          val += " #{set.unit}" if val and set.unit
          val
      text += "| #{string.rpad set.title, 18}
      | #{string.lpad val.toString(), 50} |\n"
    # additional information
    text += "\n#{@result.analysis}" if @result.analysis?
    # hint
    text += "\n#{meta.hint} " if meta.hint

# Export class
# -------------------------------------------------
module.exports = Sensor

# Cpu test class
# =================================================
# This may be used to check the overall memory use of a host.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:cpu')
# include alinex packages
object = require('alinex-util').object
string = require('alinex-util').string
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'
fs = require 'fs'
{exec} = require 'child_process'

# Sensor class
# -------------------------------------------------
class CpuSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Cpu'
    description: "Check the current activity in average percent of all cores."
    category: 'sys'
    level: 1
    hint: "A high cpu usage means that the server may not start another task immediately.
    If the load is also very high the system is overloaded check if any application
    goes evil."
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "CPU check"
      type: 'object'
      allowedKeys: true
      entries:
        fail:
          title: "%CPU Fail"
          description: "the activity level for all cpus to be considered as fail"
          type: 'percent'
          optional: true
          min: 0
        warn:
          title: "%CPU Warn"
          description: "the activity level for all cpus to be considered as ok"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<fail'
    # Definition of response values
    values:
      cpu:
        title: "CPU Model"
        description: "cpu model name with brand"
        type: 'string'
      cpus:
        title: "cpu cores"
        description: "number of cpu cores"
        type: 'integer'
      speed:
        title: "cpu speed"
        description: "speed in MHz"
        type: 'integer'
        unit: 'MHz'
      user:
        title: "User time"
        description: "percentage of user time over all cpu cores"
        type: 'percent'
      system:
        title: "System time"
        description: "percentage of system time over all cpu cores"
        type: 'percent'
      idle:
        title: "Idle time"
        description: "percentage of idle time over all cpu cores"
        type: 'percent'
      active:
        title: "Activity"
        description: "percentage of active time over all cpu cores"
        type: 'percent'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    # get data
    load = os.loadavg()
    cpus = os.cpus()
    # calculate values
    val = @result.value
    val.cpus = cpus.length
    val.cpu = cpus[0].model.replace /\s+/g, ' '
    val.speed = cpus[0].speed
    times =
      user: 0
      sys: 0
      idle: 0
    for cpu in cpus
      times[v] += cpu.times[v] for v in ['user', 'sys', 'idle']
    # calculate percentage
    total = times.user + times.sys + times.idle
    val.user = times.user / total
    val.system = times.sys / total
    val.idle = times.idle / total
    val.active = val.user + val.system
    # evaluate to check status
    status = switch
      when @config.fail? and val.active > @config.fail
        'fail'
      when @config.warn? and val.active > @config.warn
        'warn'
      else
        'ok'
    message = switch status
      when 'fail'
        "too high activity on cpu"
    # done if no problem found
    if status is 'ok'
      return @_end status, message, cb
    # get additional information
    cmd = "ps axu | awk '{print $2, $3, $4, $11}' | sort -k2 -nr | head -5"
    exec cmd, (err, stdout, stderr) =>
      unless err
        @result.analysis = """
        Currently the top cpu consuming processes are:

        |  PID  |  %CPU |  %MEM | COMMAND                                            |
        | ----: | ----: | ----: | -------------------------------------------------- |\n"""
        for line in stdout.toString().split /\n/
          continue unless line
          col = line.split /\s/, 4
          @result.analysis += "| #{string.lpad col[0], 5} | #{string.lpad col[1], 5}
            | #{string.lpad col[2], 5} | #{string.rpad col[3], 50} |\n"
        debug @result.analysis
      @_end status, message, cb

  # ### Format last result
  format: ->
    meta = @constructor.meta
    text = """
      #{meta.description}\n\nLast check results are:

      |       RESULT       |    VALUE     |     WARN     |    ERROR     |
      | ------------------ | -----------: | -----------: | -----------: |\n"""
    # table of values
    for name, set of meta.values
      val = ''
      if @result.value[name]?
        val = switch set.type
          when 'percent'
            (Math.round(@result.value[name] * 100) / 100).toString() + ' %'
          else
            val = @result.value[name]
            val += " #{set.unit}" if val and set.unit
            val
      text += "| #{string.rpad set.title, 18} "
      if name is 'cpu'
        text += "| #{string.rpad val.toString(), 42} |\n"
        continue
      text += "| #{string.lpad val.toString(), 12} "
      if name is 'active'
        warn = if @config.warn? then @config.warn.toString()+' %' else ''
        fail = if @config.fail? then @config.fail.toString()+' %' else ''
        text += "| #{string.lpad warn, 12}
        | #{string.lpad fail, 12} |\n"
      else
        text += "|              |              |\n"
    # additional information
    text += "\n#{@result.analysis}" if @result.analysis?
    # hint
    text += "\nHINT: #{meta.hint} " if meta.hint
    text

# Export class
# -------------------------------------------------
module.exports = CpuSensor

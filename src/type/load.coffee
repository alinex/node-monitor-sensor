# Load test class
# =================================================
# This may be used to check the performance of a host.
#
# The load values will be normalized, meaning the load per single cpu core will
# be calculated.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:load')
# include alinex packages
object = require('alinex-util').object
string = require('alinex-util').string
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'
{exec} = require 'child_process'

# Sensor class
# -------------------------------------------------
class LoadSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Load'
    description: "Check the local processor activity over the last minute to 15 minutes."
    category: 'sys'
    level: 1
    hint: "A very high system load makes the system irresponsible or really slow.
    Mostly this is CPU-bound load, load caused by out of memory issues or I/O-bound
    load problems. "

    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "CPU load check"
      type: 'object'
      allowedKeys: true
      entries:
        shortFail:
          title: "1min load fail"
          description: "the minimum level for the one minute load average to fail"
          type: 'percent'
          optional: true
          min: 0
        shortWarn:
          title: "1min load warn"
          description: "the minimum level for the one minute load average to warn"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<shortFail'
        mediumFail:
          title: "5min load fail"
          description: "the minimum level for the 5 minute load average to fail"
          type: 'percent'
          optional: true
          min: 0
        mediumWarn:
          title: "5min load warn"
          description: "the minimum level for the 5 minute load average to warn"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<mediumFail'
        longFail:
          title: "15min load fail"
          description: "the minimum level for the 15 minute load average to fail"
          type: 'percent'
          optional: true
          min: 0
        longWarn:
          title: "15min load warn"
          description: "the minimum level for the 15 minute load average to warn"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<longFail'
    # Definition of response values
    values:
      cpu:
        title: "CPU"
        description: "cpu model name with brand"
        type: 'string'
      cpus:
        title: "Num Cores"
        description: "number of cpu cores"
        type: 'integer'
      short:
        title: "1min Load"
        description: "average value of one minute processor load (normalized)"
        type: 'percent'
      medium:
        title: "5min Load"
        description: "average value of 5 minute processor load (normalized)"
        type: 'percent'
      long:
        title: "15min Load"
        description: "average value of 15 minute processor load (normalized)"
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
    val.short = load[0] / val.cpus
    val.medium = load[1] / val.cpus
    val.long = load[2] / val.cpus
    # evaluate to check status
    status = switch
      when @config.shortFail? and val.short > @config.shortFail, \
           @config.mediumFail? and val.medium > @config.mediumFail, \
           @config.longFail? and val.long > @config.longFail
        'fail'
      when @config.shortWarn? and val.short > @config.shortWarn, \
           @config.mediumWarn? and val.medium > @config.mediumWarn, \
           @config.longWarn? and val.long > @config.longWarn
        'warn'
      else
        'ok'
    message = switch status
      when 'fail'
        "#{@constructor.meta.name} exited with status #{status}"
    if status is 'ok'
      return @_end status, message, cb
    # get additional information
    cmd = "ps axu | awk 'NR>1 {print $2, $3, $4, $11}'"
    exec cmd, (err, stdout, stderr) =>
      console.log '-------------------------------'
      unless err
        procs = {}
        for line in stdout.toString().split /\n/
          continue unless line
          col = line.split /\s/, 4
          unless procs[col[3]]
            procs[col[3]] = [ 0, 0, 0 ]
          procs[col[3]][0]++
          procs[col[3]][1] += parseFloat col[1]
          procs[col[3]][2] += parseFloat col[2]
        keys = Object.keys(procs).sort (a,b) ->
          (procs[b][0]*100+procs[b][1]) - (procs[a][0]*100+procs[a][1])
        @result.analysis = """
        Currently the top processes are:

        | COUNT |  %CPU |  %MEM | COMMAND                                            |
        | ----: | ----: | ----: | -------------------------------------------------- |\n"""
        for proc in keys
          value = procs[proc]
          continue if value[0] is 1 and value[1] < 10
          @result.analysis += "| #{string.lpad value[0], 5} | #{string.lpad value[1], 5}
          | #{string.lpad value[2], 5} | #{string.rpad proc, 50} |\n"
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
      if name in ['ashort','medium','long']
        warn = if @config["#{name}Warn"]? then @config["#{name}Warn"].toString()+' %' else ''
        fail = if @config["#{name}Fail"]? then @config["#{name}Fail"].toString()+' %' else ''
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
module.exports = LoadSensor

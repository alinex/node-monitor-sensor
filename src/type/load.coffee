# Load test class
# =================================================
# This may be used to check the performance of a host.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:load')
colors = require 'colors'
# include alinex packages
object = require('alinex-util').object
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'

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
        tittle: "cpu"
        description: "cpu model name with brand"
        type: 'string'
      cpus:
        title: "cpu cores"
        description: "number of cpu cores"
        type: 'integer'
      short:
        title: "1min load"
        description: "average value of one minute processor load"
        type: 'percent'
      medium:
        title: "5min load"
        description: "average value of 5 minute processor load"
        type: 'percent'
      long:
        title: "15min load"
        description: "average value of 15 minute processor load"
        type: 'percent'


  # ### Run the check
  run: (cb = ->) ->

    # run the load test
    @_start "Check local system load"

    @result.value = value = {}
    cpus = os.cpus()
    value.cpus = cpus.length
    value.cpu = cpus[0].model.replace /\s+/g, ' '
    load = os.loadavg()
    value.short = load[0] / value.cpus
    value.medium = load[1] / value.cpus
    value.long = load[2] / value.cpus
    debug value

    # evaluate to check status
    status = switch
      when @config.shortFail? and value.short > @config.shortFail, \
           @config.mediumFail? and value.medium > @config.mediumFail, \
           @config.longFail? and value.long > @config.longFail
        'fail'
      when @config.shortWarn? and value.short > @config.shortWarn, \
           @config.mediumWarn? and value.medium > @config.mediumWarn, \
           @config.longWarn? and value.long > @config.longWarn
        'warn'
      else
        'ok'
    message = switch status
      when 'fail'
        "#{@constructor.meta.name} exited with status #{status}"
    debug @config
    @_end status, message
    cb null, @


# Export class
# -------------------------------------------------
module.exports = LoadSensor

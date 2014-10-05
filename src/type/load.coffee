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
    @_end status, message, cb


# Export class
# -------------------------------------------------
module.exports = LoadSensor

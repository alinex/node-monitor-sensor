# Memory test class
# =================================================
# This may be used to check the overall memory use of a host.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:memory')
colors = require 'colors'
# include alinex packages
object = require('alinex-util').object
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'

# Sensor class
# -------------------------------------------------
class MemorySensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Memory'
    description: "Check the free memory on localhost."
    category: 'sys'
    level: 1
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Memory check"
      type: 'object'
      allowedKeys: true
      entries:
        freeFail:
          title: "free memory to fail"
          description: "the minimum free memory which is needed to not fail"
          type: 'byte'
          optional: true
          min: 0
        freeWarn:
          title: "free memory to warn"
          description: "the minimum free memory which is needed to be ok"
          type: 'byte'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<freeFail'
        percentFail:
          title: "percent of free memory to fail"
          description: "the minimum free memory which is needed to not fail in percent"
          type: 'percent'
          optional: true
          min: 0
        percentWarn:
          title: "percent of free memory to warn"
          description: "the minimum free memory which is needed to be ok in percent"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<percentFail'
        swapFail:
          title: "free swap memory to fail"
          description: "the minimum free swap memory which is needed to not fail"
          type: 'byte'
          optional: true
          min: 0
        swapWarn:
          title: "free swap memory to warn"
          description: "the minimum free swap memory which is needed to be ok"
          type: 'byte'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<swapFail'
        swapPercentFail:
          title: "percent of free swap memory to fail"
          description: "the minimum free swap memory which is needed to not fail in percent"
          type: 'percent'
          optional: true
          min: 0
        swapPercentWarn:
          title: "percent of free swap memory to warn"
          description: "the minimum free swap memory which is needed to be ok in percent"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<swapPercentFail'
    # Definition of response values
    values:
      success:
        title: 'Success'
        description: "true if external command runs successfully"
        type: 'boolean'
      total:
        tittle: "Total"
        description: "total system memory"
        type: 'byte'
      used:
        title: "Used"
        description: "used system memory"
        type: 'byte'
      free:
        title: "Free"
        description: "free system memory"
        type: 'byte'
      shared:
        title: "Shared"
        description: "shared system memory"
        type: 'byte'
      buffers:
        title: "Buffers"
        description: "system memory used as buffer"
        type: 'byte'
      cached:
        title: "Cached"
        description: "system memory used as cache"
        type: 'byte'
      swapTotal:
        title: "Swap Total"
        description: "total swap memory"
        type: 'byte'
      swapUsed:
        title: "Swap Used"
        description: "used swap memory"
        type: 'byte'
      swapFree:
        title: "Swap Free"
        description: "free swap memory"
        type: 'byte'
      actualFree:
        title: "Actual Free"
        description: "real free system memory"
        type: 'byte'
      percentFree:
        title: "Percent Free"
        description: "percentage of real free system memory"
        type: 'percent'
      swapPercentFree:
        title: "Swap Percent Free"
        description: "percentage of free swap memory"
        type: 'percent'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    @_spawn 'free', null, null, (err, stdout, stderr, code) =>
      return @_end 'fail', err, cb if err
      # parse results
      lines = []
      for line in stdout.split /\n/g
        lines.push line.split /\s+/
      # calculate results
      val = @result.value
      val.total = parseInt lines[1][1]
      val.used = parseInt lines[1][2]
      val.free = parseInt lines[1][3]
      val.shared = parseInt lines[1][4]
      val.buffers = parseInt lines[1][5]
      val.cached = parseInt lines[1][6]
      val.swapTotal = parseInt lines[3][1]
      val.swapUsed = parseInt lines[3][2]
      val.swapFree = parseInt lines[3][3]
      val.actualFree = val.free + val.buffers + val.cached
      val.percentFree = val.actualFree/val.total
      val.swapPercentFree = val.swapFree/val.swapTotal
      # evaluate to check status
      status = switch
        when not val.success, \
             @config.freeFail? and val.actualFree < @config.freeFail, \
             @config.percentFail? and val.percentFree < @config.percentFail, \
             @config.swapFail? and val.swapFree < @config.swapFail, \
             @config.swapPercentFail? and val.swapPercentFree < @config.swapPercentFail
          'fail'
        when @config.freeWarn? and val.actualFree < @config.freeWarn, \
             @config.percentWarn? and val.percentFree < @config.percentWarn, \
             @config.swapWarn? and val.swapFree < @config.swapWarn, \
             @config.swapPercentWarn? and val.swapPercentFree < @config.swapPercentWarn
          'warn'
        else
          'ok'
      message = switch status
        when 'fail'
          if val.success
            "Not enought free memory left on system"
          else
            "#{@constructor.meta.name} check exited with status #{status}"
      @_end status, message, cb


# Export class
# -------------------------------------------------
module.exports = MemorySensor

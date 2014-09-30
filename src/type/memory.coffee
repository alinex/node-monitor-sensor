# Memory test class
# =================================================
# This may be used to check the overall memory use of a host.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:memory')
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
    hint: "Check which process consumes how much memory, maybe some processes have
      a memory leak."
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Memory check"
      type: 'object'
      allowedKeys: true
      entries:
        freeFail:
          title: "Free Fail"
          description: "the minimum free memory which is needed to not fail"
          type: 'byte'
          optional: true
          min: 0
        freeWarn:
          title: "Free Warn"
          description: "the minimum free memory which is needed to be ok"
          type: 'byte'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<freeFail'
        percentFail:
          title: "%Free Fail"
          description: "the minimum free memory which is needed to not fail in percent"
          type: 'percent'
          optional: true
          min: 0
        percentWarn:
          title: "%Free Warn"
          description: "the minimum free memory which is needed to be ok in percent"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<percentFail'
        swapFail:
          title: "Swap Fail"
          description: "the minimum free swap memory which is needed to not fail"
          type: 'byte'
          optional: true
          min: 0
        swapWarn:
          title: "Swap Warn"
          description: "the minimum free swap memory which is needed to be ok"
          type: 'byte'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<swapFail'
        swapPercentFail:
          title: "%Swap Fail"
          description: "the minimum free swap memory which is needed to not fail in percent"
          type: 'percent'
          optional: true
          min: 0
        swapPercentWarn:
          title: "%Swap Warn"
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
        title: "Total"
        description: "total system memory"
        type: 'byte'
        unit: 'kB'
      used:
        title: "Used"
        description: "used system memory"
        type: 'byte'
        unit: 'kB'
      free:
        title: "Free"
        description: "free system memory"
        type: 'byte'
        unit: 'kB'
      shared:
        title: "Shared"
        description: "shared system memory"
        type: 'byte'
        unit: 'kB'
      buffers:
        title: "Buffers"
        description: "system memory used as buffer"
        type: 'byte'
        unit: 'kB'
      cached:
        title: "Cached"
        description: "system memory used as cache"
        type: 'byte'
        unit: 'kB'
      swapTotal:
        title: "Swap Total"
        description: "total swap memory"
        type: 'byte'
        unit: 'kB'
      swapUsed:
        title: "Swap Used"
        description: "used swap memory"
        type: 'byte'
        unit: 'kB'
      swapFree:
        title: "Swap Free"
        description: "free swap memory"
        type: 'byte'
        unit: 'kB'
      actualFree:
        title: "Actual Free"
        description: "real free system memory"
        type: 'byte'
        unit: 'kB'
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
      # done if no problem found
      if status is 'ok'
        return @_end status, message, cb
      # get additional information
      cmd = "ps axu | awk '{print $2, $3, $4, $11}' | sort -k3 -nr | head -5"
      exec cmd, (err, stdout, stderr) =>
        unless err
          @result.analysis = """
          Currently the top memory consuming processes are:

          |  PID  |  %CPU |  %MEM | COMMAND                                            |
          | ----: | ----: | ----: | -------------------------------------------------- |\n"""
          for line in stdout.toString().split /\n/
            continue unless line
            col = line.split /\s/, 4
            @result.analysis += "| #{string.lpad col[0], 5} | #{string.lpad col[1], 5}
              | #{string.lpad col[2], 5} | #{string.rpad col[3], 50} |\n"
          debug @result.analysis
        @_end status, message, cb


# Export class
# -------------------------------------------------
module.exports = MemorySensor

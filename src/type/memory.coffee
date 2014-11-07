# Memory test class
# =================================================
# This may be used to check the overall memory use of a host.
# It will only work on unix like systems which has the `free` tool (available on
# most systems) installed.

# Find the description of the possible configuration values and the returned
# values in the code below.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:memory')
# include alinex packages
{object,string} = require 'alinex-util'
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'
{exec} = require 'child_process'
math = require 'mathjs'

# Sensor class
# -------------------------------------------------
class MemorySensor extends Sensor

  # ### General information
  #
  # This information may be used later for display and explanation.
  @meta =
    name: 'Memory'
    description: "Check the free memory on localhost."
    category: 'sys'
    level: 1
    hint: "Check which process consumes how much memory, maybe some processes have
      a memory leak."

    # ### Configuration
    #
    # Definition of all possible configuration settings (defaults included).
    # It's a n[alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible schema definition:
    config:
      title: "Memory check"
      type: 'object'
      allowedKeys: true
      entries:
        analysis:
          title: "Top X"
          description: "the number of top memory consuming processes for analysis"
          type: 'integer'
          min: 1
          default: 5
        verbose: @check.verbose
        warn: @check.warn
        fail: object.extend { default: 'percentFree is 0 and swapPercentFree is 0' }, @check.fail

    # ### Result values
    #
    # This are possible values which may be given if the check runs normally.
    # You may use any of these in your warn/fail expressions.
    values:
      total:
        title: "Total"
        description: "total system memory"
        type: 'byte'
        unit: 'B'
      used:
        title: "Used"
        description: "used system memory"
        type: 'byte'
        unit: 'B'
      free:
        title: "Free"
        description: "free system memory"
        type: 'byte'
        unit: 'B'
      shared:
        title: "Shared"
        description: "shared system memory"
        type: 'byte'
        unit: 'B'
      buffers:
        title: "Buffers"
        description: "system memory used as buffer"
        type: 'byte'
        unit: 'B'
      cached:
        title: "Cached"
        description: "system memory used as cache"
        type: 'byte'
        unit: 'B'
      swapTotal:
        title: "Swap Total"
        description: "total swap memory"
        type: 'byte'
        unit: 'B'
      swapUsed:
        title: "Swap Used"
        description: "used swap memory"
        type: 'byte'
        unit: 'B'
      swapFree:
        title: "Swap Free"
        description: "free swap memory"
        type: 'byte'
        unit: 'B'
      actualFree:
        title: "Actual Free"
        description: "real free system memory"
        type: 'byte'
        unit: 'B'
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
      val = @result.values
      val.total = math.unit(parseInt(lines[1][1]), 'kB').toNumber 'B'
      val.used = math.unit(parseInt(lines[1][2]), 'kB').toNumber 'B'
      val.free = math.unit(parseInt(lines[1][3]), 'kB').toNumber 'B'
      val.shared = math.unit(parseInt(lines[1][4]), 'kB').toNumber 'B'
      val.buffers = math.unit(parseInt(lines[1][5]), 'kB').toNumber 'B'
      val.cached = math.unit(parseInt(lines[1][6]), 'kB').toNumber 'B'
      val.swapTotal = math.unit(parseInt(lines[3][1]), 'kB').toNumber 'B'
      val.swapUsed = math.unit(parseInt(lines[3][2]), 'kB').toNumber 'B'
      val.swapFree = math.unit(parseInt(lines[3][3]), 'kB').toNumber 'B'
      val.actualFree = val.free + val.buffers + val.cached
      val.percentFree = val.actualFree/val.total
      val.swapPercentFree = val.swapFree/val.swapTotal
      # evaluate to check status
      status = @rules()
      message = @config[status] unless status is 'ok'
      # done if no problem found
      if status is 'ok' and not @config.verbose
        return @_end status, message, cb
      # get additional information
      cmd = "ps axu | awk '{print $2, $3, $4, $11}' | sort -k3 -nr | head -#{@config.analysis}"
      exec cmd, (err, stdout, stderr) =>
        unless err
          @result.analysis = """
          Currently the top #{@config.analysis} memory consuming processes are:

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

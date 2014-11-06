# Check disk space
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:io')
fs = require 'fs'
# include alinex packages
object = require('alinex-util').object
# include classes and helper
Sensor = require '../base'
# specific modules for this check
os = require 'os'
math = require 'mathjs'

# Sensor class
# -------------------------------------------------
class IoSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Disk IO'
    description: "Check the io traffic using the additional `iostat` program."
    category: 'sys'
    level: 1
    hint: "If there are any problems here check the device for hardware or
    network problems."
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Disk IO Test"
      type: 'object'
      allowedKeys: true
      entries:
        device:
          title: "Device name"
          description: "the disk's device name like sda, ..."
          type: 'string'
        time:
          title: "Measurement Time"
          description: "the time for the measurement"
          type: 'interval'
          unit: 's'
          default: 1
          min: 1
        warn: @check.warn
        fail: object.extend { default: 'wait >= 100%' }, @check.fail

    # Definition of response values
    values:
      wait:
        title: "IO Wait"
        description: "the time spent by the CPU waiting for IO operations to complete"
        type: 'percent'
      tps:
        title: "Transfers/s"
        description: "the number of transfers (I/O requests) per second that
        were issued to the device"
        type: 'float'
      read:
        title: "Read/s"
        description: "the amount of data read from the device per second"
        type: 'byte'
        unit: 'B'
      write:
        title: "Write/s"
        description: "the amount of data written to the device per second"
        type: 'byte'
        unit: 'B'
      readTotal:
        title: "Total Read"
        description: "the total amount of read data"
        type: 'byte'
        unit: 'B'
      writeTotal:
        title: "Total Write"
        description: "the total amount of written data"
        type: 'byte'
        unit: 'B'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    # comand syntax, os dependent
    p = os.platform()
    unless p in ['linux', 'darwin']
      throw new Error "sensor can only work on linux systems"
    iostat = '/usr/bin/iostat'
    fs.exists iostat, (exists) =>
      unless exists
        throw new Error "missing the `iostat` command, install through
        `sudo apt-get install sysstat`"
      # run the iostat test
      @result.range = [new Date]
      @_spawn iostat, ['-k', @config.time, 1], null, (err, stdout, stderr, code) =>
        @result.range.push new Date
        return @_end 'fail', err, cb if err
        # parse results
        val = @result.values
        lines = stdout.split /\n/
        col = lines[3].split /\s+/
        val.wait = parseFloat(col[4]) / 100
        for i in [6..lines.length-1]
          col = lines[i].split /\s+/
          continue unless @config.device is col[0]
          val.tps = parseFloat col[1]
          val.read = math.unit(parseFloat(col[2]), 'kB').toNumber 'B'
          val.write = math.unit(parseFloat(col[3]), 'kB').toNumber 'B'
          val.readTotal = math.unit(parseFloat(col[4]), 'kB').toNumber 'B'
          val.writeTotal = math.unit(parseFloat(col[5]), 'kB').toNumber 'B'
        # evaluate to check status
        status = @rules()
        message = @config[status] unless status is 'ok'
        return @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = IoSensor

# Check disk space
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:io')
# include alinex packages
fs = require 'fs'
# include classes and helper
Sensor = require '../base'
# specific modules for this check
os = require 'os'

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
        waitWarn:
          title: "%Wait Warn"
          description: "the maximum io wait percentage of cpu"
          optional: true
          type: 'percent'
          min:
            reference: 'relative'
            source: '<waitFail'
          max: 1
        waitFail:
          title: "%Wait Fail"
          description: "the maximum io wait percentage of cpu"
          optional: true
          type: 'percent'
          min: 0
          max: 1
        readWarn:
          title: "Read/s Warn"
          description: "the read limit per second on the device"
          optional: true
          type: 'byte'
          unit: 'B'
          min:
            reference: 'relative'
            source: '<readFail'
        readFail:
          title: "Read/s Fail"
          description: "the read limit per second on the device"
          optional: true
          type: 'byte'
          unit: 'B'
          min: 0
        writeWarn:
          title: "Write/s Warn"
          description: "the write limit per second on the device"
          optional: true
          type: 'byte'
          unit: 'B'
          min:
            reference: 'relative'
            source: '<writeFail'
        writeFail:
          title: "Write/s Fail"
          description: "the write limit per second on the device"
          optional: true
          type: 'byte'
          unit: 'B'
          min: 0

    # Definition of response values
    values:
      success:
        title: 'Success'
        description: "true if external command runs successfully"
        type: 'boolean'
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
        unit: 'kB'
      write:
        title: "Write/s"
        description: "the amount of data written to the device per second"
        type: 'byte'
        unit: 'kB'
      readTotal:
        title: "Total Read"
        description: "the total amount of read data"
        type: 'byte'
        unit: 'kB'
      writeTotal:
        title: "Total Write"
        description: "the total amount of written data"
        type: 'byte'
        unit: 'kB'

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
      @_spawn iostat, ['-k', @config.time, 1], null, (err, stdout, stderr, code) =>
        return @_end 'fail', err, cb if err
        # parse results
        val = @result.value
        lines = stdout.split /\n/
        col = lines[3].split /\s+/
        val.wait = parseFloat(col[4]) / 100
        for i in [6..lines.length-1]
          col = lines[i].split /\s+/
          continue unless @config.device is col[0]
          val.tps = parseFloat col[1]
          val.read = parseFloat col[2]
          val.write = parseFloat col[3]
          val.readTotal = parseFloat col[4]
          val.writeTotal = parseFloat col[5]
        # evaluate to check status
        switch
          when @config.waitFail? and val.wait > @config.waitFail
            status = 'fail'
            message = "#{@constructor.meta.name} too high cpu wait for #{@config.device}"
          when @config.readFail? and val.read > @config.readFail
            status = 'fail'
            message = "#{@constructor.meta.name} too much read on #{@config.device}"
          when @config.writeFail? and val.write > @config.writeFail
            status = 'fail'
            message = "#{@constructor.meta.name} too much written on #{@config.device}"
          when @config.waitWarn? and val.wait > @config.waitWarn
            status = 'warn'
          when @config.readWarn? and val.read > @config.readWarn
            status = 'warn'
          when @config.writeWarn? and val.write > @config.writeWarn
            status = 'warn'
          else
            status = 'ok'
        return @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = IoSensor

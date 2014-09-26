# Check disk space
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:diskfree')
colors = require 'colors'
# include alinex packages
{object,number} = require 'alinex-util'
# include classes and helper
Sensor = require '../base'
# specific modules for this check
os = require 'os'

# Sensor class
# -------------------------------------------------
class DiskfreeSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Diskfree'
    description: "Test the free diskspace of one share."
    category: 'sys'
    level: 1
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Disk free Test"
      type: 'object'
      allowedKeys: true
      entries:
        share:
          title: "Share or mount point"
          description: "the disk share's path or mount point to check"
          type: 'string'
        timeout:
          title: "Overall Timeout"
          description: "the time in milliseconds the whole test may take before
            stopping and failing it"
          type: 'interval'
          unit: 'ms'
          min: 500
          default: 1000
        freeWarn:
          type: 'any'
          optional: true
          entries: [
            type: 'byte'
            min:
              reference: 'relative'
              source: '<freeFail'
          ,
            type: 'percent'
            min:
              reference: 'relative'
              source: '<freeFail'
          ]
        freeFail:
          type: 'any'
          optional: true
          entries: [
            type: 'byte'
          ,
            type: 'percent'
          ]

    # Definition of response values
    values:
      share:
        title: 'Share'
        description: "path name of the share"
        type: 'string'
      type:
        title: 'type'
        description: "type of filesystem"
        type: 'string'
      total:
        title: 'Available'
        description: "the space, which is available"
        type: 'integer'
        unit: 'bytes'
      used:
        title: 'Used'
        description: "the space, which is already used"
        type: 'integer'
        unit: 'bytes'
      free:
        title: 'Free'
        description: "the space, which is free"
        type: 'integer'
        unit: 'bytes'
      mount:
        title: 'Mountpoint'
        description: "the path this share is mounted to"
        type: 'string'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    # comand syntax, os dependent
    p = os.platform()
    diskfree = switch p
      when 'linux', 'darwin'
        cmd: '/bin/df'
        args: ['-kT', @config.share]
      when p.match /^win/
        # For windows maybe [drivespace](https://github.com/keverw/drivespace)
        # works, but this is not tested.
        cmd: '../bin/drivespace.exe'
        args: ["drive-#{@config.share}"]
      else
        throw new Error "Operating system #{p} is not supported in diskfree."
    # run the diskfree test
    @_spawn diskfree.cmd, diskfree.args,
      timeout: @config.timeout
    , (err, stdout, stderr, code) =>
      return @_end 'fail', err, cb if err
      # parse results
      lines = stdout.split /\n/
      val = @result.value
      if p.match /^win/
        [val.total, val.free, status]
        col = lines[0].split ','
        val.total = Number(col[0])*1024
        val.free = Number(col[1])*1024
        val.used = val.total - val.free
        val.mount = @config.share
      else
        col = lines[1].split /\s+/
        val.share = col[0]
        val.type = col[1]
        val.used = Number(col[3])*1024
        val.free = Number(col[4])*1024
        val.total = val.used + val.free
        val.mount = col[6]
      # evaluate to check status
      switch
        when val.used + val.avail is 0
          status = 'fail'
          message = "#{@constructor.meta.name} no space available on share #{@config.share}"
        when @config.freeFail? and val.free < @config.freeFail
          status = 'fail'
          message = "#{@constructor.meta.name} too less space on #{@config.share}"
        when @config.freeWarn? and val.free < @config.freeWarn
          status = 'warn'
        else
          status = 'ok'
      @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = DiskfreeSensor

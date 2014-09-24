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
{exec} = require 'child_process'

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
          description: "the disk share or mount point to check"
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


  # ### Run the check
  run: (cb = ->) ->

    # comand syntax, os dependent
    p = os.platform()
    diskfree = switch p
      when 'linux', 'darwin'
        "/bin/df -kT #{@config.share} | tail -n 1"
      when p.match /^win/
        # For windows maybe [drivespace](https://github.com/keverw/drivespace)
        # works, but this is not tested.
        "../bin/drivespace.exe drive-#{@config.share}"
      else
        throw new Error "Operating system #{p} is not supported in diskfree."

    # run the diskfree test
    @_start "Diskfree #{@config.share}"
    @result.data = ''
    debug "exec> #{diskfree}"
    proc = exec diskfree,
      timeout: @config.timeout
    , (err, stdout, stderr) =>
      stdout = stdout.trim()
      stderr = stderr.trim()
      # analyze success
      if stdout
        debug stdout.grey
      if stderr
        debug stderr.magenta
      @result.data = ''
      @result.data += "STDOUT:\n#{stdout}\n" if stdout
      @result.data += "STDERR:\n#{stderr}\n" if stderr
      @result.data += "RETURN CODE: #{err.signal}" if err?
      if err?
        debug err.toString().red
        @_end 'fail', err
        return cb err
      # get the values
      @result.value = value = {}
      if p.match /^win/
        [value.total, value.free, status]
        col = stdout.split ','
        value.total = Number(col[0])*1024
        value.free = Number(col[1])*1024
        value.used = value.total - value.free
        value.mount = @config.share
      else
        col = stdout.split /\s+/
        value.share = col[0]
        value.type = col[1]
        value.used = Number(col[3])*1024
        value.free = Number(col[4])*1024
        value.total = value.used + value.free
        value.mount = col[6]
      debug value
      # evaluate to check status
      switch
        when value.used + value.avail is 0
          status = 'fail'
          message = "#{@constructor.meta.name} no space available on share #{@config.share}"
        when value.free < @config.freeFail
          status = 'fail'
          message = "#{@constructor.meta.name} too less space on #{@config.share}"
        when value.free < @config.freeWarn
          status = 'warn'
        else
          status = 'ok'
      debug @config
      @_end status, message
      cb null, @

# Export class
# -------------------------------------------------
module.exports = DiskfreeSensor

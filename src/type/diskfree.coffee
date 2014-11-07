# Check disk space
# =================================================

# Find the description of the possible configuration values and the returned
# values in the code below.
# But the analysis part currently only works on linux.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:diskfree')
# include alinex packages
{object,number,string} = require 'alinex-util'
# include classes and helper
Sensor = require '../base'
# specific modules for this check
os = require 'os'
{exec} = require 'child_process'
async = require 'async'
math = require 'mathjs'

# Sensor class
# -------------------------------------------------
class DiskfreeSensor extends Sensor

  # ### General information
  #
  # This information may be used later for display and explanation.
  @meta =
    name: 'Diskfree'
    description: "Test the free diskspace of one share."
    category: 'sys'
    level: 1
    hint: "If a share is full it will make I/O problems in the system or applications
    in case of the root partition it may also neither be possible to log errors.
    Maybe some old files like temp or logs can be removed or compressed. "

    # ### Configuration
    #
    # Definition of all possible configuration settings (defaults included).
    # It's a n[alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible schema definition:
    config:
      title: "Disk free Test"
      type: 'object'
      allowedKeys: true
      entries:
        share:
          title: "Share or Mount"
          description: "the disk share's path or mount point to check"
          type: 'string'
        timeout:
          title: "Measurement Time"
          description: "the time in milliseconds the whole test may take before
            stopping and failing it"
          type: 'interval'
          unit: 'ms'
          min: 500
          default: 1000
        analysis:
          title: "Analysis Paths"
          description: "list of directories to monitor their volume on warning"
          type: 'array'
          optional: true
          delimiter: /,\s+/
          entries:
            title: "Directory"
            type: 'string'
        verbose: @check.verbose
        warn: @check.warn
        fail: object.extend { default: 'free is 0' }, @check.fail

    # ### Result values
    #
    # This are possible values which may be given if the check runs normally.
    # You may use any of these in your warn/fail expressions.
    values:
      share:
        title: 'Share'
        description: "path name of the share"
        type: 'string'
      type:
        title: 'Type'
        description: "type of filesystem"
        type: 'string'
      total:
        title: 'Available'
        description: "the space, which is available"
        type: 'byte'
        unit: 'B'
      used:
        title: 'Used'
        description: "the space, which is already used"
        type: 'byte'
        unit: 'B'
      usedPercent:
        title: '% Used'
        description: "the space, which is already used"
        type: 'percent'
      free:
        title: 'Free'
        description: "the space, which is free"
        type: 'byte'
        unit: 'B'
      freePercent:
        title: '% Free'
        description: "the space, which is free"
        type: 'percent'
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
        throw new Error "Operating system #{p} is not supported in diskfree sensor."
    # run the diskfree test
    @_spawn diskfree.cmd, diskfree.args,
      timeout: @config.timeout
    , (err, stdout, stderr, code) =>
      return @_end 'fail', err, cb if err
      # parse results
      lines = stdout.split /\n/
      val = @result.values
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
      val.usedPercent = val.used / val.total
      val.freePercent = val.free / val.total
      # evaluate to check status
      status = @rules()
      message = @config[status] + " on share #{@config.share}" unless status is 'ok'
      # check if analysis have to be done
      if (status is 'ok' and not @config.verbose) or not @config.analysis?.length
        return @_end status, message, cb
      # analysis currently only works on linux
      if os.platform().match /^win/
        return @_end status, message, cb
      # get additional information
      @result.analysis = """
        Maybe some files in one of the following directories may be deleted or moved:

        | PATH                                |  FILES  |    SIZE    |   OLDEST   |
        | ----------------------------------- | ------: | ---------: | :--------- |\n"""
      async.mapLimit @config.analysis, os.cpus().length, (dir, cb) =>
        cmd = "find #{dir} -type f -exec ls -ltr --time-style=+%Y-%m-%d '{}' \\; 2>/dev/null
        | awk '{n++;b+=$5;if(d==\"\"){d=$6};if(d>$6){d=$6}} END{print n,b,d}'"
        exec cmd,
          timeout: @config.analysisTimeout
        , (err, stdout, stderr) ->
          unless stdout
            return cb null, "| #{string.rpad dir, 35} |       ? |          ? | ?          |\n"
          col = stdout.toString().split /\s+/
          byte = math.unit parseInt(col[1]), 'B'
          cb null, "| #{string.rpad dir, 35} | #{string.lpad col[0], 7}
          | #{string.lpad byte.format(3), 10}
          | #{string.lpad col[2], 10} |\n"
      , (err, lines) =>
        @result.analysis += line for line in lines
        debug @result.analysis
        @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = DiskfreeSensor

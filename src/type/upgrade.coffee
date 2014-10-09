# Check package upgrades
# =================================================
# This will only work on debian based linux.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:upgrade')
# include alinex packages
{object,number,string} = require 'alinex-util'
# include classes and helper
Sensor = require '../base'
# specific modules for this check
os = require 'os'
{exec} = require 'child_process'
async = require 'async'

# Sensor class
# -------------------------------------------------
class UpgradeSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Upgrade'
    description: "Check for possible package upgrades."
    category: 'sys'
    level: 1
    hint: "Maybe there are some updates to the installed packages. This may
    also be a security update. "
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Package Upgrade"
      description: "the configuration to check for possible package upgrades"
      type: 'object'
      allowedKeys: true
      entries:
        timeLowWarn:
          title: "Low Warn"
          description: "the time after which a warning is set for low priority upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
        timeLowFail:
          title: "Low Fail"
          description: "the time after which a failure is set for low priority upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
        timeMediumWarn:
          title: "Medium Warn"
          description: "the time after which a warning is set for medium priority upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
        timeMediumFail:
          title: "Medium Fail"
          description: "the time after which a failure is set for medium priority upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
        timeHighWarn:
          title: "High Warn"
          description: "the time after which a warning is set for high priority upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
        timeHighFail:
          title: "High Fail"
          description: "the time after which a failure is set for high priority upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
        timeSecurityWarn:
          title: "Security Warn"
          description: "the time after which a warning is set for any security upgrade "
          type: 'interval'
          unit: 'd'
          optional: true
        timeSecurityFail:
          title: "Security Fail"
          description: "the time after which a failure is set for any security upgrade "
          type: 'interval'
          unit: 'd'
          optional: true

    # Definition of response values
    values:
      numSecurity:
        title: "Security"
        description: "the number of security updates "
        type: 'integer'
      numLow:
        title: "Low Priority"
        description: "the number of low priority updates "
        type: 'integer'
      numMedium:
        title: "Medium Priority"
        description: "the number of medium priority updates "
        type: 'integer'
      numHigh:
        title: "High Priority"
        description: "the number of high priority updates "
        type: 'integer'
      numTotal:
        title: "Total"
        description: "the number of total updates "
        type: 'integer'
      oldestSecurity:
      oldestLow:
      oldestMedium:
      oldestHigh:
      oldestTotal:

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
      if not @config.analysis?.length
        return @_end status, message, cb
      # get additional information
      @result.analysis = """
        Maybe some files in one of the following directories may be deleted or moved:

        | PATH                                |  FILES  |    SIZE    |   OLDEST   |
        | ----------------------------------- | ------: | ---------: | :--------- |\n"""
      async.map @config.analysis, (dir, cb) =>
        cmd = "find /tmp -type f 2>/dev/null | xargs ls -ltr --time-style=+%Y-%m-%d
        | awk '{n++;b+=$5;if(d==\"\"){d=$6};if(d>$6){d=$6}} END{print n,b,d}'"
        exec cmd,
          timeout: 30000
        , (err, stdout, stderr) ->
          unless stdout
            return cb null, "| #{string.rpad dir, 40} |     ? |          ? | ?          |\n"
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
module.exports = UpgradeSensor

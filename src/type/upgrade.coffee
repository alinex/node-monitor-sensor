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
{exec} = require 'child_process'
os = require 'os'
async = require 'async'
moment = require 'moment'
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
    hint: "If there are some packages to be upgraded, please call `sudo aptitude upgrade`
    on the command line. This will interactively install all the neccessary
    package upgrades."
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Package Upgrade"
      description: "the configuration to check for possible package upgrades"
      type: 'object'
      allowedKeys: true
      entries:
        timeWarn:
          title: "Warn"
          description: "the time after which a warning is set for upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
        timeFail:
          title: "Fail"
          description: "the time after which a failure is set for upgrades "
          type: 'interval'
          unit: 'd'
          optional: true
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
        title: "Num. Security"
        description: "the number of security updates "
        type: 'integer'
      numLow:
        title: "Num. Low Prio"
        description: "the number of low priority updates "
        type: 'integer'
      numMedium:
        title: "Num. Medium Prio"
        description: "the number of medium priority updates "
        type: 'integer'
      numHigh:
        title: "Num. High Prio"
        description: "the number of high priority updates "
        type: 'integer'
      numTotal:
        title: "Num. Total"
        description: "the number of total updates "
        type: 'integer'
      timeSecurity:
        title: "Time Security"
        description: "the max. age of security update "
        type: 'interval'
        unit: 'd'
      timeLow:
        title: "Time Low Prio"
        description: "the max. age of low priority update "
        type: 'interval'
        unit: 'd'
      timeMedium:
        title: "Time Medium Prio"
        description: "the max. age of medium priority update "
        type: 'interval'
        unit: 'd'
      timeHigh:
        title: "Time High Prio"
        description: "the max. age of high priority update "
        type: 'interval'
        unit: 'd'
      timeTotal:
        title: "Time"
        description: "the max. age of update "
        type: 'interval'
        unit: 'd'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    # comand syntax, os dependent
    cmd = "apt-get update; apt-get -s upgrade | grep Inst
    | awk -F '\\]? [\\[(]?' '{print $2,$3,$4}'"
    exec cmd, (err, stdout, stderr) =>
      return @_end 'fail', err, cb if err
      async.mapLimit stdout.toString().split(/\n/), os.cpus().length, (line, cb) ->
        return cb() unless line
        [pack, old, current] = line.split /\s/
        cmd = "aptitude changelog #{pack} 2>/dev/null| sed '1d;/(#{old})/,$d'"
        exec cmd, (err, stdout, stderr) ->
          return cb err if err
          info = []
          urgency = null
          security = false
          date = null
          for line in stdout.toString().split /\n/
            continue unless line # empty line
            if line.match /^\w/ # upgrade
              col = line.split /;?\s+/
              security = ~col[2].toLowerCase().indexOf 'security'
              prio = col[3].substring 8
              urgency = prio if not urgency? or urgency is 'low' or prio is 'high'
            else if line.match /^ --/ # author
              col = line.split />\s/
              release = new Date col[1]
              date = release if not date? or release < date
            else if line.match /^\s\s\[/ # name only
              continue
            else # info
              info.push line
          cb null,
            pack: pack
            old: old
            current: current
            security: security
            urgency: urgency
            time: moment().diff(date, 'days')
            change: moment(date).fromNow()
            release: date
            info: info
      , (err, results) =>
        val = @result.value =
          numSecurity: 0
          numLow: 0
          numMedium: 0
          numHigh: 0
          numTotal: 0
          timeSecurity: null
          timeLow: null
          timeMedium: null
          timeHigh: null
          timeTotal: null
        sort = {}
        for entry in results
          continue unless entry
          sort["#{entry.security}#{{low:1,medium:2,high:3}[entry.urgency]}-#{entry.time}"] = entry
          val.numTotal++
          val.timeTotal = entry.time if not val.timeTotal or entry.time > val.timeTotal
          if entry.security
            val.numSecurity++
            val.timeSecurity = entry.time if not val.timeSecurity or entry.time > val.timeSecurity
          if entry.urgency is 'low'
            val.numLow++
            val.timeLow = entry.time if not val.timeLow or entry.time > val.timeLow
          else if entry.urgency is 'medium'
            val.numMedium++
            val.timeMedium = entry.time if not val.timeMedium or entry.time > val.timeMedium
          else if entry.urgency is 'high'
            val.numHigh++
            val.timeHigh = entry.time if not val.timeHigh or entry.time > val.timeHigh
        # evaluate to check status
        switch
          when val.timeTotal? and @config.timeFail? \
          and val.timeTotal >= @config.timeFail
            status = 'fail'
            message = "#{@constructor.meta.name} has updates waiting longer than
            #{@config.timeFail} days"
          when val.timeLow? and @config.timeLowFail? \
          and val.timeLow >= @config.timeLowFail
            status = 'fail'
            message = "#{@constructor.meta.name} has low priority updates waiting
            longer than #{@config.timeLowFail} days"
          when val.timeMedium? and @config.timeMediumFail? \
          and val.timeMedium >= @config.timeMediumFail
            status = 'fail'
            message = "#{@constructor.meta.name} has medium priority updates waiting
            longer than #{@config.timeMediumFail} days"
          when val.timeHigh? and @config.timeHighFail? \
          and val.timeHigh >= @config.timeHighFail
            status = 'fail'
            message = "#{@constructor.meta.name} has high priority updates waiting
            longer than #{@config.timeHighFail} days"
          when val.timeSecurity? and @config.timeSecurityFail? \
          and val.timeSecurity >= @config.timeSecurityFail
            status = 'fail'
            message = "#{@constructor.meta.name} has security updates waiting longer
            than #{@config.timeSecurityFail} days"
          when val.timeTotal? and @config.timeWarn? \
          and val.timeTotal >= @config.timeWarn
            status = 'warn'
          when val.timeLow? and @config.timeLowWarn? \
          and val.timeLow >= @config.timeLowWarn
            status = 'warn'
          when val.timeMedium? and @config.timeMediumWarn? \
          and val.timeMedium >= @config.timeMediumWarn
            status = 'warn'
          when val.timeHigh? and @config.timeHighWarn? \
          and val.timeHigh >= @config.timeHighWarn
            status = 'warn'
          when val.timeSecurity? and @config.timeSecurityWarn? \
          and val.timeSecurity >= @config.timeSecurityWarn
            status = 'warn'
          else
            status = 'ok'
        # done if no problem found
        if status is 'ok'
          return @_end status, message, cb
        # get additional information
        @result.analysis = "The following packages may be updated:"
        for name in Object.keys(sort).sort().reverse()
          entry = sort[name]
          security = if entry.security then 'security ' else ''
          @result.analysis += "\n\n#{entry.pack} #{entry.old} -> #{entry.current}
          #{security}#{entry.urgency} priority #{entry.change}"
          @result.analysis += "\n" + entry.info.join '\n' if entry.info
        debug @result.analysis
        @result.analysis += '\n'
        @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = UpgradeSensor

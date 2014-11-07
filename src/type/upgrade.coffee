# Check package upgrades
# =================================================
# This will at the moment only work on denian and debian based linux like Mint,
# Ubuntu.

# Find the description of the possible configuration values and the returned
# values in the code below.

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
  #
  # This information may be used later for display and explanation.
  @meta =
    name: 'Upgrade'
    description: "Check for possible package upgrades."
    category: 'sys'
    level: 1
    hint: "If there are some packages to be upgraded, please call `sudo aptitude upgrade`
    on the command line. This will interactively install all the neccessary
    package upgrades."

    # ### Configuration
    #
    # Definition of all possible configuration settings (defaults included).
    # It's a n[alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible schema definition:
    config:
      title: "Package Upgrade"
      description: "the configuration to check for possible package upgrades"
      type: 'object'
      allowedKeys: true
      entries:
        verbose: @check.verbose
        warn: @check.warn
        fail: @check.fail

    # ### Result values
    #
    # This are possible values which may be given if the check runs normally.
    # You may use any of these in your warn/fail expressions.
    values:
      platform:
        title: "Platform"
        description: "the platform you're running on: 'darwin', 'freebsd', 'linux',
        'sunos' or 'win32'"
        type: 'string'
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
      num:
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
      time:
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
        val = @result.values =
          platform: process.platform
          numSecurity: 0
          numLow: 0
          numMedium: 0
          numHigh: 0
          num: 0
          timeSecurity: null
          timeLow: null
          timeMedium: null
          timeHigh: null
          time: null
        sort = {}
        for entry in results
          continue unless entry
          sort["#{entry.security}#{{low:1,medium:2,high:3}[entry.urgency]}-#{entry.time}"] = entry
          val.num++
          val.time = entry.time if not val.time or entry.time > val.time
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
        status = @rules()
        message = @config[status] unless status is 'ok'
        # done if no problem found
        if status is 'ok' and not @config.verbose
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

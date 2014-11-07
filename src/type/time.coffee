# Check the time
# =================================================
# This will compare the local time with the time of a time server in the internet.

# Find the description of the possible configuration values and the returned
# values in the code below.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:time')
# include alinex packages
object = require('alinex-util').object
# include classes and helper
Sensor = require '../base'
# specific modules for this check
ntp = require 'ntp-client'

# Sensor class
# -------------------------------------------------
class TimeSensor extends Sensor

  # ### General information
  #
  # This information may be used later for display and explanation.
  @meta =
    name: 'Time Check'
    description: "Check the system time against the Internet."
    category: 'sys'
    level: 1
    hint: "If the time is not correct it may influence some processes which goes
    over multiple hosts. Therefore install and configure `ntpd` on the machine."

    # ### Configuration
    #
    # Definition of all possible configuration settings (defaults included).
    # It's a n[alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible schema definition:
    config:
      title: "Time Check"
      type: 'object'
      allowedKeys: true
      entries:
        host:
          title: "NTP Hostname"
          description: "the name of an NTP server to call"
          type: 'string'
          default: 'pool.ntp.org'
        port:
          title: "NTP Port"
          description: "the port to use for NTP calls"
          type: 'integer'
          default: 123
        timeout:
          title: "Timeout"
          description: "the time in milliseconds tto retrieve time"
          type: 'interval'
          unit: 'ms'
          default: 10000
          min: 500
        warn: @check.warn
        fail: @check.fail

    # ### Result values
    #
    # This are possible values which may be given if the check runs normally.
    # You may use any of these in your warn/fail expressions.
    values:
      local:
        title: 'Local Time'
        description: "the time on the local host"
        type: 'date'
      remote:
        title: 'Remote Time'
        description: "the time on an internet time server"
        type: 'date'
      diff:
        title: 'Difference'
        description: "the difference between both times"
        type: 'interval'
        unit: 'ms'


  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    ntp.ntpReplyTimeout = @config.timeout
    ntp.getNetworkTime @config.host, @config.port, (err, remote) =>
      return @_end 'fail', err, cb if err
      local = new Date
      val = @result.values
      val.remote = remote
      val.local = local
      val.diff = Math.abs local-remote
      # evaluate to check status
      status = @rules()
      message = @config[status] unless status is 'ok'
      return @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = TimeSensor

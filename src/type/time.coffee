# Check disk space
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:time')
# include alinex packages
# include classes and helper
Sensor = require '../base'
# specific modules for this check
ntp = require 'ntp-client'

# Sensor class
# -------------------------------------------------
class TimeSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Time Check'
    description: "Check the system time against the internet."
    category: 'sys'
    level: 1
    hint: "If the time is not correct it may influence some processes which gives
    over mutliple hosts. Therefore install and configure `ntpd` on the machine."
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Time Check"
      type: 'object'
      allowedKeys: true
      entries:
        ntphost:
          title: "NTP Hostname"
          description: "the name of an NTP server to call"
          type: 'string'
          default: 'pool.ntp.org'
        ntpport:
          title: "NTP Port"
          description: "the port to use for NTP calls"
          type: 'integer'
          default: 123
        warn:
          title: "Warn"
          description: "the maximum interval which is allowed"
          optional: true
          type: 'interval'
          unit: 's'
          min:
            reference: 'relative'
            source: '<fail'
        fail:
          title: "Fail"
          description: "the maximum interval which is allowed"
          type: 'interval'
          unit: 's'
          optional: true

    # Definition of response values
    values:
      success:
        title: 'Success'
        description: "both times could be retrieved"
        type: 'boolean'
      local:
        title: 'Local Time'
        description: "the time on the local host"
        type: 'date'
      remote:
        title: 'Remote Time'
        description: "the time on an internet time server"
        type: 'date'
      diff:
        title: 'Differenz'
        description: "the difference between both times"
        type: 'interval'
        unit: 'ms'


  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    ntp.getNetworkTime @config.ntphost, @config.ntpport, (err, remote) =>
      return @_end 'fail', err, cb if err
      local = new Date
      val = @result.value
      val.success = true
      val.remote = remote
      val.local = local
      val.diff = Math.abs local-remote
      # evaluate to check status
      switch
        when @config.fail? and val.diff > @config.fail
          status = 'fail'
          message = "#{@constructor.meta.name} time not synchronized"
        when @config.warn? and val.diff > @config.warn
          status = 'warn'
        else
          status = 'ok'
      return @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = TimeSensor

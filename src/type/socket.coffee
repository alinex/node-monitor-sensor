# Socket test class
# =================================================
# This may be used to check the connection to different ports.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:socket')
chalk = require 'chalk'
# include alinex packages
object = require('alinex-util').object
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
net = require 'net'

# Sensor class
# -------------------------------------------------
class SocketSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Socket'
    description: "Use TCP sockets to check for the availability of a service
    behind a given port."
    category: 'net'
    level: 1
    hint: "On problems the service may not run or a network problem exists. "
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Socket connection test"
      type: 'object'
      allowedKeys: true
      entries:
        host:
          title: "Hostname or IP"
          description: "the server hostname or ip address to establish connection to"
          type: 'string'
          default: 'localhost'
        port:
          title: "Port"
          description: "the port number used to connect to"
          type: 'integer'
          min: 1
        timeout:
          title: "Timeout"
          description: "the timeout in milliseconds till the process is stopped
            and be considered as failed"
          type: 'interval'
          unit: 'ms'
          min: 500
          default: 2000
        warn: @check.warn
        fail: @check.fail
    # Definition of response values
    values:
      responsetime:
        title: "Response Time"
        description: "time in milliseconds till connection could be established"
        type: 'integer'
        unit: 'ms'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()

    socket = new net.Socket()
    debug "connect to #{@config.host}:#{@config.port}"
    start = new Date().getTime()
    socket.setTimeout @config.timeout
    socket.connect @config.port, @config.host, =>
      debug "connection established"
      end = new Date().getTime()
      socket.destroy()

      # get the values
      val = @result.values
      val.responsetime = end-start

      # evaluate to check status
      status = @rules()
      message = @config[status] unless status is 'ok'
      @_end status, message, cb

    # Timeout occurred
    socket.on 'timeout', =>
      message = "server not responding, timeout occurred"
      debug chalk.red message
      @_end 'fail', message, cb

    # Error management
    socket.on 'error', (err) =>
      debug chalk.red err.toString()
      @_end 'fail', err, cb

# Export class
# -------------------------------------------------
module.exports = SocketSensor

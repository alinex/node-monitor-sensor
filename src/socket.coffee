# Socket test class
# =================================================
# This may be used to check the connection to different ports.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:socket')
colors = require 'colors'
# include alinex packages
object = require('alinex-util').object
# include classes and helper modules
Sensor = require './base'
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
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Socket connection test"
      type: 'object'
      mandatoryKeys: ['host', 'port']
      allowedKeys: ['timeout', 'responsetime']
      entries:
        host:
          title: "Hostname or IP"
          description: "the server hostname or ip address to establish connection to"
          type: 'string'
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
        reponsetime:
          title: "Response Time"
          description: "the maximum time in milliseconds till the connection
            can be established without setting the state to warning"
          type: 'interval'
          unit: 'ms'
          min: 0
    # Definition of response values
    values:
      success:
        title: "Successful"
        description: "true if connecting is possible"
        type: 'boolean'
      responsetime:
        title: "Response Time"
        description: "time in milliseconds till connection could be established"
        type: 'integer'
        unit: 'ms'

  # ### Default Configuration
  # The values starting with underscore are general help messages.
  @config =
    timeout: 2000
    responsetime: 1000

  # ### Create instance
  constructor: (config) ->
    super object.extend {}, @constructor.config, config
    unless config
      throw new Error "Could not initialize sensor without configuration."

  # ### Run the check
  run: (cb = ->) ->

    # run the ping test
    @_start "Connect #{@config.host}:#{@config.port}"
    @result.data = ''

    socket = new net.Socket()
    debug "connect to #{@config.host}:#{@config.port}"
    start = new Date().getTime()
    socket.setTimeout @config.timeout
    socket.connect @config.port, @config.host, =>
      debug "connection established"
      end = new Date().getTime()
      socket.destroy()

      # get the values
      @result.value = value = {}
      value.success = true
      value.responsetime = end-start
      debug value

      # evaluate to check status
      status = switch
        when not value.success
          'fail'
        when  @config.responsetime? and value.responsetime > @config.responsetime
          'warn'
        else
          'ok'
      message = switch status
        when 'fail'
          "#{@constructor.meta.name} exited with status #{status}"
      @_end status, message
      cb null, @

    # Timeout occurred
    socket.on 'timeout', =>
      message = "server not responding, timeout occurred"
      debug message.red
      @_end 'fail', message
      cb null, @

    # Error management
    socket.on 'error', (err) =>
      debug err.toString().red
      @_end 'fail', err
      cb null, @

# Export class
# -------------------------------------------------
module.exports = SocketSensor

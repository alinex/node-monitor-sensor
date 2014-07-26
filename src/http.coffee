# Socket test class
# =================================================
# This may be used to check the response of a web server.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:http')
colors = require 'colors'
EventEmitter = require('events').EventEmitter
object = require('alinex-util').object
Sensor = require './base'
# specific modules for this check
request = require 'request'

# Sensor class
# -------------------------------------------------
class SocketSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'HTTP Request'
    description: "Connect to an HTTP or HTTPS server and check the response."
    category: 'net'
    level: 2

  # ### Value Definition
  # This will define the values measured and their specifics, used to display
  # results.
  @values = [
    name: 'success'
    description: "true if server responded with correct http code"
    type: 'bool'
  ,
    name: 'responsetime'
    description: "time till connection could be established"
    type: 'int'
    unit: 'ms'
  ,
    name: 'statuscode'
    description: "http status code"
    type: 'values'
  ,
    name: 'bodycheck'
    description: "success of check for content"
    type: 'bool'
  ]

  # ### Default Configuration
  # The values starting with underscore are general help messages.
  @config =
    _url: "URL to request"
    timeout: 2
    _timeout: "timeout in seconds"
    responsetime: 1000
    _responsetime: "maximum time in ms till server responded"
    _username: "used for basic authentication"
    _password: "used for basic authentication"
    _bodycheck: "substring or regular expression"
  # ### Create instance
  constructor: (config) ->
    super object.extend {}, @constructor.config, config
    unless config
      throw new Error "Could not initialize sensor without configuration."

  # ### Run the check
  run: (cb = ->) ->

    @_start "HTTP Request to #{@config.url}"
    @result.data = ''

    # configure request
    option =
      url: @config.url
    option.timeout = @config.timeout*1000 if @config.timeout?
    if @config.username? and @config.password?
      option.auth =
        username: @config.username
        password: @config.password

    # start the request
    debug "request #{@config.url}"
    start = new Date().getTime()
    request option, (err, response, body) =>
      # request finished
      end = new Date().getTime()

      # collecting data
      if response?
        data += "HEADERS:\n"
        for key, value of response.headers
          data += "#{key}: #{value}\n"
          debug "#{key}: #{value}".grey
      data += "BODY:\n#{body}\n"

      # error checking
      if err
        debug err.toString().red
        @_end 'fail', err
        return cb err

      # get the values
      @result.value = value = {}
      value.success = 200 <= response.statusCode < 300
      value.responsetime = end-start
      value.statuscode = response.statusCode
      if @config.bodycheck?
        if @config.bodycheck instanceof RegExp
          value.bodycheck = (body.match @config.bodycheck)?
        else
          value.bodycheck = (~body.indexOf @config.bodycheck)?
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
          "#{@constructor.meta.name} exited with status code #{response.statusCode}"
      @_end status, message
      return cb new Error message if status is 'fail'
      cb()

# Export class
# -------------------------------------------------
module.exports = SocketSensor

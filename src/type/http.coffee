# Socket test class
# =================================================
# This may be used to check the response of a web server.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:http')
chalk = require 'chalk'
# include alinex modules
object = require('alinex-util').object
# include classes and helper
Sensor = require '../base'
# specific modules for this check
request = require 'request'

# Sensor class
# -------------------------------------------------
class HttpSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'HTTP Request'
    description: "Connect to an HTTP or HTTPS server and check the response."
    category: 'net'
    level: 2
    hint: "If the server didn't respond it also may be a network problem. "
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Webserver response check"
      type: 'object'
      allowedKeys: true
      entries:
        url:
          title: "URL"
          description: "the URL to request"
          type: 'string'
        timeout:
          title: "Timeout"
          description: "the timeout in milliseconds till the process is stopped
            and be considered as failed"
          type: 'interval'
          unit: 'ms'
          min: 500
          default: 2000
        responsetime:
          title: "Response Time"
          description: "the maximum time in milliseconds till the server
            responded after that the state is set to warning"
          type: 'interval'
          unit: 'ms'
          min: 0
          default: 1000
        username:
          title: "Username"
          description: "the name used for basic authentication"
          type: 'string'
          optional: true
        password:
          title: "Password"
          description: "the password used for basic authentication"
          type: 'string'
          optional: true
        bodycheck:
          title: "Body Check"
          description: "substring or regular expression"
          type: 'any'
          optional: true
          entries: [
            type: 'string'
            minLength: 1
          ,
            type: 'object'
            instanceOf: RegExp
          ]
    # Definition of response values
    values:
      success:
        title: "Success"
        description: "true if server responded with correct http code"
        type: 'boolean'
      responsetime:
        title: "Response Time"
        description: "time till connection could be established"
        type: 'integer'
        unit: 'ms'
      statuscode:
        title: "Status Code"
        description: "http status code"
        type: 'values'
      bodytype:
        title: "Body Check OK"
        description: "success of check for content"
        type: 'boolean'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
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
        @result.data += "HEADERS:\n"
        for key, value of response.headers
          debug chalk.grey "#{key}: #{value}"
      # error checking
      if err
        debug chalk.red err.toString()
        return @_end 'fail', err, cb
      # get the values
      val = @result.value
      val.success = 200 <= response.statusCode < 300
      val.responsetime = end-start
      val.statuscode = response.statusCode
      if @config.bodycheck?
        if @config.bodycheck instanceof RegExp
          val.bodycheck = (body.match @config.bodycheck)?
        else
          val.bodycheck = (~body.indexOf @config.bodycheck)?
      # evaluate to check status
      status = switch
        when not val.success
          'fail'
        when  @config.responsetime? and val.responsetime > @config.responsetime
          'warn'
        else
          'ok'
      message = switch status
        when 'fail'
          "#{@constructor.meta.name} exited with status code #{response.statusCode}"
      @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = HttpSensor

# HTTP access check
# =================================================
# This may be used to check the response of a web server using HTTP or HTTPS.

# Find the description of the possible configuration values and the returned
# values in the code below.

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
  #
  # This information may be used later for display and explanation.
  @meta =
    name: 'HTTP Request'
    description: "Connect to an HTTP or HTTPS server and check the response."
    category: 'net'
    level: 2
    hint: "If the server didn't respond it also may be a network problem. "

    # ### Configuration
    #
    # Definition of all possible configuration settings (defaults included).
    # It's a n[alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible schema definition:
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
          default: 10000
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
        match:
          title: "Match body"
          description: "the substring or regular expression which have to match"
          type: 'any'
          optional: true
          entries: [
            type: 'string'
            minLength: 1
          ,
            type: 'object'
            instanceOf: RegExp
          ]
        analysis:
          title: "Analysis Length"
          description: "the maximum body display length in analyzation report"
          type: 'integer'
          min: 1
          default: 256
        verbose: @check.verbose
        warn: @check.warn
        fail: object.extend { default: 'statuscode < 200 or statuscode >= 400' }, @check.fail

    # ### Result values
    #
    # This are possible values which may be given if the check runs normally.
    # You may use any of these in your warn/fail expressions.
    values:
      responsetime:
        title: "Response Time"
        description: "time till connection could be established"
        type: 'interval'
        unit: 'ms'
      statuscode:
        title: "Status Code"
        description: "http status code"
        type: 'integer'
      statusmessage:
        title: "Status Message"
        description: "http status message from server"
        type: 'string'
      server:
        title: "Server"
        description: "application name of the server (if given)"
        type: 'string'
      contenttype:
        title: "Content Type"
        description: "the content mimetype"
      length:
        title: "Content Length"
        description: "size of the content"
        type: 'byte'
      match:
        title: "Body Match"
        description: "success of check for content with containing results"
        type: 'object'

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
      # error checking
      if err
        debug chalk.red err.toString()
        return @_end 'fail', err, cb
      # get the values
      val = @result.values
      val.responsetime = end-start
      val.statuscode = response.statusCode
      val.statusmessage = response.statusMessage
      val.server = response.headers.server
      val.contenttype = response.headers['content-type']
      val.length = response.connection.bytesRead
      val.match = @match body, @config.match
      # evaluate to check status
      status = @rules()
      message = @config[status] unless status is 'ok'
      # done if no problem found
      if status is 'ok' and not @config.verbose
        return @_end status, message, cb
      # get additional information (top processes)
      @result.analysis = """
      See the following details of the check.

      __GET #{@config.url}__\n
      """
      if response?
        @result.analysis += "\nResponse:\n\n"
        for key, value of response.headers
          @result.analysis += "    #{key}: #{value}\n"
      if body?
        body = body[0..@config.analysis] + '...' if body.length > @config.analysis
        body = body.replace /\n/g, '\n    '
        @result.analysis += "\nContent:\n\n"
        @result.analysis += "    #{body}\n"
      debug @result.analysis
      @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = HttpSensor

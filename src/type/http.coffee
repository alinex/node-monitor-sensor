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
named = require('named-regexp').named

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
        verbose: @check.verbose
        warn: @check.warn
        fail: object.extend {}, @check.fail, { default: 'statuscode isnt 200' }
    # Definition of response values
    values:
      success:
        title: "Success"
        description: "true if server responded with correct http code"
        type: 'boolean'
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
      matched:
        title: "Body Match"
        description: "success of check for content"
        type: 'boolean'
      matches:
        title: "Named"
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
        for key, value of response.headers
          debug chalk.grey "#{key}: #{value}"
      # error checking
      if err
        debug chalk.red err.toString()
        return @_end 'fail', err, cb
      # get the values
      val = @result.values
      val.success = 200 <= response.statusCode < 300
      val.responsetime = end-start
      val.statuscode = response.statusCode
      val.statusmessage = response.statusMessage
      val.server = response.headers.server
      val.contenttype = response.headers['content-type']
      val.length = response.connection.bytesRead
      if @config.match?
        if @config.match instanceof RegExp
          if ~@config.match.indexOf '(:<'
            re = named @config.match
            if matched = re.exec body
              val.matches = {}
              for name of matched.captures()
                val.matches = matched.captures(name)
          else
            val.matches = re.exec body
        else
          val.matched = (~body.indexOf @config.match)?
      # evaluate to check status
      status = @rules()
      message = @config[status] unless status is 'ok'
      @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = HttpSensor

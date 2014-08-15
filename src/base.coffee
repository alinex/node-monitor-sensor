# Ping test class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
object = require('alinex-util').object
colors = require 'colors'

# Sensor class
# -------------------------------------------------
# This class contains all the basics for each sensor.
class Sensor

  # ### Default Configuration
  # This may be overwritten in sensor config or constructor parameter.
  @config =
    verbose: false

  # ### Create instance
  constructor: (config) ->
    @config = object.extend {}, @constructor.config, config
    unless config
      throw new Error "Could not initialize sensor without configuration."

  # ### Protocol new start
  _start: (title) ->
    @result =
      date: new Date
      status: 'running'
    if @config.verbose
      console.log "#{title}..."

  # ### Protocol end of sensor run
  _end: (status, message) ->
    @result.status = status
    @result.message = message if message
    if @config.verbose and status isnt 'ok'
      if status is 'fail' and message
        console.log "#{@constructor.meta.name} #{status}: #{message}".red
      else if status is 'fail'
        console.log "#{@constructor.meta.name} #{status}!".red
      else
        console.log "#{@constructor.meta.name} #{status}!".magenta
      console.log @result.value

# Export class
# -------------------------------------------------
module.exports = Sensor

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

  # ### Create instance
  constructor: (@config) ->
    unless @config
      throw new Error "Could not initialize sensor without configuration."

  # ### Protocol new start
  _start: (title) ->
    @result =
      date: new Date
      status: 'running'

  # ### Protocol end of sensor run
  _end: (status, message) ->
    @result.status = status
    @result.message = message if message


# Export class
# -------------------------------------------------
module.exports = Sensor

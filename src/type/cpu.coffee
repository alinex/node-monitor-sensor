# Cpu test class
# =================================================
# This may be used to check the overall memory use of a host.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:cpu')
# include alinex packages
object = require('alinex-util').object
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'
fs = require 'fs'

# Sensor class
# -------------------------------------------------
class CpuSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Cpu'
    description: "Check the current activity in average percent of all cores."
    category: 'sys'
    level: 1
    hint: "A high cpu usage means that the server may not start another task immediately.
    If the load is also very high the system is overloaded check if any application
    goes evil."
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "CPU check"
      type: 'object'
      allowedKeys: true
      entries:
        fail:
          title: "Max CPU activity to fail"
          description: "the maximum activity level for all cpus to fail"
          type: 'percent'
          optional: true
          min: 0
        warn:
          title: "Max CPU activity to warn"
          description: "the maximum activity level for all cpus to be ok"
          type: 'percent'
          optional: true
          min: 0
          max:
            reference: 'relative'
            source: '<fail'
    # Definition of response values
    values:
      success:
        title: 'Success'
        description: "true if external command runs successfully"
        type: 'boolean'
      cpu:
        tittle: "cpu"
        description: "cpu model name with brand"
        type: 'string'
      cpus:
        title: "cpu cores"
        description: "number of cpu cores"
        type: 'integer'
      speed:
        title: "cpu speed"
        description: "speed in MHz"
        type: 'integer'
      user:
        tittle: "User time"
        description: "percentage of user time over all cpu cores"
        type: 'percent'
      system:
        tittle: "System time"
        description: "percentage of system time over all cpu cores"
        type: 'percent'
      idle:
        tittle: "Idle time"
        description: "percentage of idle time over all cpu cores"
        type: 'percent'
      active:
        tittle: "Activity"
        description: "percentage of active time over all cpu cores"
        type: 'percent'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    # get data
    load = os.loadavg()
    cpus = os.cpus()
    # calculate values
    val = @result.value
    val.cpus = cpus.length
    val.cpu = cpus[0].model.replace /\s+/g, ' '
    val.speed = cpus[0].speed
    times =
      user: 0
      sys: 0
      idle: 0
    for cpu in cpus
      times[v] += cpu.times[v] for v in ['user', 'sys', 'idle']
    # calculate percentage
    total = times.user + times.sys + times.idle
    val.user = times.user / total
    val.system = times.sys / total
    val.idle = times.idle / total
    val.active = val.user + val.system
    # evaluate to check status
    status = switch
      when @config.fail? and val.active > @config.fail
        'fail'
      when @config.warn? and val.active > @config.warn
        'warn'
      else
        'ok'
    message = switch status
      when 'fail'
        "too high activity on cpu"
    @_end status, message, cb


# Export class
# -------------------------------------------------
module.exports = CpuSensor

# Cpu test class
# =================================================
# This may be used to check the overall memory use of a host.
# But the analysis part currently only works on linux.

# Find the description of the possible configuration values and the returned
# values in the code below.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:cpu')
# include alinex packages
{object,string} = require 'alinex-util'
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'
fs = require 'fs'
{exec} = require 'child_process'

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

    # ### Configuration
    #
    # Definition of all possible configuration settings (defaults included).
    # It's a n[alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible schema definition:
    config:
      title: "CPU check configuration"
      type: 'object'
      allowedKeys: true
      entries:
        analysis:
          title: "Top X"
          description: "the number of top cpu heavy processes for analysis"
          type: 'integer'
          min: 1
          default: 5
        verbose: @check.verbose
        warn: object.extend { default: 'active >= 100%' }, @check.warn
        fail: @check.fail

    # ### Result values
    #
    # This are possible values which may be given if the check runs normally.
    # You may use any of these in your warn/fail expressions.
    values:
      cpu:
        title: "CPU Model"
        description: "cpu model name with brand"
        type: 'string'
      cpus:
        title: "CPU Cores"
        description: "number of cpu cores"
        type: 'integer'
      speed:
        title: "CPU Speed"
        description: "speed in MHz"
        type: 'integer'
        unit: 'MHz'
      arch:
        title: "Architecture"
        description: "the processor architecture you're running on: 'arm', 'ia32', or 'x64'"
        type: 'string'
      user:
        title: "User Time"
        description: "percentage of user time over all cpu cores"
        type: 'percent'
      system:
        title: "System Time"
        description: "percentage of system time over all cpu cores"
        type: 'percent'
      idle:
        title: "Idle Time"
        description: "percentage of idle time over all cpu cores"
        type: 'percent'
      active:
        title: "Activity"
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
    # store the results
    val = @result.values
    val.arch = process.arch
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
    status = @rules()
    message = @config[status] unless status is 'ok'
    # done if no problem found
    if status is 'ok' and not @config.verbose
      return @_end status, message, cb
    # analysis currently only works on linux
    if os.platform().match /^win/
      return @_end status, message, cb
    # get additional information (top processes)
    cmd = "ps axu | awk '{print $2, $3, $4, $11}' | sort -k2 -nr | head -#{@config.analysis}"
    exec cmd, (err, stdout, stderr) =>
      unless err
        @result.analysis = """
        Currently the top #{@config.analysis} cpu consuming processes are:

        |  PID  |  %CPU |  %MEM | COMMAND                                            |
        | ----: | ----: | ----: | -------------------------------------------------- |\n"""
        for line in stdout.toString().split /\n/
          continue unless line
          col = line.split /\s/, 4
          @result.analysis += "| #{string.lpad col[0], 5} | #{string.lpad col[1], 5}
            | #{string.lpad col[2], 5} | #{string.rpad col[3], 50} |\n"
        debug @result.analysis
      @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = CpuSensor

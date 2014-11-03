# Load test class
# =================================================
# This may be used to check the performance of a host.
#
# The load values will be normalized, meaning the load per single cpu core will
# be calculated.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:load')
# include alinex packages
object = require('alinex-util').object
string = require('alinex-util').string
# include classes and helper modules
Sensor = require '../base'
# specific modules for this check
os = require 'os'
{exec} = require 'child_process'

# Sensor class
# -------------------------------------------------
class LoadSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Load'
    description: "Check the local processor activity over the last minute to 15 minutes."
    category: 'sys'
    level: 1
    hint: "A very high system load makes the system irresponsible or really slow.
    Mostly this is CPU-bound load, load caused by out of memory issues or I/O-bound
    load problems. "

    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "CPU load check"
      type: 'object'
      allowedKeys: true
      entries:
        verbose: @check.verbose
        warn: @check.warn
        fail: @check.fail
    # Definition of response values
    values:
      cpu:
        title: "CPU"
        description: "cpu model name with brand"
        type: 'string'
      cpus:
        title: "Num Cores"
        description: "number of cpu cores"
        type: 'integer'
      short:
        title: "1min Load"
        description: "average value of one minute processor load (normalized)"
        type: 'percent'
      medium:
        title: "5min Load"
        description: "average value of 5 minute processor load (normalized)"
        type: 'percent'
      long:
        title: "15min Load"
        description: "average value of 15 minute processor load (normalized)"
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
    val = @result.values
    val.cpus = cpus.length
    val.cpu = cpus[0].model.replace /\s+/g, ' '
    val.short = load[0] / val.cpus
    val.medium = load[1] / val.cpus
    val.long = load[2] / val.cpus
    # evaluate to check status
    status = @rules()
    message = @config[status] unless status is 'ok'
    if status is 'ok' and not @config.verbose
      return @_end status, message, cb
    # get additional information
    cmd = "ps axu | awk 'NR>1 {print $2, $3, $4, $11}'"
    exec cmd, (err, stdout, stderr) =>
      unless err
        procs = {}
        for line in stdout.toString().split /\n/
          continue unless line
          col = line.split /\s/, 4
          unless procs[col[3]]
            procs[col[3]] = [ 0, 0, 0 ]
          procs[col[3]][0]++
          procs[col[3]][1] += parseFloat col[1]
          procs[col[3]][2] += parseFloat col[2]
        keys = Object.keys(procs).sort (a,b) ->
          (procs[b][0]*100+procs[b][1]) - (procs[a][0]*100+procs[a][1])
        @result.analysis = """
        Currently the top processes are:

        | COUNT |  %CPU |  %MEM | COMMAND                                            |
        | ----: | ----: | ----: | -------------------------------------------------- |\n"""
        for proc in keys
          value = procs[proc]
          continue if value[0] is 1 and value[1] < 10
          @result.analysis += "| #{string.lpad value[0], 5} | #{string.lpad value[1], 5}
          | #{string.lpad value[2], 5} | #{string.rpad proc, 50} |\n"
        debug @result.analysis
      @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = LoadSensor

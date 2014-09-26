# Ping test class
# =================================================
# This is a basic test to check if connection to a specific server is possible.
# Keep in mind that some servers mare blocked through firewall settings.
#
# The warning level is based upon the round-trip time of packets which are
# typically:
#
#     1 ms        100BaseT-Ethernet
#     10 ms       WLAN 802.11b
#     40 ms       DSL-6000 without fastpath
#     < 50 ms     internet regional
#     55 ms       DSL-2000 without fastpath
#     100–150 ms  internet europe to usa
#     200 ms      ISDN
#     300 ms      internet europe to asia
#     300-400 ms  UMTS
#     700–1000 ms GPRS


# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:ping')
colors = require 'colors'
# include alinex packages
{object,number} = require 'alinex-util'
# include classes and helper
Sensor = require '../base'
# specific modules for this check
os = require 'os'
{spawn} = require 'child_process'

# Sensor class
# -------------------------------------------------
class PingSensor extends Sensor

  # ### General information
  # This information may be used later for display and explanation.
  @meta =
    name: 'Ping'
    description: "Test the reachability of a host on a IP network and measure the
    round-trip time for the messages send."
    category: 'net'
    level: 1
    # Check for configuration settings [alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible:
    config:
      title: "Ping test"
      type: 'object'
      allowedKeys: true
      entries:
        host:
          title: "Hostname or IP"
          description: "the server hostname or ip address to be called for ping"
          type: 'string'
        count:
          title: "Number of packets to send"
          description: "the number of ping packets to send, each after the other"
          type: 'integer'
          default: 1
          min: 1
        timeout:
          title: "Overall Timeout"
          description: "the time in milliseconds the whole test may take before
            stopping and failing it"
          type: 'interval'
          unit: 'ms'
          default: 1000
          min: 500
        responsetime:
          title: "Average ping time"
          description: "the average time in milliseconds the pings may take to
            not be marked as warning"
          type: 'interval'
          unit: 'ms'
          default: 500
          min: 0
        responsemax:
          title: "Maximum ping time"
          description: "the maximum time in milliseconds any ping may take to
            not be marked as warning"
          type: 'interval'
          unit: 'ms'
          default: 1000
          min:
            reference: 'relative'
            source: '<responsetime'

    # Definition of response values
    values:
      success:
        title: 'Success'
        description: "true if packets were echoed back"
        type: 'boolean'
      responsetime:
        title: 'Avg. Response Time'
        description: "average round-trip time of packets"
        type: 'integer'
        unit: 'ms'
      responsemin:
        title: 'Min. Respons Time'
        description: "minimum round-trip time of packets"
        type: 'integer'
        unit: 'ms'
      responsemax:
        title: 'Max. Response Time'
        description: "maximum round-trip time of packets"
        type: 'integer'
        unit: 'ms'
      quality:
        title: 'Quality'
        description: "quality of response (packets succeeded)"
        type: 'percent'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    # comand syntax, os dependent
    p = os.platform()
    ping = switch
      when p is 'linux'
        cmd: '/bin/ping'
        args: ['-c', @config.count, '-W', Math.ceil @config.timeout/1000]
      when p.match /^win/
        cmd: 'C:/windows/system32/ping.exe'
        args: ['-n', @config.count, '-w', @config.timeout]
      when p is 'darwin'
        cmd: '/sbin/ping'
        args: ['-c', @config.count, '-t', Math.ceil @config.timeout/1000]
      else
        throw new Error "Operating system #{p} is not supported in ping."
    ping.args.push @config.host
    # run the ping test
    @_spawn ping.cmd, ping.args, null, (err, stdout, stderr, code) =>
      return @_end 'fail', err, cb if err
      # parse results
      val = @result.value
      num = 0
      sum = 0
      re = /time=(\d+.?\d*) ms/g
      while match = re.exec stdout
        time = parseFloat match[1]
        num++
        sum += time
        if not val.responsemin? or time < val.responsemin
          val.responsemin = time
        if not val.responsemax? or time > val.responsemax
          val.responsemax = time
      val.responsetime = Math.round(sum/num*10)/10.0
      match = /\s(\d+)% packet loss/.exec stdout
      val.quality = 100-match?[1]
      # evaluate to check status
      status = switch
        when not val.success or val.quality < 100
          'fail'
        when @config.responsetime? and val.responsetime > @config.responsetime, \
             @config.responsemax? and val.responsemax > @config.responsemax
          'warn'
        else
          'ok'
      message = switch status
        when 'fail'
          "#{@constructor.meta.name} exited with status #{status}"
      @_end status, message, cb

# Export class
# -------------------------------------------------
module.exports = PingSensor

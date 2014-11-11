# Check network traffic
# =================================================
# This sensor only works on unix like systems using some base tools.

# Find the description of the possible configuration values and the returned
# values in the code below.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('monitor:sensor:net')
chalk = require 'chalk'
{exec} = require 'child_process'
# include alinex packages
fs = require 'alinex-fs'
{object,string} = require 'alinex-util'
# include classes and helper
Sensor = require '../base'
# specific modules for this check
os = require 'os'
math = require 'mathjs'

# Sensor class
# -------------------------------------------------
class NetSensor extends Sensor

  # ### General information
  #
  # This information may be used later for display and explanation.
  @meta =
    name: 'Network Traffic'
    description: "Check the network traffic."
    category: 'sys'
    level: 1
    hint: "If you see a high volume it may be overloaded or a attacke is
    running."

    # ### Configuration
    #
    # Definition of all possible configuration settings (defaults included).
    # It's a n[alinex-validator](http://alinex.githhub.io/node-validator)
    # compatible schema definition:
    config:
      title: "Network Traffic Test"
      type: 'object'
      allowedKeys: true
      entries:
        interface:
          title: "Interface Name"
          description: "the name of the interface to analyze"
          type: 'string'
          default: 'eth0'
        time:
          title: "Measurement Time"
          description: "the time for the measurement"
          type: 'interval'
          unit: 'ms'
          default: 10000
          min: 100
        verbose: @check.verbose
        warn: @check.warn
        fail: @check.fail

    # ### Result values
    #
    # This are possible values which may be given if the check runs normally.
    # You may use any of these in your warn/fail expressions.
    values:
      bytes:
        title: "Transfer"
        description: "the number of bytes of data transmitted or received by the interface"
        type: 'byte'
        unit: 'B'
      packets:
        title: "Packets"
        description: "the number of packets of data transmitted or received by the interface"
        type: 'integer'
      errors:
        title: "Errors"
        description: "the percentage of transmit or receive errors detected by the device driver"
        type: 'percent'
      drop:
        title: "Drops"
        description: "the percentage of packets dropped by the device driver"
        type: 'percent'
      fifo:
        title: "FIFO Errors"
        description: "the percentage of FIFO buffer errors"
        type: 'percent'
      frame:
        title: "Frame Errors"
        description: "the percentage of packet framing errors"
        type: 'percent'
      collisions:
        title: "Collisions"
        description: "the percentage of collisions detected on the interface"
        type: 'percent'
      compressed:
        title: "Compressed"
        description: "the percentage of compressed packets transmitted or received
        by the device driver"
        type: 'percent'
      carrier:
        title: "Carrier Losses"
        description: "the number of carrier losses detected by the device driver"
        type: 'integer'
      multicast:
        title: "Multicasts"
        description: "the number of multicast frames transmitted or received by the device driver"
        type: 'integer'
      state:
        title: "Interface State"
        description: "the state of the interface this may be UP, DOWN or UNKNOWN"
        type: 'string'
      mac:
        title: "Mac Address"
        description: "the mac address of the network card"
        type: 'string'
      ipv4:
        title: "IP Address"
        description: "the configured ip address"
        type: 'string'
      ipv6:
        title: "IPv6 Address"
        description: "the configured ip version 6 address"
        type: 'string'

  # ### Create instance
  constructor: (config) -> super config, debug

  # ### Run the check
  run: (cb = ->) ->
    @_start()
    # comand syntax, os dependent
    p = os.platform()
    unless p in ['linux', 'darwin']
      throw new Error "sensor can only work on linux systems"
    # read network information
    file = '/proc/net/dev'
    debug "Reading #{file}..."
    @result.range = [new Date]
    fs.readFile file, 'utf8', (err, data) =>
      return @_end 'fail', err, cb if err
      start = []
      setTimeout () =>
        fs.readFile file, 'utf8', (err, data) =>
          return @_end 'fail', err, cb if err
          end = []
          # parse measurement after time
          for line in data.split /\n/
            re = new RegExp "#{@config.interface}:"
            if line.match re
              debug line
              end = line.trim().split /\s+/
            else
              debug chalk.grey line
          # calculate and store the results
          diff = (col) -> end[col] - start[col]
          val = @result.values
          val.bytes = diff 1
          val.packets = diff 2
          percent = (col) ->
            return 0 unless val.packets
            (end[col] - start[col]) / val.packets
          val.errors = percent 3
          val.drop = percent 4
          val.fifo = percent 5
          val.frame = percent 6
          val.collisions = percent 7
          val.compressed = percent 8
          val.carrier = diff 9
          val.multicast = diff 10
          # evaluate to check status
          status = @rules()
          message = @config[status] unless status is 'ok'
          @more status, => return @_end status, message, cb
      , @config.time
      # parse start results while waiting for end measurement
      for line in data.split /\n/
        re = new RegExp "#{@config.interface}:"
        if line.match re
          debug line
          start = line.trim().split /\s+/
        else
          debug chalk.grey line

  more: (status, cb) ->
    # get interface settings
    cmd = "ip addr show #{@config.interface}"
    exec cmd,
      timeout: @config.analysisTimeout
    , (err, stdout, stderr) =>
      return cb() unless stdout
      lines = stdout.toString().split /\n\s*/
      match = /state ([A-Z]+)/.exec lines[0]
      @result.values.state = match[1]
      match = /(([0-9a-f]{2}:){5}[0-9a-f]{2})/.exec lines[1]
      @result.values.mac = match[1]
      if lines.length > 1
        for line in lines[2..]
          if match = /^inet ((\d{1,3}.){3}\d{1,3})/.exec line
            @result.values.ipv4 = match[1]
          else if match = /^inet6 (([0-9a-f]{0,4}:){5}[0-9a-f]{0,4})/.exec line
            @result.values.ipv6 = match[1]
      # check if analysis have to be done
      if status is 'ok' and not @config.verbose
        return cb()
      # analysis currently only works on linux
      exec 'netstat -plnta',
        env:
          LANG: 'DE'
      , (err, stdout, stderr) =>
        return cb() unless stdout
        # 0 Protocol
        # 1 Recv-Q
        # 2 Send-Q
        # 3 Local Address, Port
        # 4 Foreign Address, Port
        # 5 State
        # 6 PID, Program name
        server = ''
        conn = ''
        head = true
        for line in stdout.toString().trim().split /\n/
          cols = line.split /\s+/
          continue if cols[0] isnt 'Proto' and head
          if cols[0] is 'Proto'
            head = false
            continue
          if cols[5] is 'LISTEN'
            split = cols[3].lastIndexOf ':'
            ip = cols[3].substring 0, split
            port = cols[3].substring split+1
            server += "| #{string.rpad cols[0] , 5}
              | #{string.rpad ip, 20}
              | #{string.rpad port, 5} |\n"
          else
            split = cols[4].lastIndexOf ':'
            ip = cols[4].substring 0, split
            port = cols[4].substring split+1
            continue if not cols[6] or cols[6] is '-'
            [pid,cmd] = cols[6].split '/', 2
            conn += "| #{string.rpad cols[0] , 5}
              | #{string.rpad ip, 20}
              | #{string.rpad port, 5}
              | #{string.lpad pid, 6}
              | #{string.rpad (cmd ? ''), 14} |\n"
        @result.analysis = ''
        if server
          @result.analysis += """
            Listening servers:

            | PROTO | LOCAL IP             | PORT  |
            | :---- | :------------------- | :---- |
            #{server}\n"""
        if conn
          @result.analysis += """
            Active internet connections:

            | PROTO | FOREIGN IP           | PORT  |   PID  |     PROGRAM    |
            | :---- | :------------------- | ----: | -----: | :------------- |
            #{conn}\n"""
        cb()

# Export class
# -------------------------------------------------
module.exports = NetSensor

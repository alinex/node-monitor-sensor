chai = require 'chai'
expect = chai.expect
validator = require 'alinex-validator'

NetSensor = require '../../lib/type/net'

describe "Net", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', NetSensor.meta.config

    it "should be initialized", ->
      @timeout 5000
      net = new NetSensor validator.check 'config', NetSensor.meta.config,
        interface: 'eth0'
        time: 1000
      expect(net).to.have.property 'config'

    it "should return success", (done) ->
      @timeout 15000
      net = new NetSensor validator.check 'config', NetSensor.meta.config,
        interface: 'eth0'
      net.run (err) ->
        expect(err).to.not.exist
        expect(net.result).to.exist
#        expect(net.result.values.read).to.exist
#        expect(net.result.values.write).to.exist
#        expect(net.result.values.readTotal).to.exist
#        expect(net.result.values.writeTotal).to.exist
        expect(net.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      @timeout 5000
      net = new NetSensor validator.check 'config', NetSensor.meta.config,
        interface: 'wlan0'
        time: 1000
        verbose: true
      net.run (err) ->
        expect(err).to.not.exist
        text = net.format()
        expect(text).to.exist
        console.log text
        done()

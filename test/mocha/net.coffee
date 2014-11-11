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
        expect(net.result.values.bytes).to.exist
        expect(net.result.values.packets).to.exist
        expect(net.result.values.errors).to.exist
        expect(net.result.values.drops).to.exist
        expect(net.result.values.fifo).to.exist
        expect(net.result.values.frame).to.exist
        expect(net.result.values.collisions).to.exist
        expect(net.result.values.compressed).to.exist
        expect(net.result.values.carrier).to.exist
        expect(net.result.values.multicast).to.exist
        expect(net.result.values.state).to.exist
        expect(net.result.values.mac).to.exist
        expect(net.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      @timeout 5000
      net = new NetSensor validator.check 'config', NetSensor.meta.config,
        interface: 'eth0'
        time: 1000
        verbose: true
      net.run (err) ->
        expect(err).to.not.exist
        text = net.format()
        expect(text).to.exist
        console.log text
        done()

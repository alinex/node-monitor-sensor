chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

IoSensor = require '../../lib/type/io'

describe "IO", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', IoSensor.meta.config

    it "should be initialized", ->
      io = new IoSensor validator.check 'config', IoSensor.meta.config,
        device: 'sda'
      expect(io).to.have.property 'config'

    it "should return success", (done) ->
      io = new IoSensor validator.check 'config', IoSensor.meta.config,
        device: 'sda'
      io.run (err) ->
        expect(err).to.not.exist
        expect(io.result).to.exist
        expect(io.result.values.read).to.exist
        expect(io.result.values.write).to.exist
        expect(io.result.values.readTotal).to.exist
        expect(io.result.values.writeTotal).to.exist
        expect(io.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      io = new IoSensor validator.check 'config', IoSensor.meta.config,
        device: 'sda'
      io.run (err) ->
        expect(err).to.not.exist
        text = io.format()
        expect(text).to.exist
        console.log text
        done()

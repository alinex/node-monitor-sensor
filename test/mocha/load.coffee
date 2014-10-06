chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

LoadSensor = require '../../lib/type/load'

describe "Load", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', LoadSensor.meta.config

    it "should be initialized", ->
      load = new LoadSensor validator.check 'config', LoadSensor.meta.config,
        longWarn: 15
      expect(load).to.have.property 'config'

    it "should return success", (done) ->
      load = new LoadSensor validator.check 'config', LoadSensor.meta.config,
        longWarn: 15
      load.run (err) ->
        expect(err).to.not.exist
        expect(load.result).to.exist
        expect(load.result.value.cpu).to.exist
        expect(load.result.value.cpus).to.be.above 0
        expect(load.result.value.short).to.be.above 0
        expect(load.result.value.medium).to.be.above 0
        expect(load.result.value.long).to.be.above 0
        expect(load.result.status).to.equal 'ok'
        expect(load.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      load = new LoadSensor validator.check 'config', LoadSensor.meta.config,
        longWarn: 15
      load.run (err) ->
        expect(err).to.not.exist
        text = load.format()
        expect(text).to.exist
        console.log text
        done()

chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

LoadSensor = require '../../lib/type/load'

describe.only "Load", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', LoadSensor.meta.config

    it "should be initialized", ->
      df = new LoadSensor validator.check 'config', LoadSensor.meta.config,
        longWarn: 15
      expect(df).to.have.property 'config'

    it "should return success", (done) ->
      df = new LoadSensor validator.check 'config', LoadSensor.meta.config,
        longWarn: 15
      df.run (err) ->
        expect(err).to.not.exist
        expect(df.result).to.exist
        expect(df.result.value.cpu).to.exist
        expect(df.result.value.cpus).to.be.above 0
        expect(df.result.value.short).to.be.above 0
        expect(df.result.value.medium).to.be.above 0
        expect(df.result.value.long).to.be.above 0
        expect(df.result.status).to.equal 'ok'
        expect(df.result.message).to.not.exist
        done()


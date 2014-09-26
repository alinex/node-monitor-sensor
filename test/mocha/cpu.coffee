chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

CpuSensor = require '../../lib/type/cpu'

describe.only "Cpu", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', CpuSensor.meta.config

    it "should be initialized", ->
      df = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        warn: 0.90
      expect(df).to.have.property 'config'

    it "should return success", (done) ->
      df = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        warn: 0.99
      df.run (err) ->
        expect(err).to.not.exist
        expect(df.result).to.exist
        expect(df.result.value.cpu).to.exist
        expect(df.result.value.cpus).to.be.above 0
        expect(df.result.value.user).to.exist
        expect(df.result.value.system).to.exist
        expect(df.result.value.idle).to.exist
        expect(df.result.value.active).to.exist
        expect(df.result.status).to.equal 'ok'
        expect(df.result.message).to.not.exist
        done()


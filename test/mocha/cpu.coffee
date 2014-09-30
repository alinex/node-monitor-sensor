chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

CpuSensor = require '../../lib/type/cpu'

describe "Cpu", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', CpuSensor.meta.config

    it "should be initialized", ->
      cpu = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        warn: 0.90
      expect(cpu).to.have.property 'config'

    it "should return success", (done) ->
      cpu = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        warn: 0.99
      cpu.run (err) ->
        expect(err).to.not.exist
        expect(cpu.result).to.exist
        expect(cpu.result.value.cpu).to.exist
        expect(cpu.result.value.cpus).to.be.above 0
        expect(cpu.result.value.user).to.exist
        expect(cpu.result.value.system).to.exist
        expect(cpu.result.value.idle).to.exist
        expect(cpu.result.value.active).to.exist
        expect(cpu.result.status).to.equal 'ok'
        expect(cpu.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      cpu = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        warn: 0.99
      cpu.run (err) ->
        expect(err).to.not.exist
        text = cpu.format()
        expect(text).to.exist
        console.log text
        done()

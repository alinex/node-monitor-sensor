chai = require 'chai'
expect = chai.expect
validator = require 'alinex-validator'

CpuSensor = require '../../lib/type/cpu'

describe "Cpu", ->

  describe "init", ->

    it "should has correct validation rules", ->
      validator.selfcheck 'meta.config', CpuSensor.meta.config

    it "should be initialized", ->
      cpu = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        warn: 'active > 90%'
      expect(cpu).to.have.property 'config'

  describe "run", ->

    it "should return success", (done) ->
      cpu = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        warn: 'active > 99%'
      cpu.run (err) ->
        expect(err).to.not.exist
        expect(cpu.result).to.exist
        expect(cpu.result.values.cpu).to.exist
        expect(cpu.result.values.cpus).to.be.above 0
        expect(cpu.result.values.user).to.exist
        expect(cpu.result.values.system).to.exist
        expect(cpu.result.values.idle).to.exist
        expect(cpu.result.values.active).to.exist
        expect(cpu.result.status).to.equal 'ok'
        expect(cpu.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      cpu = new CpuSensor validator.check 'config', CpuSensor.meta.config,
        verbose: true
        warn: 'active > 99%'
      cpu.run (err) ->
        expect(err).to.not.exist
        text = cpu.format()
        expect(text).to.exist
        console.log text
        done()

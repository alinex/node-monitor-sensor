chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

MemorySensor = require '../../lib/type/memory'

describe "Memory", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', MemorySensor.meta.config

    it "should be initialized", ->
      memory = new MemorySensor validator.check 'config', MemorySensor.meta.config,
        fail: 'free < 1MB'
      expect(memory).to.have.property 'config'

    it "should return success", (done) ->
      memory = new MemorySensor validator.check 'config', MemorySensor.meta.config,
        fail: 'free < 100kB'
      memory.run (err) ->
        console.log err, memory.result unless memory.result.status is 'ok'
        expect(err).to.not.exist
        expect(memory.result).to.exist
        expect(memory.result.values.success).to.equal true
        expect(memory.result.values.total).to.be.above 0
        expect(memory.result.values.used).to.be.above 0
        expect(memory.result.values.free).to.be.above 0
        expect(memory.result.values.shared).to.exist
        expect(memory.result.values.buffers).to.exist
        expect(memory.result.values.cached).to.exist
        expect(memory.result.values.swapTotal).to.exist
        expect(memory.result.values.swapUsed).to.exist
        expect(memory.result.values.swapFree).to.exist
        expect(memory.result.values.actualFree).to.be.above 0
        expect(memory.result.status).to.equal 'ok'
        expect(memory.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      memory = new MemorySensor validator.check 'config', MemorySensor.meta.config,
        fail: 'free < 1MB'
      memory.run (err) ->
        expect(err).to.not.exist
        text = memory.format()
        expect(text).to.exist
        console.log text
        done()

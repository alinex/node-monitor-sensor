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
        freeFail: '1M'
      expect(memory).to.have.property 'config'

    it "should return success", (done) ->
      memory = new MemorySensor validator.check 'config', MemorySensor.meta.config,
        freeFail: '1M'
      memory.run (err) ->
        expect(err).to.not.exist
        expect(memory.result).to.exist
        expect(memory.result.value.success).to.equal true
        expect(memory.result.value.total).to.be.above 0
        expect(memory.result.value.used).to.be.above 0
        expect(memory.result.value.free).to.be.above 0
        expect(memory.result.value.shared).to.exist
        expect(memory.result.value.buffers).to.exist
        expect(memory.result.value.cached).to.exist
        expect(memory.result.value.swapTotal).to.exist
        expect(memory.result.value.swapUsed).to.exist
        expect(memory.result.value.swapFree).to.exist
        expect(memory.result.value.actualFree).to.be.above 0
        expect(memory.result.status).to.equal 'ok'
        expect(memory.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      memory = new MemorySensor validator.check 'config', MemorySensor.meta.config,
        freeFail: '1M'
      memory.run (err) ->
        expect(err).to.not.exist
        text = memory.format()
        expect(text).to.exist
        console.log text
        done()

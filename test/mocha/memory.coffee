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
      df = new MemorySensor validator.check 'config', MemorySensor.meta.config,
        freeFail: '1M'
      expect(df).to.have.property 'config'

    it "should return success", (done) ->
      df = new MemorySensor validator.check 'config', MemorySensor.meta.config,
        freeFail: '1M'
      df.run (err) ->
        expect(err).to.not.exist
        expect(df.result).to.exist
        expect(df.result.value.success).to.equal true
        expect(df.result.value.total).to.be.above 0
        expect(df.result.value.used).to.be.above 0
        expect(df.result.value.free).to.be.above 0
        expect(df.result.value.shared).to.be.above 0
        expect(df.result.value.buffers).to.be.above 0
        expect(df.result.value.cached).to.be.above 0
        expect(df.result.value.swapTotal).to.be.above 0
        expect(df.result.value.swapUsed).to.be.above 0
        expect(df.result.value.swapFree).to.be.above 0
        expect(df.result.value.actualFree).to.be.above 0
        expect(df.result.status).to.equal 'ok'
        expect(df.result.message).to.not.exist
        done()


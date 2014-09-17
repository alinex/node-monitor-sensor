chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

DiskfreeSensor = require '../../lib/diskfree'

describe "Diskfree", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', DiskfreeSensor.meta.config

    it "should be initialized", ->
      df = new DiskfreeSensor {}
      expect(df).to.have.property 'config'

    it "should return success", (done) ->
      df = new DiskfreeSensor
        share: '/'
      df.run (err) ->
        expect(err).to.not.exist
        expect(df.result).to.exist
        expect(df.result.value.total).to.be.above 0
        expect(df.result.value.used).to.be.above 0
        expect(df.result.value.free).to.be.above 0
        expect(df.result.message).to.not.exist
        done()


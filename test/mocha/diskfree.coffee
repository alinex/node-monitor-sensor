chai = require 'chai'
expect = chai.expect
validator = require 'alinex-validator'

DiskfreeSensor = require '../../lib/type/diskfree'

describe "Diskfree", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', DiskfreeSensor.meta.config

    it "should be initialized", ->
      df = new DiskfreeSensor validator.check 'config', DiskfreeSensor.meta.config,
        share: '/'
      expect(df).to.have.property 'config'

    it "should return success", (done) ->
      df = new DiskfreeSensor validator.check 'config', DiskfreeSensor.meta.config,
        share: '/'
      df.run (err) ->
        expect(err).to.not.exist
        expect(df.result).to.exist
        expect(df.result.values.total).to.be.above 0
        expect(df.result.values.used).to.be.above 0
        expect(df.result.values.free).to.be.above 0
        expect(df.result.message).to.not.exist
        done()

    it "should work with binary values", (done) ->
      df = new DiskfreeSensor validator.check 'config', DiskfreeSensor.meta.config,
        share: '/'
        warn: 'free < 1GB'
      df.run (err) ->
        expect(err).to.not.exist
        expect(df.result).to.exist
        expect(df.result.values.total).to.be.above 0
        expect(df.result.values.used).to.be.above 0
        expect(df.result.values.free).to.be.above 0
        expect(df.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      df = new DiskfreeSensor validator.check 'config', DiskfreeSensor.meta.config,
        share: '/'
        analysis: ['/tmp']
        verbose: true
      df.run (err) ->
        expect(err).to.not.exist
        text = df.format()
        expect(text).to.exist
        console.log text
        done()

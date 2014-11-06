chai = require 'chai'
expect = chai.expect
validator = require 'alinex-validator'

TimeSensor = require '../../lib/type/time'

describe "Time", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', TimeSensor.meta.config,
        warn: 'diff > 1m'

    it "should be initialized", ->
      time = new TimeSensor validator.check 'config', TimeSensor.meta.config,
        warn: 'diff > 1m'
      expect(time).to.have.property 'config'

    it "should return success", (done) ->
      time = new TimeSensor validator.check 'config', TimeSensor.meta.config,
        warn: 'diff > 1m'
      time.run (err) ->
        expect(err).to.not.exist
        expect(time.result).to.exist
        expect(time.result.values.local).to.exist
        expect(time.result.values.remote).to.exist
        expect(time.result.values.diff).to.exist
        expect(time.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      time = new TimeSensor validator.check 'config', TimeSensor.meta.config,
        warn: 'diff > 1m'
      time.run (err) ->
        expect(err).to.not.exist
        text = time.format()
        expect(text).to.exist
        console.log text
        done()

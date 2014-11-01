chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

Sensor = require '../../lib/base'

describe.only "Sensor", ->

  describe "init", ->

    it "should has correct validation rules", ->
      validator.selfcheck 'check.fail', Sensor.check.fail
      validator.selfcheck 'check.warn', Sensor.check.warn
      validator.selfcheck 'check.verbose', Sensor.check.verbose

    it "should be initialized", ->
      sensor = new Sensor
        warn: 'active > 90%'
      expect(sensor).to.have.property 'config'

  describe "rules", ->

    it "should work on normal operations", ->
      sensor = new Sensor { fail: 'active > 0.9' }
      sensor.result = { values: { active: 0.5 } }
      expect(sensor.rules(), 'ok').to.equal 'ok'
      sensor = new Sensor { fail: 'active >= 0.5' }
      sensor.result = { values: { active: 0.5 } }
      expect(sensor.rules(), 'fail').to.equal 'fail'

    it "should work with percent values", ->
      sensor = new Sensor { fail: 'active > 90%' }
      sensor.result = { values: { active: 0.5 } }
      expect(sensor.rules(), 'ok').to.equal 'ok'
      sensor = new Sensor { fail: 'active >= 50%' }
      sensor.result = { values: { active: 0.5 } }
      expect(sensor.rules(), 'fail').to.equal 'fail'

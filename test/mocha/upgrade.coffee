chai = require 'chai'
expect = chai.expect
validator = require 'alinex-validator'

UpgradeSensor = require '../../lib/type/upgrade'

describe "Upgrade", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', UpgradeSensor.meta.config

    it "should be initialized", ->
      upgrade = new UpgradeSensor validator.check 'config', UpgradeSensor.meta.config,
        fail: 'time > 5d'
      expect(upgrade).to.have.property 'config'

    it "should return success", (done) ->
      @timeout 60000
      upgrade = new UpgradeSensor validator.check 'config', UpgradeSensor.meta.config,
        fail: 'time > 5000d'
      upgrade.run (err) ->
        expect(err).to.not.exist
        expect(upgrade.result).to.exist
        expect(upgrade.result.values).to.exist
        expect(upgrade.result.status).to.equal 'ok'
        expect(upgrade.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      @timeout 60000
      upgrade = new UpgradeSensor validator.check 'config', UpgradeSensor.meta.config,
        fail: 'time > 5d'
      upgrade.run (err) ->
        expect(err).to.not.exist
        text = upgrade.format()
        expect(text).to.exist
        console.log text
        done()

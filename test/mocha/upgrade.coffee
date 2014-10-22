chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

UpgradeSensor = require '../../lib/type/upgrade'

describe "Upgrade", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', UpgradeSensor.meta.config

    it "should be initialized", ->
      upgrade = new UpgradeSensor validator.check 'config', UpgradeSensor.meta.config,
        timeFail: 5
      expect(upgrade).to.have.property 'config'

    it "should return success", (done) ->
      @timeout 30000
      upgrade = new UpgradeSensor validator.check 'config', UpgradeSensor.meta.config,
        timeFail: 5000
      upgrade.run (err) ->
        expect(err).to.not.exist
        expect(upgrade.result).to.exist
        expect(upgrade.result.value).to.exist
        expect(upgrade.result.status).to.equal 'ok'
        expect(upgrade.result.message).to.not.exist
        done()

    it "should format result", (done) ->
      @timeout 30000
      upgrade = new UpgradeSensor validator.check 'config', UpgradeSensor.meta.config,
        timeFail: 5
      upgrade.run (err) ->
        expect(err).to.not.exist
        text = upgrade.format()
        expect(text).to.exist
        console.log text
        done()

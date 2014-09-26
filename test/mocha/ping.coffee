chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

PingSensor = require '../../lib/type/ping'

describe "Ping sensor", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', PingSensor.meta.config

    it "should be initialized", ->
      ping = new PingSensor {}
      expect(ping).to.have.property 'config'

    it "should return success", (done) ->
      ping = new PingSensor validator.check 'config', PingSensor.meta.config,
        host: '193.99.144.80'
      ping.run (err) ->
        expect(err).to.not.exist
        expect(ping.result).to.exist
        expect(ping.result.date).to.exist
        expect(ping.result.status).to.equal 'ok'
        expect(ping.result.message).to.not.exist
        done()

    it "should succeed with domain name", (done) ->
      ping = new PingSensor validator.check 'config', PingSensor.meta.config,
        host: 'heise.de'
      ping.run (err) ->
        expect(err).to.not.exist
        expect(ping.result).to.exist
        expect(ping.result.date).to.exist
        expect(ping.result.status).to.equal 'ok'
        expect(ping.result.message).to.not.exist
        done()

    it "should send multiple packets", (done) ->
      @timeout 10000
      ping = new PingSensor validator.check 'config', PingSensor.meta.config,
        host: '193.99.144.80'
        count: 10
      ping.run (err) ->
        expect(err).to.not.exist
        expect(ping.result).to.exist
        expect(ping.result.date).to.exist
        expect(ping.result.status).to.equal 'ok'
        expect(ping.result.message).to.not.exist
        done()

    it "should return fail", (done) ->
      ping = new PingSensor validator.check 'config', PingSensor.meta.config,
        host: '137.168.111.222'
      ping.run (err) ->
        expect(err).to.not.exist
        expect(ping.result).to.exist
        expect(ping.result.date).to.exist
        expect(ping.result.status).to.equal 'fail'
        expect(ping.result.message).to.exist
        done()

  describe "check", ->

    it "should succeed for complete configuration", (done) ->
      validator.check 'test', PingSensor.meta.config,
        host: '193.99.144.80'
        count: 10
        timeout: 5000
        responsetime: 500
        responsemax: 1000
      , (err) ->
        expect(err).to.not.exist
        done()

    it "should succeed with human readable values", (done) ->
      validator.check 'test', PingSensor.meta.config,
        host: '193.99.144.80'
        count: 10
        timeout: '5s'
        responsetime: 500
        responsemax: '1s'
      , (err) ->
        expect(err).to.not.exist
        done()

    it "should succeed for simple configuration", (done) ->
      validator.check 'test', PingSensor.meta.config,
        host: '193.99.144.80'
      , (err) ->
        expect(err).to.not.exist
        done()

    it "should fail for missing host", (done) ->
      validator.check 'test', PingSensor.meta.config,
        ip: '193.99.144.80'
      , (err) ->
        expect(err).to.exist
        done()

    it "should fail for wrong timeout", (done) ->
      validator.check 'test', PingSensor.meta.config,
        host: '193.99.144.80'
        timeout: []
      , (err) ->
        expect(err).to.exist
        done()

    it "should succeed with timeout as string", (done) ->
      validator.check 'test', PingSensor.meta.config,
        host: '193.99.144.80'
        timeout: '5000'
      , (err) ->
        expect(err).to.not.exist
        done()

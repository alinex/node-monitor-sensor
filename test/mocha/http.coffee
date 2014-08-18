chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

HttpSensor = require '../../lib/http'

describe "Http request sensor", ->

  describe "check", ->

    it "should be initialized", ->
      http = new HttpSensor {}
      expect(http).to.have.property 'config'

    it "should connect to webserver", (done) ->
      http = new HttpSensor
        url: 'http://heise.de'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.data).to.exist
        expect(http.result.message).to.not.exist
        done()

    it "should fail for non-existent webserver", (done) ->
      @timeout 10000
      http = new HttpSensor
        url: 'http://nonexistentsubdomain.unknown.site'
      http.run (err) ->
        expect(err).to.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.data).to.exist
        expect(http.result.message).to.exist
        done()

    it "should fail for wrong protocol", (done) ->
      http = new HttpSensor
        url: 'ftp://heise.de'
      http.run (err) ->
        expect(err).to.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.data).to.exist
        expect(http.result.message).to.exist
        done()

    it "should fail for non-existing page", (done) ->
      http = new HttpSensor
        url: 'http://heise.de/page-which-does-not-exit-on-this-server'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.data).to.exist
        expect(http.result.message).to.exist
        done()

    it "should check the body part", (done) ->
      http = new HttpSensor
        url: 'http://heise.de'
        bodycheck: 'Newsticker'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.value.bodycheck).to.exist
        expect(http.result.value.bodycheck).to.equal true
        done()

    it "should check the body part with RegExp", (done) ->
      http = new HttpSensor
        url: 'http://heise.de'
        bodycheck: /heise Developer|iX Magazin/
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.value.bodycheck).to.exist
        expect(http.result.value.bodycheck).to.equal true
        done()

  describe "check", ->

    it "should succeed for complete configuration", (done) ->
      validator.check 'test', HttpSensor.meta.config,
        url: 'heise.de'
        timeout: 5000
        responsetime: 500
        username: 'alex'
        password: 'alex'
        bodycheck: 'Login'
      , (err) ->
        expect(err).to.not.exist
        done()

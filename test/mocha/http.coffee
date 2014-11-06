chai = require 'chai'
expect = chai.expect
validator = require 'alinex-validator'

HttpSensor = require '../../lib/type/http'

describe "Http request sensor", ->

  describe "init", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', HttpSensor.meta.config

    it "should be initialized", ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
      expect(http).to.have.property 'config'

  describe "check", ->

    it "should connect to webserver", (done) ->
      @timeout 10000
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
      http.run (err) ->
        console.log err, http.result unless http.result.status is 'ok'
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.message).to.not.exist
        expect(http.result.values.responsetime).to.exist
        expect(http.result.values.statuscode).to.exist
        expect(http.result.values.statusmessage).to.exist
        expect(http.result.values.server).to.exist
        expect(http.result.values.contenttype).to.exist
        expect(http.result.values.length).to.exist
        done()

    it "should fail for non-existent webserver", (done) ->
      @timeout 10000
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://nonexistentsubdomain.unknown.site'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.message).to.exist
        done()

    it "should fail for wrong protocol", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'ftp://heise.de'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.message).to.exist
        done()

    it "should fail for non-existing page", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de/page-which-does-not-exit-on-this-server'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.message).to.exist
        done()

  describe "match body", ->

    it "should work with simple substring", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
        match: 'Newsticker'
        fail: 'not match'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.values.match).to.exist
        expect(http.result.values.match).to.deep.equal ['Newsticker']
        done()

    it "should fail with simple substring", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
        match: 'GODCHA nOt INCLUDED'
        fail: 'not match'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.message).to.exist
        done()

    it "should work with simple RegExp", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
        match: /heise Developer|iX Magazin/
        fail: 'not match'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.values.match).to.exist
        expect(http.result.values.match).to.deep.equal ['heise Developer']
        done()

    it "should fail with simple RegExp", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
        match: /heise Alinex Developer/
        fail: 'not match'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.message).to.exist
        done()

    it "should work with named RegExp", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
        match: /(:<title>heise Developer|iX Magazin)/
        fail: 'not match'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.values.match).to.exist
        expect(Boolean http.result.values.match).to.equal true
        done()

    it "should fail with named RegExp", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
        match: /(:<title>Alinex Developer|Alinex Magazin)/
        fail: 'not match'
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'fail'
        expect(http.result.message).to.exist
        done()

    it "should work with named RegExp and value check", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
        match: /(:<title>heise Developer|iX Magazin)/
        fail: 'match.title isnt \'heise Developer\''
      http.run (err) ->
        expect(err).to.not.exist
        expect(http.result).to.exist
        expect(http.result.date).to.exist
        expect(http.result.status).to.equal 'ok'
        expect(http.result.values.match).to.exist
        expect(Boolean http.result.values.match).to.equal true
        done()

  describe "meta", ->

    it "should succeed for complete configuration", (done) ->
      validator.check 'test', HttpSensor.meta.config,
        url: 'heise.de'
        timeout: 5000
        username: 'alex'
        password: 'alex'
        match: 'Login'
      , (err) ->
        expect(err).to.not.exist
        done()

    it "should format result", (done) ->
      http = new HttpSensor validator.check 'config', HttpSensor.meta.config,
        url: 'http://heise.de'
      http.run (err) ->
        expect(err).to.not.exist
        text = http.format()
        expect(text).to.exist
        console.log text
        done()

chai = require 'chai'
expect = chai.expect
require('alinex-error').install()
validator = require 'alinex-validator'

SocketSensor = require '../../lib/type/socket'

describe "Socket connection sensor", ->

  describe "run", ->

    it "should has correct validator rules", ->
      validator.selfcheck 'meta.config', SocketSensor.meta.config

    it "should be initialized", ->
      socket = new SocketSensor validator.check 'config', SocketSensor.meta.config,
        host: '193.99.144.80'
        port: 80
      expect(socket).to.have.property 'config'

    it "should connect to webserver", (done) ->
      socket = new SocketSensor validator.check 'config', SocketSensor.meta.config,
        host: '193.99.144.80'
        port: 80
      socket.run (err) ->
        expect(err).to.not.exist
        expect(socket.result).to.exist
        expect(socket.result.date).to.exist
        expect(socket.result.status).to.equal 'ok'
        expect(socket.result.message).to.not.exist
        done()

    it "should connect to webserver by hostname", (done) ->
      socket = new SocketSensor validator.check 'config', SocketSensor.meta.config,
        host: 'heise.de'
        port: 80
      socket.run (err) ->
        expect(err).to.not.exist
        expect(socket.result).to.exist
        expect(socket.result.date).to.exist
        expect(socket.result.status).to.equal 'ok'
        expect(socket.result.message).to.not.exist
        done()

    it "should fail to connect to wrong port", (done) ->
      @timeout 5000
      socket = new SocketSensor validator.check 'config', SocketSensor.meta.config,
        host: '193.99.144.80'
        port: 1298
        timeout: 4000
      socket.run (err) ->
        expect(err).to.not.exist
        expect(socket.result).to.exist
        expect(socket.result.date).to.exist
        expect(socket.result.status).to.equal 'fail'
        expect(socket.result.message).to.exist
        done()

    it "should fail to connect to wrong host", (done) ->
      @timeout 5000
      socket = new SocketSensor validator.check 'config', SocketSensor.meta.config,
        host: 'unknownsubdomain.nonexisting.host'
        port: 80
      socket.run (err) ->
        expect(err).to.not.exist
        expect(socket.result).to.exist
        expect(socket.result.date).to.exist
        expect(socket.result.status).to.equal 'fail'
        expect(socket.result.message).to.exist
        done()

  describe "check", ->

    it "should succeed for complete configuration", (done) ->
      validator.check 'test', SocketSensor.meta.config,
        host: '193.99.144.80'
        port: 80
        timeout: 5000
        responsetime: 500
      , (err) ->
        expect(err).to.not.exist
        done()

    it "should format result", (done) ->
      socket = new SocketSensor validator.check 'config', SocketSensor.meta.config,
        host: '193.99.144.80'
        port: 80
      socket.run (err) ->
        expect(err).to.not.exist
        text = socket.format()
        expect(text).to.exist
        console.log text
        done()

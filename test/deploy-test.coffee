chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'deploy', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
      logger:
        warning: sinon.spy()

    require('../src/deploy')(@robot)

  it 'registers a deploy/build listener', ->
    expect(@robot.respond).to.have.been.calledWith(/(deploy|build) ([\w\.\-_]+) (.+)?/i)

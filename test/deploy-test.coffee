chai = require 'chai'
sinon  = require 'sinon'
chai.use require 'sinon-chai'
expect = require('chai').expect
path   = require 'path'

Robot       = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

CONFIG = """
{
  "staging": {
    "job": "deploy-staging",
    "role": "*"
  },
  "production": {
    "job": "deploy-production",
    "role": "deploy"
  },
  "image": {
    "job": "build-image",
    "role": "*"
  }
}
"""

describe 'auth', ->
  robot = {}
  adminUser = {}
  roleUser = {}
  adapter = {}

  beforeEach (done) ->
    # Fake environment variables
    process.env.HUBOT_AUTH_ADMIN = "1"
    process.env.HUBOT_DEPLOY_CONFIG = CONFIG

    # Create new robot, without http, using mock adapter
    robot = new Robot null, "mock-adapter", false

    # Fake Jenkins
    robot.jenkins =
      build: sinon.spy()

    robot.adapter.on "connected", ->
      # load modules and configure it for the robot. This is in place of
      # external-scripts
      require(path.resolve path.join("node_modules/hubot-auth/src"), "auth")(@robot)
      require('../src/deploy')(@robot)

      adminUser = robot.brain.userForId "1", {
        name: "admin-user"
        room: "#test"
      }

      roleUser = robot.brain.userForId "2", {
        name: "role-user"
        room: "#test"
        roles: [
          'deploy'
        ]
      }

      adapter = robot.adapter

    robot.run()

    done()

  afterEach ->
    robot.shutdown()

  it 'deploy master to staging', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy staging master")
    expect(robot.jenkins.build).to.be.calledOnce
    done()

  it 'deploy master to production', (done) ->
    adapter.receive(new TextMessage roleUser, "hubot deploy production master")
    expect(robot.jenkins.build).to.be.calledOnce
    done()

  it 'unauthorized deploy to production', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy production master")
    expect(robot.jenkins.build).to.be.not.called
    done()

  it 'build image', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot build image master")
    expect(robot.jenkins.build).to.be.calledOnce
    done()

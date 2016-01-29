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
  },
  "release": {
    "job": "test-release",
    "role": "*"
  },
  "ami-simple": {
    "job": "build-ami-simple",
    "role": "*",
    "params": "ONE"
  },
  "ami-complex": {
    "job": "build-ami-complex",
    "role": "*",
    "params": "ONE,TWO,THREE"
  },
  "worker": {
    "job": "deploy-worker",
    "role": "*",
    "params": "BRANCH,WORKER"
  },
  "alertworker": {
    "job": "deploy-worker",
    "role": "*",
    "params": {
      "BRANCH": "prod",
      "WORKER": "alertworker"
    }
  },
  "multiworker": {
    "job": "deploy-worker",
    "role": "*",
    "params": {
      "BRANCH": "prod",
      "HOSTS": "host2,host3"
    }
  }
}
"""

describe 'jenkins-deploy', ->
  robot = {}
  adminUser = {}
  roleUser = {}
  adapter = {}

  beforeEach (done) ->
    # Fake environment variables
    process.env.HUBOT_AUTH_ADMIN = "1"
    process.env.HUBOT_JENKINS_DEPLOY_CONFIG = CONFIG

    # Create new robot, without http, using mock adapter
    robot = new Robot null, "mock-adapter", false

    # Fake Jenkins
    robot.jenkins =
      build: sinon.spy()

    robot.adapter.on "connected", ->
      # load modules and configure it for the robot. This is in place of
      # external-scripts
      require(path.resolve path.join("node_modules/hubot-auth/src"), "auth")(@robot)
      require('../src/jenkins-deploy')(@robot)

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

  it 'unrestricted access deploy', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy staging master")
    expect(robot.jenkins.build).to.be.calledOnce
    params = robot.jenkins.build.args[0][0].match[3]
    expect(params).to.equal('BRANCH=master')
    done()

  it 'restricted access deploy', (done) ->
    adapter.receive(new TextMessage roleUser, "hubot deploy production master")
    expect(robot.jenkins.build).to.be.calledOnce
    done()

  it 'unsuccessful restricted access deploy', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy production master")
    expect(robot.jenkins.build).to.be.not.called
    done()

  it 'unsuccessful deploy of invalid environment', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy blah master")
    expect(robot.jenkins.build).to.be.not.called
    done()

  it 'unrestricted access build', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot build image master")
    expect(robot.jenkins.build).to.be.calledOnce
    done()

  it 'unrestricted access test', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot test release rc")
    expect(robot.jenkins.build).to.be.calledOnce
    done()

  it 'unrestricted access single parameter', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot build ami-simple one")
    expect(robot.jenkins.build).to.be.calledOnce
    params = robot.jenkins.build.args[0][0].match[3]
    expect(params).to.equal('ONE=one')
    done()

  it 'unrestricted access multiple parameters', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot build ami-complex one,two,three")
    expect(robot.jenkins.build).to.be.calledOnce
    params = robot.jenkins.build.args[0][0].match[3]
    expect(params).to.equal('ONE=one&TWO=two&THREE=three')
    done()

  it 'restricted access deploy when hubot-auth is not installed', (done) ->
    robot.auth = null
    adapter.receive(new TextMessage roleUser, "hubot deploy production master")
    expect(robot.jenkins.build).to.be.calledOnce
    done()

  it 'unrestricted access multiple parameters space seperated', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy ami-complex one two three")
    expect(robot.jenkins.build).to.be.calledOnce
    params = robot.jenkins.build.args[0][0].match[3]
    expect(params).to.equal('ONE=one&TWO=two&THREE=three')
    done()

  it 'unrestricted access defaulted parameters', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy alertworker prod")
    expect(robot.jenkins.build).to.be.calledOnce
    params = robot.jenkins.build.args[0][0].match[3]
    expect(params).to.equal('BRANCH=prod&WORKER=alertworker')
    done()

  it 'unrestricted access more defaulted parameters', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy multiworker prod")
    expect(robot.jenkins.build).to.be.calledOnce
    params = robot.jenkins.build.args[0][0].match[3]
    expect(params).to.equal('BRANCH=prod&HOSTS=host2,host3')
    done()

  it 'unrestricted access space and comma seperation', (done) ->
    adapter.receive(new TextMessage adminUser, "hubot deploy worker prod host1,host4")
    expect(robot.jenkins.build).to.be.calledOnce
    params = robot.jenkins.build.args[0][0].match[3]
    expect(params).to.equal('BRANCH=prod&WORKER=host1,host4')
    done()

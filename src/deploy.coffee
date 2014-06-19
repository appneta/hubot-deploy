# Description:
#   Deploy wrapper script for Jenkins CI Hubot script
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_DEPLOY_CONFIG
#
#   CONFIG should be in JSON i.e. '{ "foo": {"job": "deploy-foo", "users": ["*"] } }'
#
# Commands:
#   hubot deploy <environment> <branch> - deploys the specified branch to the specified environment
#
# Author:
#   danriti

querystring = require 'querystring'

jenkinsDeploy = (msg, robot) ->
  CONFIG = JSON.parse process.env.HUBOT_DEPLOY_CONFIG

  if not robot.jenkins?.build?
    msg.send "Error: jenkins plugin not installed."
    return

  environment = querystring.escape msg.match[1]
  branch = querystring.escape msg.match[2]
  user = querystring.escape msg.message.user.name

  if environment not of CONFIG
    msg.send "Invalid environment: #{environment}"
    msg.send "Valid environments are: #{(key for key of CONFIG)}"
    return

  job = CONFIG[environment].job
  users = CONFIG[environment].users
  params = "BRANCH=#{branch}"

  if user not in users and '*' not in users
    msg.send "Access denied."
    msg.send "Valid users are: #{(u for u in users)}"
    return

  # monkeypatch the msg.match object
  msg.match[1] = job
  msg.match[3] = params

  robot.jenkins.build(msg)

module.exports = (robot) ->
  robot.respond /deploy ([\w\.\-_]+) (.+)?/i, (msg) ->
    jenkinsDeploy(msg, robot)

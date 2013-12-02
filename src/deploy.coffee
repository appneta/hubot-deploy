# Description:
#   Deploy wrapper script for Jenkins CI Hubot script
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_DEPLOY_ENV
#
#   ENV should be in JSON i.e. '{ "foo": "deploy-foo" }'
#
# Commands:
#   hubot deploy <environment> <branch> - deploys the specified branch to the specified environment
#
# Author:
#   danriti

querystring = require 'querystring'

jenkinsDeploy = (msg, robot) ->
  ENV_TO_JOBS = JSON.parse process.env.HUBOT_DEPLOY_ENV

  if not robot.jenkins?.build?
    msg.send "Error: jenkins plugin not installed."
    return

  environment = querystring.escape msg.match[1]
  branch = querystring.escape msg.match[2]

  if environment not of ENV_TO_JOBS
    msg.send "Invalid environment: #{environment}"
    msg.send "Valid environments are: #{(key for key of ENV_TO_JOBS)}"
    return

  job = ENV_TO_JOBS[environment]
  params = "BRANCH=#{branch}"

  # monkeypatch the msg.match object
  msg.match[1] = job
  msg.match[3] = params

  robot.jenkins.build(msg)

module.exports = (robot) ->
  robot.respond /deploy ([\w\.\-_]+) (.+)?/i, (msg) ->
    jenkinsDeploy(msg, robot)

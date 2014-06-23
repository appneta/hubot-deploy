# Description:
#   Deploy wrapper script for Jenkins CI Hubot script
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_DEPLOY_CONFIG
#
#   CONFIG should be in JSON i.e. '{ "foo": {"job": "deploy-foo", "role": "deploy" } }'
#
#   The "role" field uses the [auth.coffee][1] module for restricting access via user
#   configurable roles. You can set "role" to "*" if you don't care about restricting access.
#
#   [1]: https://github.com/github/hubot-scripts/blob/master/src/scripts/auth.coffee
#
# Commands:
#   hubot deploy <environment> <branch> - deploys the specified branch to the specified environment
#
# Author:
#   danriti

querystring = require 'querystring'

jenkinsDeploy = (msg, robot) ->
  CONFIG = JSON.parse process.env.HUBOT_DEPLOY_CONFIG

  userHasRole = (user, role) ->
    if role is "*"
      return true

    return robot.Auth.hasRole(user, role)

  if not robot.jenkins?.build?
    msg.send "Error: jenkins plugin not installed."
    return

  environment = querystring.escape msg.match[1]
  branch = querystring.escape msg.match[2]
  userName = msg.message.user.name

  if environment not of CONFIG
    msg.send "Invalid environment: #{environment}"
    msg.send "Valid environments are: #{(key for key of CONFIG)}"
    return

  job = CONFIG[environment].job
  role = CONFIG[environment].role
  params = "BRANCH=#{branch}"

  if not userHasRole(userName, role)
     msg.send "Access denied."
     msg.send "You must have this role to use this command: #{role}"
     return

  # monkeypatch the msg.match object
  msg.match[1] = job
  msg.match[3] = params

  robot.jenkins.build(msg)

module.exports = (robot) ->
  robot.respond /deploy ([\w\.\-_]+) (.+)?/i, (msg) ->
    jenkinsDeploy(msg, robot)

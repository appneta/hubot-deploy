# Description:
#   Deploy wrapper script for Jenkins CI Hubot script
#
# Configuration:
#   HUBOT_DEPLOY_CONFIG - A JSON string the describes your deploy configuration.
#
# Commands:
#   hubot deploy <environment> <branch> - deploys the specified branch to the specified environment
#   hubot build <job> <param> - builds the specified job with the specified param
#
# Notes:
#   HUBOT_DEPLOY_CONFIG expects a JSON object structured like this:
#
#   { "foo": {
#       "job": "deploy-foo",
#       "role": "deploy",
#       "param": "BRANCH"
#     }
#   }
#
#   - "foo" (String) Name of the environment/job you want to invoke.
#   - "job" (String) Name of the Jenkins job you want to invoke.
#   - "param" (String) Name of the string parameter passed to the Jenkins job.
#   - "role" (String) (Optional) Uses the [hubot-auth][1] module (requires
#     installation) for restricting access via user configurable roles.
#
#     You can set "role" to "*" if you don't care about restricting access.
#
#   [1]: https://github.com/hubot-scripts/hubot-auth
#
# Author:
#   danriti

querystring = require 'querystring'

module.exports = (robot) ->

  if process.env.HUBOT_DEPLOY_CONFIG?
    CONFIG = JSON.parse process.env.HUBOT_DEPLOY_CONFIG
  else
    robot.logger.warning 'The HUBOT_DEPLOY_CONFIG environment variable is not set'
    CONFIG = {}

  userHasRole = (user, role) ->
    if role is "*" or not robot.auth?.hasRole?
      return true

    return robot.auth.hasRole(user, role)

  jenkinsDeploy = (msg) ->
    if not robot.jenkins?.build?
      msg.send "Error: jenkins plugin not installed."
      return

    environment = querystring.escape msg.match[2]
    branch = querystring.escape msg.match[3]
    user = msg.envelope.user

    if environment not of CONFIG
      msg.send "Invalid environment: #{environment}"
      msg.send "Valid environments are: #{(key for key of CONFIG)}"
      return

    job = CONFIG[environment].job
    role = CONFIG[environment].role
    paramName = CONFIG[environment].param ||= "BRANCH"
    params = "#{paramName}=#{branch}"

    if not userHasRole(user, role)
       msg.send "Access denied."
       msg.send "You must have this role to use this command: #{role}"
       return

    # monkeypatch the msg.match object
    msg.match[1] = job
    msg.match[3] = params

    robot.jenkins.build(msg)

  robot.respond /(deploy|build) ([\w\.\-_]+) (.+)?/i, (msg) ->
    jenkinsDeploy(msg)
# Description:
#   Deploy wrapper script for Jenkins CI Hubot script
#
# Configuration:
#   HUBOT_JENKINS_DEPLOY_CONFIG - Path to a JSON file that describes your deploy configuration (see below).
#
# Commands:
#   hubot deploy <job> <params> - deploy the specified job with the specified param(s)
#   hubot build <job> <params> - build the specified job with the specified param(s)
#   hubot test <job> <params> - test the specified job with the specified param(s)
#
# Notes:
#   HUBOT_JENKINS_DEPLOY_CONFIG expects a valid JSON file that contains a JSON object structured like this:
#
#   {
#     "foo": {
#       "job": "deploy-foo",
#       "role": "deploy",
#       "params": "BRANCH,REGION"
#     },
#     "bar": {
#       "job": "deploy-foo",
#       "role": "*",
#       "params": {
#         "BRANCH": "master",
#         "HOSTS": "host1,host2"
#       }
#     }
#   }
#
#   - "foo" (String) Human readable job you want to invoke.
#   - "job" (String) Name of the Jenkins job you want to invoke.
#   - "params"
#       - (String) Comma seperated string of all the parameter keys
#         to be passed to the Jenkins job.
#       - (Object) Object containing keys of the expected parameters with
#         defaulted values to be passed to the Jenkins job.
#   - "role" (String) (Optional) Uses the [hubot-auth][1] module (requires
#     installation) for restricting access via user configurable roles.
#
#     You can set "role" to "*" if you don't care about restricting access.
#
#   [1]: https://github.com/hubot-scripts/hubot-auth
#
# Author:
#   danriti

fs = require 'fs'

module.exports = (robot) ->

  if process.env.HUBOT_JENKINS_DEPLOY_CONFIG?
    CONFIG = JSON.parse(fs.readFileSync(process.env.HUBOT_JENKINS_DEPLOY_CONFIG, 'utf8'))
  else
    robot.logger.warning 'The HUBOT_JENKINS_DEPLOY_CONFIG environment variable is not set'
    CONFIG = {}

  userHasRole = (user, role) ->
    if role is "*" or not robot.auth?.hasRole?
      return true

    return robot.auth.hasRole(user, role)

  parseUserParams = (params) ->
    if ' ' in params
      return params.split(' ')
    return params.split(',')

  parseParamKeys = (params) ->
    if typeof params is 'object'
      return Object.keys(params)
    if not params
      params = "BRANCH"
    return params.split(',')

  jenkinsDeploy = (msg) ->
    if not robot.jenkins?.build?
      msg.send "Error: jenkins plugin not installed."
      return

    environment = msg.match[2]
    userValues = parseUserParams(msg.match[3])
    user = msg.envelope.user

    if environment not of CONFIG
      msg.send "Invalid environment: #{environment}"
      msg.send "Valid environments are: #{(key for key of CONFIG)}"
      return

    job = CONFIG[environment].job
    role = CONFIG[environment].role
    paramKeys = parseParamKeys(CONFIG[environment].params)
    defaultValues = CONFIG[environment].params

    if not userHasRole(user, role)
       msg.send "Access denied."
       msg.send "You must have this role to use this command: #{role}"
       return

    count = paramKeys.length - 1
    params = ''
    for i in [0..count]
      key = paramKeys[i]
      value = userValues[i] || defaultValues[key]
      params += "#{key}=#{value}"
      if i isnt count
        params += '&'

    # monkeypatch the msg.match object
    msg.match[1] = job
    msg.match[3] = params

    robot.jenkins.build(msg)

  robot.respond /(deploy|build|test)\s+([\w\.\-_]+)\s+(.+)?/i, (msg) ->
    jenkinsDeploy(msg)

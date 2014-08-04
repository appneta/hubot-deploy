# Hubot Jenkins Deploy

Deploy wrapper script for Jenkins CI Hubot script

[![Build Status](https://travis-ci.org/appneta/hubot-jenkins-deploy.png)](https://travis-ci.org/appneta/hubot-jenkins-deploy)

## Installation

Add **hubot-jenkins-deploy** to your `package.json` file:

```json
"dependencies": {
  "hubot": ">= 2.5.1",
  "hubot-scripts": ">= 2.4.2",
  "hubot-deploy": "git://github.com/appneta/hubot-jenkins-deploy.git#master",
  "hubot-hipchat": "~2.5.1-5",
  "ntwitter": "~0.5.0",
  "shellwords": "~0.1.0",
  "bang": "~1.0.4",
  "cheerio": "~0.12.3",
  "moment": "~2.4.0"
}
```

Add **hubot-jenkins-deploy** to your `external-scripts.json`:

```json
["hubot-jenkins-deploy"]
```

Run `npm install`

#!/usr/bin/env groovy

// See https://github.com/capralifecycle/jenkins-pipeline-library
@Library('cals') _

def dockerImageName = '923402097046.dkr.ecr.eu-central-1.amazonaws.com/git-visualized-activity/worker'

def jobProperties = [
  parameters([
    // Add parameter so we can build without using cached image layers.
    booleanParam(
      defaultValue: false,
      description: 'Force build without Docker cache',
      name: 'docker_skip_cache'
    ),
  ]),
]

buildConfig([
  jobProperties: jobProperties,
  slack: [
    channel: '#cals-dev-info',
    teamDomain: 'cals-capra',
  ],
]) {
  dockerNode {
    stage('Checkout source') {
      checkout scm
    }

    def img
    def lastImageId = dockerPullCacheImage(dockerImageName)

    stage('Build Docker image') {
      def args = ""
      if (params.docker_skip_cache) {
        args = " --no-cache"
      }
      img = docker.build(dockerImageName, "--cache-from $lastImageId$args --pull .")
    }

    def isSameImage = dockerPushCacheImage(img, lastImageId)

    if (env.BRANCH_NAME == 'master' && !isSameImage) {
      stage('Push Docker image') {
        milestone 2

        def tagName = sh([
          returnStdout: true,
          script: 'date +%Y%m%d-%H%M'
        ]).trim() + '-' + env.BUILD_NUMBER

        img.push(tagName)
        img.push('latest')
        slackNotify message: "New Docker image available: $dockerImageName:$tagName"
      }
    }
  }
}

#!/usr/bin/env groovy

// See https://github.com/capralifecycle/jenkins-pipeline-library
@Library('cals') _

import no.capraconsulting.buildtools.cdk.EcrPublish
import no.capraconsulting.buildtools.cdk.EcsUpdateImage

def ecrPublish = new EcrPublish()
def ecsUpdateImage = new EcsUpdateImage()

def publishConfig = ecrPublish.config {
  repositoryUri = "001112238813.dkr.ecr.eu-west-1.amazonaws.com/incub-common-builds"
  applicationName = "gva-worker"
  roleArn = "arn:aws:iam::001112238813:role/incub-common-build-artifacts-ci"
}

buildConfig([
  jobProperties: [
    parameters([
      booleanParam(
        defaultValue: false,
        description: "Force deploy even when having cache",
        name: "forceDeploy"
      ),
      booleanParam(
        defaultValue: false,
        description: "Allow this build to override branch check and deploy",
        name: "overrideBranchCheck"
      ),
      ecrPublish.dockerSkipCacheParam(),
    ]),
  ],
  slack: [
    channel: "#cals-dev-info",
    teamDomain: "cals-capra",
  ],
]) {
  def tagName

  dockerNode {
    ecrPublish.withEcrLogin(publishConfig) {
      stage("Checkout source") {
        checkout scm
      }

      def (img, isSameImageAsLast) = ecrPublish.buildImage(publishConfig)

      /* TODO: Add a simple image test later.
      stage("Test build") {
        docker.image("docker").inside {
          sh "./test-image.sh ${img.id}"
        }
      }
      */

      if (!isSameImageAsLast || params.forceDeploy) {
        tagName = ecrPublish.generateLongTag(publishConfig)
        stage("Push Docker image") {
          img.push(tagName)
        }
      }
    }
  }

  /* TODO: Activate later.
  def allowDeploy = env.BRANCH_NAME == "master" || params.overrideBranchCheck
  if (allowDeploy && tagName) {
    stage("Deploy") {
      ecsUpdateImage.deploy {
        milestone1 = 1
        milestone2 = 2
        lockName = "gva-worker-deploy"
        tag = tagName
        deployFunctionArn = "arn:aws:lambda:eu-west-1:001112238813:function:incub-gva-worker-ecs-update-image"
        statusFunctionArn = "arn:aws:lambda:eu-west-1:001112238813:function:incub-gva-worker-ecs-status"
        roleArn = "arn:aws:iam::001112238813:role/incub-gva-worker-ecs-update-image"
      }
    }

    slackNotify message: "Deployed new version of git-visualized-activity-worker ($tagName)"
  }
  */
}

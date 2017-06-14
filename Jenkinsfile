#!groovy

@Library('testutils@stable-41b0bf6')

import org.istio.testutils.Utilities
import org.istio.testutils.GitUtilities

// Utilities shared amongst modules
def gitUtils = new GitUtilities()
def utils = new Utilities()

mainFlow(utils) {
  node {
    gitUtils.initialize()
  }
  // PR on every branch
  if (utils.runStage('PRESUBMIT')) {
    presubmit(gitUtils)
  }
  // Postsubmit from every branch
  if (utils.runStage('POSTSUBMIT')) {
    postsubmit(gitUtils, utils)
  }
}

def checkJekyll() {
  sh('docker run --rm --label=jekyll --volume=\$(pwd):/srv/jekyll ' +
      'jekyll/jekyll sh -c "bundle install && rake test"')
}

def pushDocs(utils) {
  projectId = utils.getParam('FIREBASE_PROJECT_ID')
  release = utils.getParam('MINOR_RELEASE')
  if (projectId == '' || release == '') {
    return
  }
  withEnv("PROJECT_ID=${projectId}", "RELEASE=${release}") {
    withCredentials([string(credentialsId: FIREBASE_TOKEN, variable: 'FIREBASE_TOKEN')]) {
      sh('scripts/build.sh')
    }
  }
}

def presubmit(gitUtils) {
  defaultNode(gitUtils) {
    checkJekyll()
  }
}

def postsubmit(gitUtils, utils) {
  defaultNode(gitUtils) {
    checkJekyll()
    pushDocs(utils)
  }
}


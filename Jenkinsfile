#!groovy

@Library('testutils@stable-41b0bf6')

import org.istio.testutils.Utilities
import org.istio.testutils.GitUtilities
import org.istio.testutils.Bazel

// Utilities shared amongst modules
def gitUtils = new GitUtilities()
def utils = new Utilities()

mainFlow(utils) {
  node {
    gitUtils.initialize()
  }
  defaultNode(gitUtils) {
    sh('docker run --rm --label=jekyll --volume=\$(pwd):/srv/jekyll ' +
        'jekyll/jekyll sh -c "bundle install && rake test"')
  }
}

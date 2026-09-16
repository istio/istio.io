---
title: "Retirement of Kubernetes integration jobs for unsupported Kubernetes versions"
description: Istio's continuous integration will no longer run integration tests against unsupported Kubernetes versions.
publishdate: 2026-09-16
attribution: "Francisco Herrera (Red Hat), Daniel Hawton (solo.io)"
keywords: [Istio, Kubernetes, testing, CI]
---

The Istio Test and Release Working Group is retiring CI integration tests for older Kubernetes versions from the `master` branch, affecting Istio versions 1.32 and newer.

## What's changing

Previously, Istio would have a supported range of Kubernetes versions that were typically N-3 or N-4 of the latest Kubernetes version, but would continue testing older Kubernetes versions. Currently, this means we are testing Kubernetes 1.23 through 1.36.

With [test-infra PR 6048](https://github.com/istio/test-infra/pull/6048), we are removing the tested older Kubernetes versions from testing, limiting our testing to only the supported Kubernetes range. This change is being made to the `master` branch, so will affect Istio versions 1.32 and forward.

## Why we're making this change

These Kubernetes versions are either already end-of-life (EOL) or rapidly approaching it. Upstream Kubernetes supports minor releases for roughly 14 months; see the [Kubernetes releases page](https://kubernetes.io/releases/) for official support status.

Maintaining old node images and running tests against EOL versions consumes valuable CI infrastructure and time. Retiring these jobs allows the working group to focus our testing resources on the actively supported versions that the vast majority of the community runs.

## What this means for you

If you still need to test against these older versions, you can run the integration suite locally using [kind](https://kind.sigs.k8s.io/).

The [`integ-suite-kind.sh`]({{< github_blob >}}/prow/integ-suite-kind.sh) script is the exact entry point our CI uses. You can run it against the Kubernetes version you need by checking the [test-infra](https://github.com/istio/test-infra/blob/master/prow/aws/config/jobs/istio.yaml) commit history for the specific node image and configuration:

{{< text bash >}}
$ prow/integ-suite-kind.sh \
      --node-image kind-node-target-version \
      --kind-config prow/config/mixedlb-service.yaml \
      test.integration.kube
{{< /text >}}

Note: Replace the `--node-image` and `--kind-config` values with the versions previously used in CI for the Kubernetes version you want to test against.

## What's next

You can always check the current set of tested Kubernetes versions for each Istio release in our [support status table](/docs/releases/supported-releases/).

If you have any questions, reach out to the Istio Test and Release Working Group on Slack.

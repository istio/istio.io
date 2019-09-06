---
title: Operator Install [Experimental]
description: Install and configure Istio using the Istio Operator.
weight: 25
keywords: [operator,kubernetes,helm]
---

{{< boilerplate experimental-feature-warning >}}

Follow this guide to install and configure an Istio mesh using an alternate
installation method: the Istio {{<gloss operator>}}Operator{{</gloss>}}
installation.

The Istio Operator installation is a shorter process with the option of
installing Istio using a one-line command. It has user input
validation to help prevent installation errors and customization options to
override any aspect of the configuration.

It has these additional characteristics:

- Descriptive error messages to spot configuration errors easier.

- Installer capable of waiting for Istio pods and services to be in a
  ready state.

- Fewer dependencies (doesn’t require Helm).

The Operator install is accessed via [`istioctl`](/docs/reference/commands/istioctl/)
commands.

## Prerequisites

Before you begin, check the following prerequisites:

1. [Download the Istio release](/docs/setup/#downloading-the-release).
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).
1. Check the [Requirements for Pods and Services](/docs/setup/additional-setup/requirements/).

## Install Istio using the default profile

The simplest option is to install Istio using a one-line command:

{{< text bash >}}
$ istioctl experimental manifest apply
{{< /text >}}

This command installs a profile named `default` on the cluster defined by your
Kubernetes configuration. The `default` profile is smaller and more suitable
for establishing a production environment, unlike the larger profile named
`demo` that is meant to evaluate a broad set of Istio features.

You can view the profile named `default` by using this command:

{{< text bash >}}
$ istioctl experimental profile dump
{{< /text >}}

## Install a different profile

Other Istio configuration profiles can be installed in a cluster using this command:

{{< text bash >}}
$ istioctl experimental manifest apply --set profile=default
{{< /text >}}

In the example above, `default` is one of the profile names from the output of
the `istioctl profile list` command.

## Display the profiles list

You can display the names of Istio configuration profiles that are
accessible to `istioctl` by using this command:

{{< text bash >}}
$ istioctl experimental profile list
{{< /text >}}

Optionally, you can use the `-s` flag with a install package path to see the
list of configuration profiles available for other Istio versions:

{{< text bash >}}
$ istioctl experimental profile list -s installPackagePath=https://github.com/istio/istio/releases/tags/1.3.3
{{< /text >}}

## Inspect/modify a manifest before installation

You can inspect or modify the manifest before installing Istio using these steps:

1. Generate the manifest using this command:

{{< text bash >}}
$ istioctl experimental manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

1. Inspect or modify the manifest as needed.
1. Then, apply the manifest using this command:

{{< tip >}}
This command might show transient errors due to resources not being available in
the cluster in the correct order.
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f $HOME/generated-manifest.yaml
{{< /text >}}

## Verify a successful installation

You can check if the Istio installation succeeded using the `verify-install` command.
This compares the installation on your cluster to a manifest you specify
and displays the results:

{{< text bash >}}
$ istioctl verify-install -f $HOME/generated-manifest.yaml
{{< /text >}}

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

It has the following additional characteristics:

- Descriptive error messages to spot configuration errors easier.

- Installer capable of waiting for Istio pods and services to be in a
  ready state.

- Fewer dependencies (doesn’t require Helm).

The Operator install is accessed via [`istioctl`](/docs/reference/commands/istioctl/)
commands.

## Prerequisites

Before you begin, you must meet the following prerequisites.

1. [Download the Istio release](/docs/setup/#downloading-the-release).
1. Perform any necessary [platform-specific setup](/docs/setup/install/platform/).
1. Check the [Requirements for Pods and
   Services](/docs/setup/additional-setup/requirements/).

## Install Istio using One Line

The simplest option is to install Istio using a one-line command. At the command
prompt, run the following command:

{{< text bash >}}
$ istioctl manifest apply
{{< /text >}}

This command installs a profile named `default` on the cluster defined by your
Kubernetes configuration. The `default` profile is smaller and more suitable
for establishing a production environment, unlike the larger profile named
`demo` that is meant to evaluate a broad set of Istio features.

You can view the profile named `default` by using the following command:

{{< text bash >}}
$ istioctl profile dump
{{< /text >}}

## Install a Different Profile

Other Istio configuration profiles can be installed in a cluster using the
following command:

{{< text bash >}}
$ istioctl manifest apply --set profile=default
{{< /text >}}

where `default` is one of the profile names from the output of the
`istioctl profile list` command.

## Display the Profiles List

You can display the names of Istio configuration profiles that are
accessible to `istioctl` by using the following command:

{{< text bash >}}
$ istioctl profile list
{{< /text >}}

Optionally, you can use the `-s` flag with a install package path to see the
list of configuration profiles available for other Istio versions. At the
command prompt, run the following command:

{{< text bash >}}
$ istioctl profile list -s installPackagePath=https://github.com/istio/istio/releases/tags/1.3.3
{{< /text >}}

## Inspect/Modify a Manifest Before Installation

You can inspect or modify the manifest before installing Istio using the
following steps:

1. At the command prompt, run the following command:

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

1. Inspect or modify the manifest as needed.
1. Then, run the following command:

{{< text bash >}}
$ kubectl apply -f $HOME/generated-manifest.yaml
{{< /text >}}

{{< tip >}}
This option might show transient errors due to resources not being available in
the cluster in the correct order.
{{< /tip >}}

## Verify a Successful Installation

You can check if the installation succeeded by following the steps at
[Verifying the installation](/docs/setup/install/kubernetes/#verifying-the-installation).

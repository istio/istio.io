---
title: Analyze your cluster and local configuration with istioctl analyze
description: Shows you how to use istioctl analyze to identify potential issues with your configuration.
weight: 90
keywords: [istioctl, debugging, kubernetes]
---

{{< boilerplate experimental-feature-warning >}}

`istioctl analyze` is a powerful Istio diagnostic tool that can detect potential issues with your
Istio configuration. It can run against a live cluster or a set of local configuration files.
It can also run against a combination of the two, allowing you to catch problems before you
apply changes to a cluster.

## Getting started in under a minute

Getting started is very simple. First, download the latest `istioctl` into the current folder
using one bash command (downloding the latest version ensure that it will have the most
complete set of analyzers):

{{< tabset cookie-name="platform" >}}

{{< tab name="macOS" cookie-value="macos" >}}
{{< text bash >}}
$ curl https://storage.googleapis.com/istio-build/dev/latest | xargs -I {} curl https://storage.googleapis.com/istio-build/dev/{}/istioctl-{}-osx.tar.gz | tar xvz
{{< /text >}}
{{< /tab >}}

{{< tab name="Linux" cookie-value="linux" >}}
{{< text bash >}}
$ curl https://storage.googleapis.com/istio-build/dev/latest | xargs -I {} curl https://storage.googleapis.com/istio-build/dev/{}/istioctl-{}-linux.tar.gz | tar xvz
{{< /text >}}
{{< /tab >}}

{{< /tabset >}}


Then, run it against your current Kubernetes cluster:

{{< text bash >}}
$ ./istioctl x analyze -k
{{< /text >}}

And that’s it! It’ll give you any recommendations that apply.

For example, if you forgot to enable Istio injection (very common issue), you would get the following warning:

{{< text plain >}}
Warn [IST0102](Namespace/default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection
{{< /text >}}

Note that ‘x’ in the command is because this is currently an experimental feature.

## Analyzing live clusters, local files, or both

The scenario in the ‘getting started’ section is doing analysis on live cluster. But the tool also supports performing analysis of a set of local yaml configuration files, or on a combination of local files and a live cluster.

{{< text bash >}}
$
# Analyze a specific set of local files
$ ./istioctl x analyze a.yaml b.yaml

# Analyze all yaml files in the current folder
$ ./istioctl x analyze *.yaml

# Analyze the current live cluster, simulating the effect of applying additional yaml files
$ ./istioctl x analyze -k a.yaml b.yaml
{{< /text >}}

You can run `./istioctl x analyze --help` to see the full set of options.

## Helping us make improve this tool

This tool works by running a set of analyzers that can each detect a certain set of problems. While we’re working hard to expand the list of analyzers, we don’t necessarily have awareness of all the areas of Istio that can benefit from it.

This is where you come in! If you know of a scenario that could be automatically detected by looking at the cluster configuration, we should write an analyzer for it.

There are two ways you can help us.

### The easy way: just describe the scenario to us

Just open an issue [on the Istio repo](https://github.com/istio/istio/issues) describing your scenario. E.g. something like:

- Look at all the virtual services
- For each, look at their list of gateways
- If some of the gateways don’t exist, produce an error

We already have an analyzer for this specific scenario, so this is just an example to illustrate what we’re looking at.

### The harder (but more rewarding!) way: send a PR for a new analyzer

You should still start with a GitHub issue as above, but then you can look into writing the new analyzer yourself!

Please head over to [this page]({{<github_blob>}}/galley/pkg/config/analysis/README.md) to get started.

## Q&A

### What Istio version does this tool target?

One great thing about it is that it works with any version of Istio, and doesn’t require anything to be installed in the cluster.

In some cases, some of the analyzers will not apply if they are not meaningful with your Istio version. But the analysis will still happen with all analyzers that do apply.

Note that while the `analyze` command works across Istio versions, that is not the case for all other `istioctl` commands. So it is suggested that you download the latest version of `istioctl` in a separate folder for analysis purpose, while you use the one that came with your specific Istio version to run other commands.

### What analyzers are supported today?

We're still working to documenting the analyzers. In the meantime, you can see all the analyzers in the [Istio source]({{<github_blob>}}/galley/pkg/config/analysis/analyzers).

### Can analysis do anything harmful to my cluster?

Analysis never changes configuration state. It is a completely read-only operation and so will never alter the state of a cluster.

### What about analysis that goes beyond configuration?

Today, the analysis is purely based on Kubernetes configuration, but in the future we’d like to expand beyond that. For example, we could allow analyzers to also look at logs to generate recommendations.

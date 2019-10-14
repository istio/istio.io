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
using one bash command (downloading the latest release ensure that it will have the most
complete set of analyzers):

{{< tabset cookie-name="platform" >}}

{{< tab name="Mac" cookie-value="macos" >}}

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

For example, if you forgot to enable Istio injection (a very common issue), you would get the following warning:

{{< text plain >}}
Warn [IST0102](Namespace/default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection
{{< /text >}}

Note that `x` in the command is because this is currently an experimental feature.

## Analyzing live clusters, local files, or both

The scenario in the ‘getting started’ section is doing analysis on live clusters. But the tool also supports performing analysis of a set of local yaml configuration files, or on a combination of local files and a live cluster.

Analyze a specific set of local files:

{{< text bash >}}
$ ./istioctl x analyze a.yaml b.yaml
{{< /text >}}

Analyze all yaml files in the current folder:

{{< text bash >}}
$ ./istioctl x analyze *.yaml
{{< /text >}}

Analyze all yaml files in the current folder:

{{< text bash >}}
$ ./istioctl x analyze *.yaml
{{< /text >}}

You can run `./istioctl x analyze --help` to see the full set of options.

## Helping us improve this tool

We're constantly adding more analysis capability and we'd love your help in identifying more use cases.
If you've discovered some Istio configuration "gotcha", some tricky situation that caused you some
problems, open an issue and let us know. We might be able to automatically flag this problem so that
others can discover and avoid the problem in the first place.

To do this, [open an issue](https://github.com/istio/istio/issues) describing your scenario. For example:

- Look at all the virtual services
- For each, look at their list of gateways
- If some of the gateways don’t exist, produce an error

We already have an analyzer for this specific scenario, so this is just an example to illustrate what
the kind of information you should provide.

## Q&A

### What Istio release does this tool target?

Analysis works with any version of Istio, and doesn’t require anything to be installed in the cluster. You just need to get a recent version of `istioctl`.

In some cases, some of the analyzers will not apply if they are not meaningful with your Istio release. But the analysis will still happen with all analyzers that do apply.

Note that while the `analyze` command works across Istio releases, that is not the case for all other `istioctl` commands. So it is suggested that you download the latest release of `istioctl` in a separate folder for analysis purpose, while you use the one that came with your specific Istio release to run other commands.

### What analyzers are supported today?

We're still working to documenting the analyzers. In the meantime, you can see all the analyzers in the [Istio source]({{<github_blob>}}/galley/pkg/config/analysis/analyzers).

### Can analysis do anything harmful to my cluster?

Analysis never changes configuration state. It is a completely read-only operation and so will never alter the state of a cluster.

### What about analysis that goes beyond configuration?

Today, the analysis is purely based on Kubernetes configuration, but in the future we’d like to expand beyond that. For example, we could allow analyzers to also look at logs to generate recommendations.

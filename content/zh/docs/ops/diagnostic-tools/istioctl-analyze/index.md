---
title: Diagnose your Configuration with Istioctl Analyze
description: Shows you how to use istioctl analyze to identify potential issues with your configuration.
weight: 40
keywords: [istioctl, debugging, kubernetes]
---

{{< boilerplate experimental-feature-warning >}}

`istioctl analyze` is a powerful Istio diagnostic tool that can detect potential issues with your
Istio configuration. It can run against a live cluster or a set of local configuration files.
It can also run against a combination of the two, allowing you to catch problems before you
apply changes to a cluster.

## Getting started in under a minute

Getting started is very simple. First, download the latest `istioctl` into the current folder
using one command (downloading the latest release ensure that it will have the most
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
Warn [IST0102](Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection
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

Simulate applying the files in the current folder to the current cluster:

{{< text bash >}}
$ ./istioctl x analyze -k *.yaml
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

- **What Istio release does this tool target?**

      Analysis works with any version of Istio, and doesn’t require anything to be installed in the cluster. You just need to get a recent version of `istioctl`.

      In some cases, some of the analyzers will not apply if they are not meaningful with your Istio release. But the analysis will still happen with all analyzers that do apply.

      Note that while the `analyze` command works across Istio releases, that is not the case for all other `istioctl` commands. So it is suggested that you download the latest release of `istioctl` in a separate folder for analysis purpose, while you use the one that came with your specific Istio release to run other commands.

- **What analyzers are supported today?**

      We're still working to documenting the analyzers. In the meantime, you can see all the analyzers in the [Istio source]({{<github_blob>}}/galley/pkg/config/analysis/analyzers).

- **Can analysis do anything harmful to my cluster?**

      Analysis never changes configuration state. It is a completely read-only operation and so will never alter the state of a cluster.

- **What about analysis that goes beyond configuration?**

      Today, the analysis is purely based on Kubernetes configuration, but in the future we’d like to expand beyond that. For example, we could allow analyzers to also look at logs to generate recommendations.

- **Where can I find out how to fix the errors I'm getting?**

      The set of [configuration analysis messages](/zh/docs/reference/config/analysis/) contains descriptions of each message along with suggested fixes.

## Enabling validation messages for resource status

{{< boilerplate experimental-feature-warning >}}

Starting with Istio 1.4, Galley can be set up to perform configuration analysis alongside the configuration distribution that it is primarily responsible for, via the `galley.enableAnalysis` flag.
This analysis uses the same logic and error messages as when using `istioctl analyze`. Validation messages from the analysis are written to the status subresource of the affected Istio resource.

For example. if you have a misconfigured gateway on your "ratings" virtual service, running `kubectl get virtualservice ratings` would give you something like:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"networking.istio.io/v1alpha3","kind":"VirtualService","metadata":{"annotations":{},"name":"ratings","namespace":"default"},"spec":{"hosts":["ratings"],"http":[{"route":[{"destination":{"host":"ratings","subset":"v1"}}]}]}}
  creationTimestamp: "2019-09-04T17:31:46Z"
  generation: 11
  name: ratings
  namespace: default
  resourceVersion: "12760039"
  selfLink: /apis/networking.istio.io/v1alpha3/namespaces/default/virtualservices/ratings
  uid: dec86702-cf39-11e9-b803-42010a8a014a
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
status:
  validationMessages:
  - code: IST0101
    level: Error
    message: 'Referenced gateway not found: "bogus-gateway"'
{{< /text >}}

`enableAnalysis` runs in the background, and will keep the status field of a resource up to date with its current validation status. Note that this isn't a replacement for `istioctl analyze`:

- Not all resources have a custom status field (e.g. Kubernetes `namespace` resources), so messages attached to those resources won't show validation messages.
- `enableAnalysis` only works on Istio versions starting with 1.4, while `istioctl analyze` can be used with older versions.
- While it makes it easy to see what's wrong with a particular resource, it's harder to get a holistic view of validation status in the mesh.

You can enable this feature with:

{{< text bash >}}
$ istioctl manifest apply --set values.galley.enableAnalysis=true
{{< /text >}}

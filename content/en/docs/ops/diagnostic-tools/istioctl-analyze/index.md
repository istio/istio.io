---
title: Diagnose your Configuration with Istioctl Analyze
description: Shows you how to use istioctl analyze to identify potential issues with your configuration.
weight: 40
keywords: [istioctl, debugging, kubernetes]
owner: istio/wg-user-experience-maintainers
test: yes
---

`istioctl analyze` is a diagnostic tool that can detect potential issues with your
Istio configuration. It can run against a live cluster or a set of local configuration files.
It can also run against a combination of the two, allowing you to catch problems before you
apply changes to a cluster.

## Getting started in under a minute

You can analyze your current live Kubernetes cluster by running:

{{< text syntax=bash snip_id=analyze_all_namespaces >}}
$ istioctl analyze --all-namespaces
{{< /text >}}

And that’s it! It’ll give you any recommendations that apply.

For example, if you forgot to enable Istio injection (a very common issue), you would get the following 'Info' message:

{{< text syntax=plain snip_id=analyze_all_namespace_sample_response >}}
Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

Fix the issue:

{{< text syntax=bash snip_id=fix_default_namespace >}}
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

Then try again:

{{< text syntax=bash snip_id=try_with_fixed_namespace >}}
$ istioctl analyze --namespace default
✔ No validation issues found when analyzing namespace: default.
{{< /text >}}

## Analyzing live clusters, local files, or both

Analyze the current live cluster, simulating the effect of applying additional yaml files like `bookinfo-gateway.yaml` and `destination-rule-all.yaml` in the `samples/bookinfo/networking` directory:

{{< text syntax=bash snip_id=analyze_sample_destrule >}}
$ istioctl analyze @samples/bookinfo/networking/bookinfo-gateway.yaml@ @samples/bookinfo/networking/destination-rule-all.yaml@
Error [IST0101] (Gateway default/bookinfo-gateway samples/bookinfo/networking/bookinfo-gateway.yaml:9) Referenced selector not found: "istio=ingressgateway"
Error [IST0101] (VirtualService default/bookinfo samples/bookinfo/networking/bookinfo-gateway.yaml:41) Referenced host not found: "productpage"
Error: Analyzers found issues when analyzing namespace: default.
See https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}

Analyze the entire `networking` folder:

{{< text syntax=bash snip_id=analyze_networking_directory >}}
$ istioctl analyze samples/bookinfo/networking/
{{< /text >}}

Analyze all yaml files in the `networking` folder:

{{< text syntax=bash snip_id=analyze_all_networking_yaml >}}
$ istioctl analyze samples/bookinfo/networking/*.yaml
{{< /text >}}

The above examples are doing analysis on a live cluster. The tool also supports performing analysis of a set of local Kubernetes yaml configuration files,
or on a combination of local files and a live cluster. When analyzing a set of local files, the file-set is expected to be fully self-contained.
Typically, this is used to analyze the entire set of configuration files that are intended to be deployed to a cluster. To use this feature, simply add the `--use-kube=false` flag.

Analyze all yaml files in the `networking` folder:

{{< text syntax=bash snip_id=analyze_all_networking_yaml_no_kube >}}
$ istioctl analyze --use-kube=false samples/bookinfo/networking/*.yaml
{{< /text >}}

You can run `istioctl analyze --help` to see the full set of options.

## Advanced

### Enabling validation messages for resource status

{{< boilerplate experimental-feature-warning >}}

Starting with Istio 1.5, Galley can be set up to perform configuration analysis alongside the configuration distribution that it is primarily responsible for, via the `istiod.enableAnalysis` flag.
This analysis uses the same logic and error messages as when using `istioctl analyze`. Validation messages from the analysis are written to the status subresource of the affected Istio resource.

For example. if you have a misconfigured gateway on your "ratings" virtual service, running `kubectl get virtualservice ratings` would give you something like:

{{< text syntax=yaml snip_id=vs_yaml_with_status >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
...
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
...
status:
  observedGeneration: "1"
  validationMessages:
  - documentationUrl: https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis/ist0101/
    level: ERROR
    type:
      code: IST0101
{{< /text >}}

`enableAnalysis` runs in the background, and will keep the status field of a resource up to date with its current validation status. Note that this isn't a replacement for `istioctl analyze`:

- Not all resources have a custom status field (e.g. Kubernetes `namespace` resources), so messages attached to those resources won't show validation messages.
- `enableAnalysis` only works on Istio versions starting with 1.5, while `istioctl analyze` can be used with older versions.
- While it makes it easy to see what's wrong with a particular resource, it's harder to get a holistic view of validation status in the mesh.

You can enable this feature with:

{{< text syntax=bash snip_id=install_with_custom_config_analysis >}}
$ istioctl install --set values.global.istiod.enableAnalysis=true
{{< /text >}}

### Ignoring specific analyzer messages via CLI

Sometimes you might find it useful to hide or ignore analyzer messages in certain cases. For example, imagine a situation where a message is emitted about a resource you don't have permissions to update:

{{< text syntax=bash snip_id=analyze_k_frod >}}
$ istioctl analyze -k --namespace frod
Info [IST0102] (Namespace frod) The namespace is not enabled for Istio injection. Run 'kubectl label namespace frod istio-injection=enabled' to enable it, or 'kubectl label namespace frod istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

Because you don't have permissions to update the namespace, you cannot resolve the message by annotating the namespace. Instead, you can direct `istioctl analyze` to suppress the above message on the resource:

{{< text syntax=bash snip_id=analyze_suppress0102 >}}
$ istioctl analyze -k --namespace frod --suppress "IST0102=Namespace frod"
✔ No validation issues found when analyzing namespace: frod.
{{< /text >}}

The syntax used for suppression is the same syntax used throughout `istioctl` when referring to resources: `<kind> <name>.<namespace>`, or just `<kind> <name>` for cluster-scoped resources like `Namespace`. If you want to suppress multiple objects, you can either repeat the `--suppress` argument or use wildcards:

{{< text syntax=bash snip_id=analyze_suppress_frod_0107_baz >}}
$ # Suppress code IST0102 on namespace frod and IST0107 on all pods in namespace baz
$ istioctl analyze -k --all-namespaces --suppress "IST0102=Namespace frod" --suppress "IST0107=Pod *.baz"
{{< /text >}}

### Ignoring specific analyzer messages via annotations

You can also ignore specific analyzer messages using an annotation on the resource. For example, to ignore code IST0107 (`MisplacedAnnotation`) on resource `deployment/my-deployment`:

{{< text syntax=bash snip_id=annotate_for_deployment_suppression >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107
{{< /text >}}

To ignore multiple codes for a resource, separate each code with a comma:

{{< text syntax=bash snip_id=annotate_for_deployment_suppression_107 >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107,IST0002
{{< /text >}}

## Helping us improve this tool

We're continuing to add more analysis capability and we'd love your help in identifying more use cases.
If you've discovered some Istio configuration "gotcha", some tricky situation that caused you some
problems, open an issue and let us know. We might be able to automatically flag this problem so that
others can discover and avoid the problem in the first place.

To do this, [open an issue](https://github.com/istio/istio/issues) describing your scenario. For example:

- Look at all the virtual services
- For each, look at their list of gateways
- If some of the gateways don’t exist, produce an error

We already have an analyzer for this specific scenario, so this is just an example to illustrate what
kind of information you should provide.

## Q&A

- **What Istio release does this tool target?**

    Like other `istioctl` tools, we generally recommend using a downloaded version that matches the version deployed in your cluster.

    For the time being, analysis is generally backwards compatible, so that you can, for example, run the {{< istio_version >}} version of `istioctl analyze` against a cluster running an older Istio 1.x version and expect to get useful feedback. Analysis rules that are not meaningful with an older Istio release will be skipped.

    If you decide to use the latest `istioctl` for analysis purposes on a cluster running an older Istio version, we suggest that you keep it in a separate folder from the version of the binary used to manage your deployed Istio release.

- **What analyzers are supported today?**

    We're still working to documenting the analyzers. In the meantime, you can see all the analyzers in the [Istio source]({{< github_tree >}}/pkg/config/analysis/analyzers).

    You can also see what [configuration analysis messages](/docs/reference/config/analysis/)
    are supported to get an idea of what is currently covered.

- **Can analysis do anything harmful to my cluster?**

    Analysis never changes configuration state. It is a completely read-only operation that will never alter the state of a cluster.

- **What about analysis that goes beyond configuration?**

    Today, the analysis is purely based on Kubernetes configuration, but in the future we’d like to expand beyond that. For example, we could allow analyzers to also look at logs to generate recommendations.

- **Where can I find out how to fix the errors I'm getting?**

    The set of [configuration analysis messages](/docs/reference/config/analysis/) contains descriptions of each message along with suggested fixes.

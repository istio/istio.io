---
title: FAQ
overview: Common issues, known limitations and work arounds, and other frequently asked questions on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

## How do I see all of the configuration for Mixer ?

Configuration for *instances*, *handlers*, and *rules* is stored as Kubernetes
[Custom
Resources](https://kubernetes.io/docs/concepts/api-extension/custom-resources/).
Configuration may be accessed by using `kubectl` to query the Kubernetes [API
server](https://kubernetes.io/docs/admin/kube-apiserver/) for the resources.

### Rules

To see the list of all rules, execute the following:

```
kubectl get rules --all-namespaces
```

Output will be similar to:

```
NAMESPACE      NAME        KIND
default        mongoprom   rule.v1alpha2.config.istio.io
istio-system   promhttp    rule.v1alpha2.config.istio.io
istio-system   promtcp     rule.v1alpha2.config.istio.io
istio-system   stdio       rule.v1alpha2.config.istio.io
```

To see an individual rule configuration, execute the following:

```
kubectl -n <namespace> get rules <name> -o yaml
```

### Handlers

Handlers are defined based on Kubernetes [Custom Resource
Definitions](https://kubernetes.io/docs/concepts/api-extension/custom-resources/#customresourcedefinitions)
for adapters.

First, identify the list of adapter kinds:

```
kubectl get crd -listio=mixer-adapter
```

The output will be similar to:

```
NAME                           KIND
deniers.config.istio.io        CustomResourceDefinition.v1beta1.apiextensions.k8s.io
listcheckers.config.istio.io   CustomResourceDefinition.v1beta1.apiextensions.k8s.io
memquotas.config.istio.io      CustomResourceDefinition.v1beta1.apiextensions.k8s.io
noops.config.istio.io          CustomResourceDefinition.v1beta1.apiextensions.k8s.io
prometheuses.config.istio.io   CustomResourceDefinition.v1beta1.apiextensions.k8s.io
stackdrivers.config.istio.io   CustomResourceDefinition.v1beta1.apiextensions.k8s.io
statsds.config.istio.io        CustomResourceDefinition.v1beta1.apiextensions.k8s.io
stdios.config.istio.io         CustomResourceDefinition.v1beta1.apiextensions.k8s.io
svcctrls.config.istio.io       CustomResourceDefinition.v1beta1.apiextensions.k8s.io
```

Then, for each adapter kind in that list, issue the following command:

```
kubectl get <adapter kind name> --all-namespaces
```

Output for `stdios` will be similar to:

```
NAMESPACE      NAME      KIND
istio-system   handler   stdio.v1alpha2.config.istio.io
```

To see an individual handler configuration, execute the following:

```
kubectl -n <namespace> get <adapter kind name> <name> -o yaml
```


### Instances

Instances are defined according to Kubernetes [Custom Resource
Definitions](https://kubernetes.io/docs/concepts/api-extension/custom-resources/#customresourcedefinitions)
for instances.

First, identify the list of instance kinds:

```
kubectl get crd -listio=mixer-instance
```

The output will be similar to:

```
NAME                             KIND
checknothings.config.istio.io    CustomResourceDefinition.v1beta1.apiextensions.k8s.io
listentries.config.istio.io      CustomResourceDefinition.v1beta1.apiextensions.k8s.io
logentries.config.istio.io       CustomResourceDefinition.v1beta1.apiextensions.k8s.io
metrics.config.istio.io          CustomResourceDefinition.v1beta1.apiextensions.k8s.io
quotas.config.istio.io           CustomResourceDefinition.v1beta1.apiextensions.k8s.io
reportnothings.config.istio.io   CustomResourceDefinition.v1beta1.apiextensions.k8s.io
```

Then, for each instance kind in that list, issue the following command:

```
kubectl get <instance kind name> --all-namespaces
```

Output for `metrics` will be similar to:

```
NAMESPACE      NAME                 KIND
default        mongoreceivedbytes   metric.v1alpha2.config.istio.io
default        mongosentbytes       metric.v1alpha2.config.istio.io
istio-system   requestcount         metric.v1alpha2.config.istio.io
istio-system   requestduration      metric.v1alpha2.config.istio.io
istio-system   requestsize          metric.v1alpha2.config.istio.io
istio-system   responsesize         metric.v1alpha2.config.istio.io
istio-system   tcpbytereceived      metric.v1alpha2.config.istio.io
istio-system   tcpbytesent          metric.v1alpha2.config.istio.io
```

To see an individual instance configuration, execute the following:

```
kubectl -n <namespace> get <instance kind name> <name> -o yaml
```

## What is the full set of attribute expressions supported by Mixer ?

Please see the [Expression Language
Reference]({{home}}/docs/reference/config/mixer/expression-language.html) for
the full set of supported attribute expressions.

## Does Mixer provide any self-monitoring ?

Mixer provides self-monitoring in the form of debug endpoints, Prometheus
metrics, access and application logs, and generated trace data for all requests.

### Mixer monitoring

Mixer exposes an monitoring endpoint(default port: `9093`). There are a few
useful paths that can be used to investigate Mixer performance and audit
function:

- `/metrics` provides Prometheus metrics on the Mixer process as well as gRPC
  metrics related to API calls and metrics on adapter dispatch.
- `/debug/pprof` provides an endpoint for profiling data in [pprof
  format](https://golang.org/pkg/net/http/pprof/).
- `/debug/vars` provides an endpoint exposing server metrics in JSON format.

### Mixer logs

Mixer logs can be accessed via a `kubectl logs` command, as follows:

```
kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=mixer -o jsonpath='{.items[0].metadata.name}') mixer
```

### Mixer traces

Mixer trace generation is controlled by the command-line flag `traceOutput`. If
the flag value is set to `STDOUT` or `STDERR` trace data will be written
directly to those locations. If a URL is provided, Mixer will post
Zipkin-formatted data to that endpoint (example:
`http://zipkin:9411/api/v1/spans`).

In the 0.2 release, Mixer only supports Zipkin tracing.


## How can I write a custom adapter for Mixer ?

To implement a new adapter for Mixer, please refer to the [Adapter Developer's
Guide](https://github.com/istio/mixer/blob/master/doc/dev/adapters.md).
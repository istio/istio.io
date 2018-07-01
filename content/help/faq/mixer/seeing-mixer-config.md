---
title: How do I see all Mixer's configuration?
weight: 10
---

Configuration for *instances*, *handlers*, and *rules* is stored as Kubernetes
[Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/).
Configuration may be accessed by using `kubectl` to query the Kubernetes
API server for the resources.

## Rules

To see the list of all rules, execute the following:

{{< text bash >}}
$ kubectl get rules --all-namespaces
NAMESPACE      NAME        KIND
default        mongoprom   rule.v1alpha2.config.istio.io
istio-system   promhttp    rule.v1alpha2.config.istio.io
istio-system   promtcp     rule.v1alpha2.config.istio.io
istio-system   stdio       rule.v1alpha2.config.istio.io
{{< /text >}}

To see an individual rule configuration, execute the following:

{{< text bash >}}
$ kubectl -n <namespace> get rules <name> -o yaml
{{< /text >}}

## Handlers

Handlers are defined based on Kubernetes [Custom Resource
Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
for adapters.

First, identify the list of adapter kinds:

{{< text bash >}}
$ kubectl get crd -listio=mixer-adapter
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
{{< /text >}}

Then, for each adapter kind in that list, issue the following command:

{{< text bash >}}
$ kubectl get <adapter kind name> --all-namespaces
{{< /text >}}

Output for `stdios` will be similar to:

{{< text plain >}}
NAMESPACE      NAME      KIND
istio-system   handler   stdio.v1alpha2.config.istio.io
{{< /text >}}

To see an individual handler configuration, execute the following:

{{< text bash >}}
$ kubectl -n <namespace> get <adapter kind name> <name> -o yaml
{{< /text >}}

## Instances

Instances are defined according to Kubernetes [Custom Resource
Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
for instances.

First, identify the list of instance kinds:

{{< text bash >}}
$ kubectl get crd -listio=mixer-instance
NAME                             KIND
checknothings.config.istio.io    CustomResourceDefinition.v1beta1.apiextensions.k8s.io
listentries.config.istio.io      CustomResourceDefinition.v1beta1.apiextensions.k8s.io
logentries.config.istio.io       CustomResourceDefinition.v1beta1.apiextensions.k8s.io
metrics.config.istio.io          CustomResourceDefinition.v1beta1.apiextensions.k8s.io
quotas.config.istio.io           CustomResourceDefinition.v1beta1.apiextensions.k8s.io
reportnothings.config.istio.io   CustomResourceDefinition.v1beta1.apiextensions.k8s.io
{{< /text >}}

Then, for each instance kind in that list, issue the following command:

{{< text bash >}}
$ kubectl get <instance kind name> --all-namespaces
{{< /text >}}

Output for `metrics` will be similar to:

{{< text plain >}}
NAMESPACE      NAME                 KIND
default        mongoreceivedbytes   metric.v1alpha2.config.istio.io
default        mongosentbytes       metric.v1alpha2.config.istio.io
istio-system   requestcount         metric.v1alpha2.config.istio.io
istio-system   requestduration      metric.v1alpha2.config.istio.io
istio-system   requestsize          metric.v1alpha2.config.istio.io
istio-system   responsesize         metric.v1alpha2.config.istio.io
istio-system   tcpbytereceived      metric.v1alpha2.config.istio.io
istio-system   tcpbytesent          metric.v1alpha2.config.istio.io
{{< /text >}}

To see an individual instance configuration, execute the following:

{{< text bash >}}
$ kubectl -n <namespace> get <instance kind name> <name> -o yaml
{{< /text >}}

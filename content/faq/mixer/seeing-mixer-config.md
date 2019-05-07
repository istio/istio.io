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
NAMESPACE      NAME                     AGE
istio-system   kubeattrgenrulerule      20h
istio-system   promhttp                 20h
istio-system   promtcp                  20h
istio-system   stdiohttp                20h
istio-system   stdiotcp                 20h
istio-system   tcpkubeattrgenrulerule   20h
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
NAME                              AGE
adapters.config.istio.io          20h
bypasses.config.istio.io          20h
circonuses.config.istio.io        20h
deniers.config.istio.io           20h
fluentds.config.istio.io          20h
kubernetesenvs.config.istio.io    20h
listcheckers.config.istio.io      20h
memquotas.config.istio.io         20h
noops.config.istio.io             20h
opas.config.istio.io              20h
prometheuses.config.istio.io      20h
rbacs.config.istio.io             20h
servicecontrols.config.istio.io   20h
signalfxs.config.istio.io         20h
solarwindses.config.istio.io      20h
stackdrivers.config.istio.io      20h
statsds.config.istio.io           20h
stdios.config.istio.io            20h
{{< /text >}}

Then, for each adapter kind in that list, issue the following command:

{{< text bash >}}
$ kubectl get <adapter kind name> --all-namespaces
{{< /text >}}

Output for `stdios` will be similar to:

{{< text plain >}}
NAMESPACE      NAME      AGE
istio-system   handler   20h
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
NAME                                    AGE
apikeys.config.istio.io                 20h
authorizations.config.istio.io          20h
checknothings.config.istio.io           20h
edges.config.istio.io                   20h
instances.config.istio.io               20h
kuberneteses.config.istio.io            20h
listentries.config.istio.io             20h
logentries.config.istio.io              20h
metrics.config.istio.io                 20h
quotas.config.istio.io                  20h
reportnothings.config.istio.io          20h
servicecontrolreports.config.istio.io   20h
tracespans.config.istio.io              20h
{{< /text >}}

Then, for each instance kind in that list, issue the following command:

{{< text bash >}}
$ kubectl get <instance kind name> --all-namespaces
{{< /text >}}

Output for `metrics` will be similar to:

{{< text plain >}}
NAMESPACE      NAME              AGE
istio-system   requestcount      20h
istio-system   requestduration   20h
istio-system   requestsize       20h
istio-system   responsesize      20h
istio-system   tcpbytereceived   20h
istio-system   tcpbytesent       20h
{{< /text >}}

To see an individual instance configuration, execute the following:

{{< text bash >}}
$ kubectl -n <namespace> get <instance kind name> <name> -o yaml
{{< /text >}}

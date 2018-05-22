---
title: Per-service mutual TLS authentication control
overview: This task shows how to change mutual TLS authentication for a single service.

order: 50

layout: docs
type: markdown
---
{% include home.html %}

> If you are using Istio 0.7 or later, please refer to [authentication policy task]({{home}}/docs/tasks/security/authn-policy.html) for alternative (recommended) solution using authentication policy.

In the [Installation guide]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps), we show how to enable [mutual TLS authentication]({{home}}/docs/concepts/security/mutual-tls.html) between sidecars. The settings will be applied to all sidecars in the mesh.

In this task, you will learn:

* Annotate Kubernetes service to disable (or enable) mutual TLS authentication for a selective service(s).
* Modify Istio mesh config to exclude mutual TLS authentication for control services.

## Before you begin

* Understand Istio [mutual TLS authentication]({{home}}/docs/concepts/security/mutual-tls.html) concepts and [authentication policy]({{home}}/docs/concepts/security/authn-policy.html)

* Familiar with [testing Istio mutual TLS authentication]({{home}}/docs/tasks/security/mutual-tls.html).

* Install Istio with mutual TLS authentication by following the instructions in the [Installation guide]({{home}}/docs/setup/kubernetes/).

* Start [httpbin demo](https://github.com/istio/istio/tree/master/samples/httpbin) with Istio sidecar. Also, for testing purpose, run two instances of [sleep](https://github.com/istio/istio/tree/master/samples/sleep), one with sidecar and one without (in different namespace). Below are commands to help you start these services.

```bash
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)

kubectl create ns legacy && kubectl apply -f samples/sleep/sleep.yaml -n legacy
```

In this initial setup, we expect the sleep instance in default namespace can talk to httpbin service, but the one in legacy namespace cannot, as it doesn't have sidecar to facilitate mTLS.

```bash
kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl http://httpbin.default:8000/ip -s
```

```json
{
  "origin": "127.0.0.1"
}
```

```bash
kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n legacy) -n legacy -- curl http://httpbin.default:8000/ip -s
```

```xxx
command terminated with exit code 56
```

## Disable mutual TLS authentication for httpbin

If we want to disable mTLS only for httpbin (on port 8000), without changing the mesh authentication settings,
we can do that by adding this annotations to the httpbin service definition.

```xxx
annotations:
  auth.istio.io/8000: NONE
```

For a quick test, run `kubectl edit svc httpbin` and add the annotations above (
or you can edit the original httpbin.yaml file and re-apply it). After the change is applied, request from sleep.legacy should now success, as the result of mTLS was dropped.

Note:

* The annotations can be used in the opposite direction, i.e enable mTLS for a service, simply by using annotation value  `MUTUAL_TLS`, instead of `NONE`. People can use this option to enable mTLS on selected services instead of enable it for the whole mesh.

* Annotations can also be used for a (server) service that *does not have sidecar*, to instruct Istio do not apply mTLS for the client when making a call to that service. In fact, if a system has some services that are not managed by Istio (i.e without sidecar), this is a recommended solution to fix communication problem with those services.

## Disable mutual TLS authentication for control services

As we cannot annotate control services, such as API server, in Istio 0.3, we introduced [mtls_excluded_services](https://github.com/istio/api/blob/master/mesh/v1alpha1/config.proto#L200:19) to the mesh configuration to specify the list of services for which mTLS should not be used. If your application needs to communicate to any control service, it's fully-qualified domain name should be listed there.

In the part of the demo, we will show the impact of this field.

By default (0.3 or later), this list contains `kubernetes.default.svc.cluster.local` (which is the name of the API server service in common setup). You can verify it by running this command:

```bash
kubectl get configmap -n istio-system istio -o yaml | grep mtlsExcludedServices
```

```bash
mtlsExcludedServices: ["kubernetes.default.svc.cluster.local"]
```

It's then expected that request to kubernetes.default service should be possible:

```bash
kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl https://kubernetes.default:443/api/ -k -s
```

```json
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "104.199.122.14"
    }
  ]
}
```

Now, run `kubectl edit configmap istio -n istio-system` and clear `mtlsExcludedServices` and restart Pilot after done:

```bash
kubectl get pod $(kubectl get pod -l istio=pilot -n istio-system -o jsonpath={.items..metadata.name}) -n istio-system -o yaml | kubectl replace --force -f -
```

The same test request above now fail with code 35, as sleep's sidecar starts using mTLS again:

```bash
kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl https://kubernetes.default:443/api/ -k -s
```

```xxx
command terminated with exit code 35
```

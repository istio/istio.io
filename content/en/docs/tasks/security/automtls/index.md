---
title: Automatic mutual TLS
description: A simplified workflow to adopt mutual TLS with minimal configuration overhead.
weight: 10
keywords: [security,mtls,ux]
---

This tasks shows a simplified workflow for mutual TLS adoption[authentication overview](/docs/concepts/security/#authentication).

With Istio auto mutual TLS feature, you can adopt mutual TLS by only configuring Authentication Policy without worrying about destination rule.

Istio tracks the server workloads are migrated to Istio sidecar, and configure client sidecar to send mutual TLS traffic to those workloads automatically, and send plain text traffic to workloads
without sidecars. This allows you to adopt Istio mutual TLS incrementally with minimal manual configuration.

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed (e.g use `install/kubernetes/istio-demo.yaml` as described in
[installation steps](/docs/setup/install/kubernetes/#installation-steps), set `global.mtls.enabled` to false  and `global.mtls.auto` to true using [Helm](/docs/setup/install/helm/)). For example,

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system  \
  --set global.mtls.enabled=false  --set global.mtls.auto=true \
  --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl apply -f -
{{< /text >}}

## Instructions

### Setup

Our examples use three namespaces, `foo`, `mixed`, and `legacy`. 

Each namespace we deploy `httpbin` and `sleep`.

All workloads in `foo` namespace have sidecar.

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
{{< /text >}}

Some workloads in `mixed` have sidecar and some don't. 

{{< text bash >}}
$ kubectl create ns mixed
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n mixed
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n mixed
$ cat <<EOF | kubectl apply -n mixed -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: httpbin
        version: nosidecar
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF
{{< /text >}}

None of the workloads in `legacy` have sidecar.

{{< text bash >}}
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

You can confirm the deployments in all namespaces.

{{< text bash >}}
$ kubectl get pods -n foo
$ kubectl get pods -n mixed
$ kubectl get pods -n legacy
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-dcd949489-5cndk   2/2     Running   0          39s
sleep-58d6644d44-gb55j    2/2     Running   0          38s
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-6f6fc94fb6-8d62h   1/1     Running   0          10s
httpbin-dcd949489-5fsbs    2/2     Running   0          12s
sleep-58d6644d44-zmv8w     2/2     Running   0          11s
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-54f5bb4957-lzxlg   1/1     Running   0          6s
sleep-74564b477b-vb6h4     1/1     Running   0          4s
{{< /text >}}

You should also verify that there is a default mesh authentication policy in the system, which you can do as follows:

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
NAMESPACE      NAME                          AGE
istio-system   grafana-ports-mtls-disabled   5m
{{< /text >}}

{{< text bash >}}
$ kubectl get meshpolicies.authentication.istio.io
NAME      AGE
default   3m
{{< /text >}}

Last but not least, verify that there are no destination rules that apply on the example services. You can do this by checking the `host:` value of
 existing destination rules and make sure they do not match. For example:

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
    host: istio-policy.istio-system.svc.cluster.local
    host: istio-telemetry.istio-system.svc.cluster.local
{{< /text >}}

You can verify setup by sending an HTTP request with `curl` from any `sleep` pod in the namespace `foo`, `mixed` or `legacy` to either `httpbin.foo`, `httpbin.mixed` or `httpbin.legacy`. All requests should succeed with HTTP code 200.

For example, here is a command to check `sleep.mixed` to `httpbin.foo` reachability:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n mixed -o jsonpath={.items..metadata.name}) -c sleep -n mixed -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

This one-liner command conveniently iterates through all reachability combinations:

{{< text bash >}}
$ for from in "foo" "mixed" "legacy"; do for to in "foo" "mixed" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.mixed: 200
sleep.foo to httpbin.legacy: 200
sleep.mixed to httpbin.foo: 200
sleep.mixed to httpbin.mixed: 200
sleep.mixed to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 200
sleep.legacy to httpbin.mixed: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

In the setup, we start with `PERMISSIVE` for all services in the mesh. Combined with automatic
mutual TLS enabled, sleep from `foo` and `mixed` client, send mutual TLS traffic to `httpbin.foo`
service and plain text to `httpbin.legacy` service. For `httpbin.mixed`, the client sidecar send
mutual TLS to the pod with sidecar injected deployment, and plain text to the pod without sidecar.

### Configure mutual TLS STRICT

The default installation configures all the service in `PERMISSIVE` mode by default, which accepts
both plain text and mutual TLS traffic. Now we configure `httpbin.foo` service to mutual TLS
`STRICT` mode, only accepting mutual TLS traffic.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
EOF
{{< /text >}}

Now the requests from the clients without sidecar start to fail.

{{< text bash >}}
$ for from in "foo" "mixed" "legacy"; do for to in "foo" "mixed" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.mixed: 200
sleep.foo to httpbin.legacy: 200
sleep.mixed to httpbin.foo: 200
sleep.mixed to httpbin.mixed: 200
sleep.mixed to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.mixed: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### Disable mutual TLS to plain text

Now we can explicitly disable mutual TLS to plain text for `httpbin.foo`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
EOF
{{< /text >}}

In this case, since the service is in plain text mode. Istio automatically configure clients
to send plain text traffic to avoid breakage. Confirm all the traffic still succeed.

{{< text bash >}}
$ for from in "foo" "mixed" "legacy"; do for to in "foo" "mixed" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.mixed: 200
sleep.foo to httpbin.legacy: 200
sleep.mixed to httpbin.foo: 200
sleep.mixed to httpbin.mixed: 200
sleep.mixed to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.mixed: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### Destination rule overrides

For backward compatibility, you can still use destination rule to override the TLS configuration as
before. For example, you can explicitly configure destination rule for `httpbin.foo` to enable
mutual TLS explicitly

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin-foo-mtls"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

Since in previous steps, we already disable the authentication policy for `httpbin.foo` to disable
mutual TLS, we should see the traffic from clients with sidecar starts to fail.


{{< text bash >}}
$ for from in "foo" "mixed" "legacy"; do for to in "foo" "mixed" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 503
sleep.foo to httpbin.mixed: 200
sleep.foo to httpbin.legacy: 200
sleep.mixed to httpbin.foo: 503
sleep.mixed to httpbin.mixed: 200
sleep.mixed to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 200
sleep.legacy to httpbin.mixed: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### Cleanup

{{< text bash >}}
$ kubectl delete ns foo mixed legacy
{{< /text >}}

## Summary

Automatic mutual TLS configures the client sidecar to send TLS traffic by default between sidecars.
This means corresponding TLS overhead.

As aforementioned, automatic mutual TLS is a mesh wide Helm installation option. You have to
re-deploy Istio to enable or disable the feature. When disabling the feature, if you already rely
on it to automatically encrypt the traffic, then traffic can **fall back to plain text**, which
can affect your **security posture or break the traffic**, if the service is already configured as
`STRICT` to only accept mutual TLS traffic.

Currently, automatic mutual TLS is an Alpha stage feature, please be aware of the risk.
We're considering to make this feature the default enabled. Please consider to send your feedback
or encountered issues when trying auto mutual TLS via [Git Hub](https://github.com/istio/istio/issues/18548).

---
title: Automatic mutual TLS
description: A simplified workflow to adopt mutual TLS with minimal configuration overhead.
weight: 10
keywords: [security,mtls,ux]
---

This tasks shows a simplified workflow for mutual TLS adoption.

With Istio auto mutual TLS feature, you can adopt mutual TLS by only configuring authentication policy without worrying about destination rule.

Istio tracks the server workloads migrated to Istio sidecar, and configures client sidecar to send mutual TLS traffic to those workloads automatically, and send plain text traffic to workloads
without sidecars. This allows you to adopt Istio mutual TLS incrementally with minimal manual configuration.

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Install Istio with the `global.mtls.enabled` option set to false and `global.mtls.auto` set to true.
For example, using the `demo` configuration profile:

{{< text bash >}}
$ istioctl manifest apply --set profile=demo \
  --set values.global.mtls.auto=true \
  --set values.global.mtls.enabled=false
{{< /text >}}

## Instructions

### Setup

Our examples deploy `httpbin` service into three namespaces, `full`, `partial`, and `legacy`.
Each represents different phase of Istio migration.

`full` namespace contains all server workloads finishing the Istio migration. All deployments have
sidecar injected.

{{< text bash >}}
$ kubectl create ns full
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n full
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n full
{{< /text >}}

`partial` namespace contains server workloads partially migrated to Istio. Only migrated one has
sidecar injected, able to serve mutual TLS traffic.

{{< text bash >}}
$ kubectl create ns partial
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n partial
$ cat <<EOF | kubectl apply -n partial -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-nosidecar
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
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

`legacy` namespace contains the workloads and none of them have Envoy sidecar.

{{< text bash >}}
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

Last we deploy two `sleep` workloads, one has sidecar and one does not.

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n full
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

You can confirm the deployments in all namespaces.

{{< text bash >}}
$ kubectl get pods -n full
$ kubectl get pods -n partial
$ kubectl get pods -n legacy
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-dcd949489-5cndk   2/2     Running   0          39s
sleep-58d6644d44-gb55j    2/2     Running   0          38s
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-6f6fc94fb6-8d62h   1/1     Running   0          10s
httpbin-dcd949489-5fsbs    2/2     Running   0          12s
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-54f5bb4957-lzxlg   1/1     Running   0          6s
sleep-74564b477b-vb6h4     1/1     Running   0          4s
{{< /text >}}

You should also verify that there is a default mesh authentication policy in the system, which you can do as follows:

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
$ kubectl get meshpolicies -o yaml | grep ' mode'
NAMESPACE      NAME                          AGE
istio-system   grafana-ports-mtls-disabled   2h
        mode: PERMISSIVE
{{< /text >}}

Last but not least, verify that there are no destination rules that apply on the example services. You can do this by checking the `host:` value of
 existing destination rules and make sure they do not match. For example:

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
    host: istio-policy.istio-system.svc.cluster.local
    host: istio-telemetry.istio-system.svc.cluster.local
{{< /text >}}

You can verify setup by sending an HTTP request with `curl` from any `sleep` pod in the namespace `full`, `partial` or `legacy` to either `httpbin.full`, `httpbin.partial` or `httpbin.legacy`. All requests should succeed with HTTP code 200.

For example, here is a command to check `sleep.full` to `httpbin.full` reachability:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n full -o jsonpath={.items..metadata.name}) -c sleep -n full -- curl http://httpbin.full:8000/headers  -s  -w "response %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$'
URI=spiffe://cluster.local/ns/full/sa/sleep
response 200
{{< /text >}}

The SPIFFE URI shows the client identity from X509 certificate, which
indicates the traffic is sent in mutual TLS. If the traffic is in plain text, no client certificate
will be displayed.

### Start from PERMISSIVE mode

In the setup, we start with `PERMISSIVE` for all services in the mesh.

1. All `httpbin.full` workloads and the workload with sidecar for `httpbin.partial` are able to serve
both mutual TLS traffic and plain text traffic.
1. The workload without sidecar for `httpbin.partial` and workloads of `httpbin.legacy` can only serve
plain text traffic.

Automatic mutual TLS configures the client, `sleep.full`, to send mutual TLS to the first type of
workloads and plain text to the second type.

You can verify the reachability as:

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.partial
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 200

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200

{{< /text >}}

### Working with Sidecar Migration

The request to `httpbin.partial` can reach to server workloads with or without sidecar. Istio
automatically configures the `sleep.full` client to initiates mutual TLS connection to workload
with sidecar.

{{< text bash >}}
$ for i in `seq 1 10`; do kubectl exec $(kubectl get pod -l app=sleep -n full -o jsonpath={.items..metadata.name}) -c sleep -nfull  -- curl http://httpbin.partial:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

response code: 200
{{< /text >}}

Without automatic mutual TLS feature, you have to track the sidecar migration finishes, and then
explicitly configure the destination rule to make client send mutual TLS traffic to `httpbin.full`.

### Lock down mutual TLS to STRICT

Imagine now you need to lock down the `httpbin.full` service to only accept mutual TLS traffic. You
can configure authentication policy to `STRICT`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n full -f -
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

All `httpbin.full` workloads and the workload with sidecar for `httpbin.partial` can only serve
mutual TLS traffic.

Now the requests from the `sleep.legacy` starts to fail, since it can't send mutual TLS traffic.
But the client `sleep.full` is automatically configured with auto mutual TLS, to send mutual TLS
request, returning 200.

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.partial
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 000
command terminated with exit code 56

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200

{{< /text >}}

### Disable mutual TLS to plain text

If for some reason, you want service to be in plain text mode explicitly, we can configure authentication policy as plain text.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n full -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
EOF
{{< /text >}}

In this case, since the service is in plain text mode. Istio automatically configures client sidecars
to send plain text traffic to avoid breakage.

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
response code: 200

sleep.full to httpbin.partial
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 200

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200
{{< /text >}}

All traffic are now in plain text.

### Destination rule overrides

For backward compatibility, you can still use destination rule to override the TLS configuration as
before. When destination rule has an explicit TLS configuration, that overrides the client sidecars'
TLS configuration.

For example, you can explicitly configure destination rule for `httpbin.full` to enable or
disable mutual TLS explicitly.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n full -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin-full-mtls"
spec:
  host: httpbin.full.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

Since in previous steps, we already disable the authentication policy for `httpbin.full` to disable
mutual TLS, we should see the traffic from `sleep.full` starting to fail.

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
response code: 503

sleep.full to httpbin.partial
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 200

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200

{{< /text >}}

### Cleanup

{{< text bash >}}
$ kubectl delete ns full partial legacy
{{< /text >}}

## Summary

Automatic mutual TLS configures the client sidecar to send TLS traffic by default between sidecars.
You only need to configure authentication policy.

As aforementioned, automatic mutual TLS is a mesh wide Helm installation option. You have to
re-deploy Istio to enable or disable the feature. When disabling the feature, if you already rely
on it to automatically encrypt the traffic, then traffic can **fall back to plain text**, which
can affect your **security posture or break the traffic**, if the service is already configured as
`STRICT` to only accept mutual TLS traffic.

Currently, automatic mutual TLS is an Alpha stage feature, please be aware of the risk, and the
additional CPU cost for TLS encryption.

We're considering to make this feature the default enabled. Please consider to send your feedback
or encountered issues when trying auto mutual TLS via [Git Hub](https://github.com/istio/istio/issues/18548).

---
title: Mutual TLS Migration
description: Shows you how to migrate your Istio services to mutual TLS incrementally.
weight: 10
keywords: [security,authentication,migration]
---

This task shows how to migrate your existing Istio services' traffic from plain text to mutual TLS.

In practice, a mesh consists of both Istio services (with Envoy sidecar) and services without Envoy sidecar(call it "legacy" below for simplicity).
A legacy service can't use Istio issued key/certificate to send mutual TLS traffic. We want to enable mutual TLS incrementally, safely.

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/authn-policy/) and related [mutual TLS authentication](/docs/concepts/security/mutual-tls/) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use `install/kubernetes/istio-demo.yaml` as described in [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/kubernetes/helm-install/)).

* For demo, create three namespaces `foo`, `bar`, `legacy`, and deploy [httpbin](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/httpbin) and [sleep](https://github.com/istio/istio/tree/master/samples/sleep) with sidecar on both of them. Also, run another sleep app without sidecar (to keep it separate, run it in `legacy` namespace)

    ```command
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    ```

* Verify setup by sending an http request (using curl command) from any sleep pod (among those in namespace `foo`, `bar` or `legacy`) to `httpbin.foo`.  All requests should success with HTTP code 200.

    ```command
    $ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
    sleep.foo to httpbin.foo: 200
    sleep.bar to httpbin.foo: 200
    sleep.legacy to httpbin.foo: 200
    ```

* Also verify that there are no authentication policy or destination rule in the system

    ```command
    $ kubectl get policies.authentication.istio.io --all-namespaces
    No resources found.
    $ kubectl get destionationrule --all-namespaces
    No resources found.
    ```

## Configure the server to accept both mTLS and plain text traffic

In Authentication Policy, we have a `PERMISSIVE` mode which makes the server accept both mutual TLS and plain text traffic.
We need to configure the server to this mode.

```bash
cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-httpbin-permissive"
  namespace: foo
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
      mode: PERMISSIVE
EOF
```

Now send traffic to `httpbin.foo` again to ensure all requests can still succeed.

```command
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
200
```

## Configure clients to send mutual TLS traffic

Configure Istio services to send mutual TLS traffic by setting `DestinationRule`.

```bash
cat <<EOF | istioctl create -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-httpbin-istio-client-mtls"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

`sleep.foo` and `sleep.bar` should start sending mutual TLS traffic to `httpbin.foo`.

Now we confirm all requests to `httpbin.foo` still succeed.

```command
$ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
```

You can also specify a subset of the clients' request to use `ISTIO_MUTUAL` mutual TLS in
[DestinationRule](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#DestinationRule).
After verifying it works by checking [Grafana to monitor](https://istio.io/docs/tasks/telemetry/using-istio-dashboard/),
then increase the rollout scope and finally apply to all Istio client services.

## Lock down to mutual TLS (optional)

After migrating all clients to Istio services, injecting Envoy sidecar, we can lock down the `httpbin.foo` to only accept mutual TLS traffic.

```bash
cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-httpbin-permissive"
  namespace: foo
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
      mode: STRICT
EOF
```

Now you should see the request from `sleep.legacy` fails.

```command
$ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
```

If you can't migrate all your services to Istio (injecting Envoy sidecar), you have to stay at `PERMISSIVE` mode.
However, when configured with `PERMISSIVE` mode, no authentication or authorization checks will be performed for the plain text traffic by default.
We recommend to use [RBAC](https://istio.io/docs/tasks/security/role-based-access-control/) to configure different paths with different authorization policies.

## Cleanup

Remove all resources.

```command
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
```
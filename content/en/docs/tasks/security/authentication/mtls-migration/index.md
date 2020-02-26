---
title: Mutual TLS Migration
description: Shows you how to incrementally migrate your Istio services to mutual TLS.
weight: 40
keywords: [security,authentication,migration]
aliases:
    - /docs/tasks/security/mtls-migration/
---

This task shows how to ensure your workloads only communicate in mutual TLS as they are migrated to
Istio.

Istio by default automatically configures workloads between sidecars in [mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls). By default, Istio configures workloads as `PERMISSIVE` mode.
When `PERMISSIVE` mode is enabled, a service can take both plain text and mutual TLS traffic. In order to only allow
mutual TLS traffic, we need to change to `STRICT` mode.

You can use the [Grafana dashboard](/docs/tasks/observability/metrics/using-istio-dashboard/) to
check which workloads are still sending plaintext traffic to the workloads in `PERMISSIVE` mode and choose to lock
them down once the migration is done.

## Before you begin

<!-- TODO: update the link after other PRs are merged -->

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Read the [authentication policy task](/docs/tasks/security/authentication/authn-policy) to
  learn how to configure authentication policy.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use the demo configuration profile as described in [installation steps](/docs/setup/getting-started).

In this section, you can try out the migration process by creating sample workloads and modifying
the policies to enforce STRICT mutual TLS between the workloads.

## Set up the cluster

* Create the following namespaces and deploy [httpbin]({{< github_tree >}}/samples/httpbin) and [sleep]({{< github_tree >}}/samples/sleep) with sidecars on both of them.
    * `foo`
    * `bar`

* Create the following namespace and deploy [sleep]({{< github_tree >}}/samples/sleep) without a sidecar
    * `legacy`

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    {{< /text >}}

* Verify setup by sending an http request (using curl command) from any sleep pod (among those in namespace `foo`, `bar` or `legacy`) to `httpbin.foo`.  All requests should success with HTTP code 200.

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
    sleep.foo to httpbin.foo: 200
    sleep.foo to httpbin.bar: 200
    sleep.bar to httpbin.foo: 200
    sleep.bar to httpbin.bar: 200
    sleep.legacy to httpbin.foo: 200
    sleep.legacy to httpbin.bar: 200
    {{< /text >}}

* Also verify that there are no authentication policies or destination rules (except control plane's) in the system:

    {{< text bash >}}
    $ kubectl get peerauthentication --all-namespaces
    No resources found
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces
    No resources found
    {{< /text >}}

## Lock down to mutual TLS by namespace

After migrating all clients to Istio and injecting the Envoy sidecar, we can lock down workloads in `foo` namespace
to only accept mutual TLS traffic.

{{< text bash >}}
$ kubectl apply -n foo -f - << EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Now, you should see the request from `sleep.legacy` to `httpbin.foo` failing.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
{{< /text >}}

If you can't migrate all your services to Istio (injecting Envoy sidecar), you have to stay at `PERMISSIVE` mode.
However, when configured with `PERMISSIVE` mode, no authentication or authorization checks will be performed for plaintext traffic by default.
We recommend you use [Istio Authorization](/docs/tasks/security/authorization/authz-http/) to configure different paths with different authorization policies.

## Lock down mutual TLS for entire mesh

{{< text bash >}}
$ kubectl apply -n istio-system -f - << EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Now you can see both `foo` `bar` namespaces enforcing mutual TLS only traffic, thus requests from `sleep.legacy`
failing at both.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
{{< /text >}}

## Clean up the example

To remove all resources created in this section:

{{< text bash >}}
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
$ kubectl delete peerauthentication --all-namespaces --all
{{< /text >}}

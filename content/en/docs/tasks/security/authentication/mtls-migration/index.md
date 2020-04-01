---
title: Mutual TLS Migration
description: Shows you how to incrementally migrate your Istio services to mutual TLS.
weight: 40
keywords: [security,authentication,migration]
aliases:
    - /docs/tasks/security/mtls-migration/
---

This task shows how to ensure your workloads only communicate using mutual TLS as they are migrated to
Istio.

Istio automatically configures workload sidecars to use [mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) when calling other workloads. By default, Istio configures the destination workloads using `PERMISSIVE` mode.
When `PERMISSIVE` mode is enabled, a service can accept both plain text and mutual TLS traffic. In order to only allow
mutual TLS traffic, the configuration needs to be changed to `STRICT` mode.

You can use the [Grafana dashboard](/docs/tasks/observability/metrics/using-istio-dashboard/) to
check which workloads are still sending plaintext traffic to the workloads in `PERMISSIVE` mode and choose to lock
them down once the migration is done.

## Before you begin

<!-- TODO: update the link after other PRs are merged -->

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Read the [authentication policy task](/docs/tasks/security/authentication/authn-policy) to
  learn how to configure authentication policy.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use the demo configuration profile as described in [installation steps](/docs/setup/getting-started)).

In this task, you can try out the migration process by creating sample workloads and modifying
the policies to enforce STRICT mutual TLS between the workloads.

## Set up the cluster

* Create two namespaces, `foo` and `bar`, and deploy [httpbin]({{< github_tree >}}/samples/httpbin) and [sleep]({{< github_tree >}}/samples/sleep) with sidecars on both of them:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
    {{< /text >}}

* Create another namespace, `legacy`, and deploy [sleep]({{< github_tree >}}/samples/sleep) without a sidecar:

    {{< text bash >}}
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

* Also verify that there are no authentication policies or destination rules (except control plane ones) in the system:

    {{< text bash >}}
    $ kubectl get peerauthentication --all-namespaces
    No resources found
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces
    No resources found
    {{< /text >}}

## Lock down to mutual TLS by namespace

After migrating all clients to Istio and injecting the Envoy sidecar, you can lock down workloads in the `foo` namespace
to only accept mutual TLS traffic.

{{< text bash >}}
$ kubectl apply -n foo -f - <<EOF
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

If you installed Istio with `values.global.proxy.privildeged=true`, you can use `tcpdump` to verify
traffic is encrypted or not.

{{< text bash >}}
$ kubectl exec -nfoo $(kubectl get pod -nfoo -lapp=httpbin -ojsonpath={.items..metadata.name}) -c istio-proxy -it -- sudo tcpdump dst port 80  -A
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
{{< /text >}}

You will see plain text and encrypted text in the output when requests are sent from `sleep.legacy` and `sleep.foo`
respectively.

If you can't migrate all your services to Istio (i.e., inject Envoy sidecar in all of them), you will need to continue to use `PERMISSIVE` mode.
However, when configured with `PERMISSIVE` mode, no authentication or authorization checks will be performed for plaintext traffic by default.
We recommend you use [Istio Authorization](/docs/tasks/security/authorization/authz-http/) to configure different paths with different authorization policies.

## Lock down mutual TLS for the entire mesh

{{< text bash >}}
$ kubectl apply -n istio-system -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Now, both the `foo` and `bar` namespaces enforce mutual TLS only traffic, so you should see requests from `sleep.legacy`
failing for both.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
{{< /text >}}

## Clean up the example

1. To remove all authentication policies

{{< text bash >}}
$ kubectl delete peerauthentication --all-namespaces --all
{{< /text >}}

1. If you are not planning to explore any follow-on tasks, you can remove all test namespaces.

{{< text bash >}}
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
{{< /text >}}

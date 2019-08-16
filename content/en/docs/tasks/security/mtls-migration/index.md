---
title: Mutual TLS Migration
description: Shows you how to incrementally migrate your Istio services to mutual TLS.
weight: 80
keywords: [security,authentication,migration]
---

This task shows how to migrate your existing Istio services' traffic from plain
text to mutual TLS without breaking live traffic.

In the scenario where there are many services communicating over the network, it
may be desirable to gradually migrate them to Istio. During the migration, some services have Envoy
sidecars while some do not. For a service with a sidecar, if you enable
mutual TLS on the service, the connections from legacy clients (i.e., clients without
Envoy) will lose communication since they do not have Envoy sidecars and client certificates.
To solve this issue, Istio authentication policy provides a "PERMISSIVE" mode to solve
this problem. Once "PERMISSIVE" mode is enabled, a service can take both HTTP
and mutual TLS traffic.

You can configure Istio services to send mutual
TLS traffic to that service while connections from legacy services will not
lose communication. Moreover, you can use the
[Grafana dashboard](/docs/tasks/telemetry/metrics/using-istio-dashboard/) to check which services are
still sending plaintext traffic to the service in "PERMISSIVE" mode and choose to lock
down once the migration is done.

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use `install/kubernetes/istio-demo.yaml` as described in [installation steps](/docs/setup/install/kubernetes/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/install/helm/)).

* For demo
    * Create the following namespaces and deploy [httpbin]({{< github_tree >}}/samples/httpbin) and [sleep]({{< github_tree >}}/samples/sleep) with sidecar on both of them.
        * `foo`
        * `bar`

    * Create the following namespace and deploy [sleep]({{< github_tree >}}/samples/sleep) without sidecar
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
    $ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
    sleep.foo to httpbin.foo: 200
    sleep.bar to httpbin.foo: 200
    sleep.legacy to httpbin.foo: 200
    {{< /text >}}

* Also verify that there are no authentication policies or destination rules (except control plane's) in the system:

    {{< text bash >}}
    $ kubectl get policies.authentication.istio.io --all-namespaces
    NAMESPACE      NAME                          AGE
    istio-system   grafana-ports-mtls-disabled   3m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces
    NAMESPACE      NAME              AGE
    istio-system   istio-policy      25m
    istio-system   istio-telemetry   25m
    {{< /text >}}

## Configure clients to send mutual TLS traffic

Configure Istio services to send mutual TLS traffic by setting `DestinationRule`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
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
{{< /text >}}

`sleep.foo` and `sleep.bar` should start sending mutual TLS traffic to `httpbin.foo`. And `sleep.legacy` still sends plaintext
traffic to `httpbin.foo` since it does not have sidecar thus `DestinationRule` does not apply.

Now we confirm all requests to `httpbin.foo` still succeed.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
200
{{< /text >}}

You can also specify a subset of the clients' request to use `ISTIO_MUTUAL` mutual TLS in
[`DestinationRule`](/docs/reference/config/networking/v1alpha3/destination-rule/).
After verifying it works by checking [Grafana to monitor](/docs/tasks/telemetry/metrics/using-istio-dashboard/),
then increase the rollout scope and finally apply to all Istio client services.

## Lock down to mutual TLS (optional)

After migrating all clients to Istio services, injecting Envoy sidecar, we can lock down the `httpbin.foo` to only accept mutual TLS traffic.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
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
{{< /text >}}

Now you should see the request from `sleep.legacy` fails.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
200
200
503
{{< /text >}}

If you can't migrate all your services to Istio (injecting Envoy sidecar), you have to stay at `PERMISSIVE` mode.
However, when configured with `PERMISSIVE` mode, no authentication or authorization checks will be performed for plaintext traffic by default.
We recommend you use [Istio Authorization](/docs/tasks/security/authz-http/) to configure different paths with different authorization policies.

## Cleanup

Remove all resources.

{{< text bash >}}
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
{{< /text >}}

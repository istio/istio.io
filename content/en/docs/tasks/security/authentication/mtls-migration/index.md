---
title: Mutual TLS Migration
description: Shows you how to incrementally migrate your Istio services to mutual TLS.
weight: 40
keywords: [security,authentication,migration]
aliases:
    - /docs/tasks/security/mtls-migration/
---

This task shows how to migrate your existing Istio services' traffic from plain
text to mutual TLS without breaking live traffic.

In the scenario where there are many services communicating over the network, it
may be desirable to gradually migrate them to Istio. During the migration, some services have Envoy
sidecars while some do not. For a service with a sidecar, if you enable
mutual TLS on the service, the connections from legacy clients (i.e., clients without
Envoy) will lose communication since they do not have Envoy sidecars and client certificates.
To solve this issue, Istio authentication policy provides a `PERMISSIVE` mode to solve
this problem. When `PERMISSIVE` mode is enabled, a service can take both HTTP
and mutual TLS traffic.

You can configure Istio services to send mutual
TLS traffic to that service while connections from legacy services will not
lose communication. Moreover, you can use the
[Grafana dashboard](/docs/tasks/observability/metrics/using-istio-dashboard/) to check which services are
still sending plaintext traffic to the service in `PERMISSIVE` mode and choose to lock
them down once the migration is done.

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Read the [authentication policy task](/docs/tasks/security/authentication/authn-policy) to
  learn how to configure authentication policy.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use the demo configuration profile as described in
[installation steps](/docs/setup/getting-started), or set the `global.mtls.enabled` installation option to false).

* Ensure that your cluster is in `PERMISSIVE` mode before migrating to mutual TLS.
  Run the following command to check:

    {{< text bash >}}
    $ kubectl get meshpolicy default -o yaml
    ...
    spec:
      peers:
      - mtls:
          mode: PERMISSIVE
    {{< /text >}}

    If the output is the same as above, you can skip the next step.

* Run the following command to enable `PERMISSIVE` mode for the cluster. In general, this operation
  does not cause any interruption to your workloads, but note the warning message below.

    {{< warning >}}
    In `PERMISSIVE` mode, the Envoy sidecar relies on the
    [ALPN](https://en.wikipedia.org/wiki/Application-Layer_Protocol_Negotiation) value `istio` to
    decide whether to terminate the mutual TLS traffic. If your workloads (without Envoy sidecar)
    have enabled mutual TLS directly to the services with Envoy sidecars, enabling `PERMISSIVE` mode
    may cause these connections to fail.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "MeshPolicy"
    metadata:
      name: "default"
    spec:
      peers:
      - mtls:
          mode: PERMISSIVE
    EOF
    {{< /text >}}

{{< tip >}}
You can use the following command to show the mutual TLS configuration of all connections from one pod:

{{< text bash >}}
$ istioctl authn tls-check <YOUR_POD> -n <YOUR_NAMESPACE>
{{< /text >}}

{{< /tip >}}

The rest of this task is divided into two parts.

* If you want to enable mutual TLS for your workloads one by one, refer to
[gradually enable mutual TLS for services](/docs/tasks/security/authentication/mtls-migration/#option-1-gradually-enable-mutual-tls-for-services),
which describes the process using simple examples.

* If you want to enable mutual TLS for the entire cluster, refer to
[globally enable mutual TLS for the cluster](/docs/tasks/security/authentication/mtls-migration/#option-2-globally-enable-mutual-tls-for-the-cluster).

## Option 1: gradually enable mutual TLS for services

In this section, you can try out the migration process by creating sample workloads and modifying
the policies to enforce STRICT mutual TLS between the workloads.

### Set up the cluster

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
    NAMESPACE      NAME                                 HOST                                             AGE
    istio-system   istio-multicluster-destinationrule   *.global                                         35s
    istio-system   istio-policy                         istio-policy.istio-system.svc.cluster.local      35s
    istio-system   istio-telemetry                      istio-telemetry.istio-system.svc.cluster.local   33s
    {{< /text >}}

### Configure clients to send mutual TLS traffic

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
sleep.foo to httpbin.foo: 200
sleep.bar to httpbin.foo: 200
sleep.legacy to httpbin.foo: 200
{{< /text >}}

You can also specify a subset of the clients' request to use `ISTIO_MUTUAL` mutual TLS in
[`DestinationRule`](/docs/reference/config/networking/destination-rule/).
After verifying it works by checking [Grafana to monitor](/docs/tasks/observability/metrics/using-istio-dashboard/),
then increase the rollout scope and finally apply to all Istio client services.

### Lock down to mutual TLS

After migrating all clients to Istio services and injecting the Envoy sidecar, we can lock down the `httpbin.foo` to only accept mutual TLS traffic.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-httpbin-strict"
  namespace: foo
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
      mode: STRICT
EOF
{{< /text >}}

Now, you should see the request from `sleep.legacy` fail.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.foo: %{http_code}\n"; done
sleep.foo to httpbin.foo: 200
sleep.bar to httpbin.foo: 200
sleep.legacy to httpbin.foo: 503
{{< /text >}}

If you can't migrate all your services to Istio (injecting Envoy sidecar), you have to stay at `PERMISSIVE` mode.
However, when configured with `PERMISSIVE` mode, no authentication or authorization checks will be performed for plaintext traffic by default.
We recommend you use [Istio Authorization](/docs/tasks/security/authorization/authz-http/) to configure different paths with different authorization policies.

### Clean up the example

To remove all resources created in this section:

{{< text bash >}}
$ kubectl delete ns foo bar legacy
Namespaces foo bar legacy deleted.
{{< /text >}}

## Option 2: globally enable mutual TLS for the cluster

This section describes how to apply the configuration to enforce mutual TLS for a cluster. For more
details, see the
[Authentication policy](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)
task.

{{< warning >}}
If you have special TLS configurations for your services or you have
services without Envoy sidecars, we recommend that you
[enable mutual TLS service by service](/docs/tasks/security/authentication/mtls-migration/#option-1-gradually-enable-mutual-tls-for-services).
{{< /warning >}}

### Configure all clients to send mutual TLS traffic

Run the following command to enable all Envoy sidecars to send mutual TLS traffic to the servers.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

The connections between services should not be interrupted.

### Lock down to mutual TLS for the entire cluster

Run the following command to enforce all Envoy sidecars to only receive mutual TLS traffic.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

The connections between services should not be interrupted.

### Clean up global mutual TLS configuration

Choose one of the following, depending on the mode you want to switch to:

* To switch to `PERMISSIVE` mode for the cluster:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "MeshPolicy"
    metadata:
      name: "default"
    spec:
      peers:
      - mtls:
          mode: PERMISSIVE
    EOF
    {{< /text >}}

* To disable the global mutual TLS and switch to plaintext only:

    {{< text bash >}}
    $ kubectl delete meshpolicy default
    $ kubectl delete destinationrule default -n istio-system
    {{< /text >}}

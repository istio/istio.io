---
title: Mutual TLS Deep-Dive
description: Shows you how to verify and test Istio's automatic mutual TLS authentication.
weight: 10
keywords: [security,mutual-tls]
---

Through this task, you will have a closer look mutual TLS, and learn to its settings. This task assumes you have
already finished the [authentication policy](/docs/tasks/security/authn-policy/) task and are familiar with using authentication policy to enable mutual TLS.

## Before you begin

1. Install Istio on Kubernetes with global mutual TLS enabled:
    * You can use [Helm](/docs/setup/kubernetes/helm-install/) with `global.mtls.enabled` set to `true`
    * If you already have Istio installed, you can add or modify authentication policies and destination rules to enable mutual TLS as described in this [task](/docs/tasks/security/authn-policy/#globally-enabling-istio-mutual-tls).

1. For demo, deploy [httpbin]({{< github_tree >}}/samples/httpbin) and [sleep]({{< github_tree >}}/samples/sleep) with Envoy sidecar. For simplicity, the demo is setup in the `default` namespace. If you wish to use a different namespace,  please add `-n <your-namespace>` appropriately to the example commands in the next sections.

    * If you are using [manual sidecar injection](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection), use the following command:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    * If you are using a cluster with [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection) enabled, simply deploy the services using `kubectl`

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

## Verifying Citadel is running

[Citadel](/docs/concepts/security/#key-management) is the Istio's key management service. It must be up and running in order for mutual TLS to work correctly. Verify the cluster-level Citadel is running:

{{< text bash >}}
$ kubectl get deploy -l istio=citadel -n istio-system
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-citadel   1         1         1            1           1m
{{< /text >}}

Citadel is up if the "AVAILABLE" column is 1.

## Verifying keys and certificates installation

Istio automatically installs necessary keys and certificates for mutual TLS authentication in all sidecar containers.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- ls /etc/certs
cert-chain.pem
key.pem
root-cert.pem
{{< /text >}}

> `cert-chain.pem` is Envoy's cert that needs to be presented to the other side. `key.pem` is Envoy's private key
paired with Envoy's cert in `cert-chain.pem`. `root-cert.pem` is the root cert to verify the peer's cert.
In this example, we only have one Citadel in a cluster, so all Envoys have the same `root-cert.pem`.

Use the `oppenssl` tool to check if certificate is valid (current time should be in between `Not Before` and `Not After`)

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep Validity -A 2
Validity
        Not Before: May 17 23:02:11 2018 GMT
        Not After : Aug 15 23:02:11 2018 GMT
{{< /text >}}

You can also check the _identity_ of the client certificate:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
        X509v3 Subject Alternative Name:
            URI:spiffe://cluster.local/ns/default/sa/default
{{< /text >}}

Please check [secure naming](/docs/concepts/security/#workflow) for more information about  _service identity_ in Istio.

## Verifying TLS configuration

Use the `istioctl` tool to check the effective TLS settings. For example, the command below shows what TLS mode is used for `httpbin.default.svc.cluster.local`, and what authentication policy and destination rules are used for that configuration:

{{< text bash >}}
$ istioctl authn tls-check httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS     SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8080     OK         mTLS       mTLS       default/            default/default
{{< /text >}}

Where:

* STATUS column: shows whether the TLS settings are consistent between server (i.e `httpbin` service) and client(s), i.e all other services making call to `httpbin`.

* SERVER column: shows the mode which is used on server

* CLIENT column: shows the mode which is used on client(s)

* AUTHN POLICY column: shows the name and namespace of the authentication policy that is used. If the policy is the mesh-wide policy, namespace is blank, e.g `default/`

* DESTINATION RULE column: shows the name and namespace of the destination rule that is used.

In the example output above, you can see that mutual TLS is consistently setup for `httpbin.default.svc.cluster.local` on port `8080`. The authentication policy in used is the mesh-wide policy `default`, and destination rule is `default` in `default` namespace.

Now, add a service-specific destination rule for `httpbin` with incorrect TLS mode:

{{< text bash >}}
$ cat <<EOF | istioctl create -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "bad-rule"
spec:
  host: "httpbin.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

Re-running the `istioctl authn tls-check` command, you will see the status is `CONFLICT`, as client is in `HTTP` mode while server is in `mTLS`.

{{< text bash >}}
$ istioctl authn tls-check httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS       SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8080     CONFLICT     mTLS       HTTP       default/            bad-rule/default
{{< /text >}}

As expected, requests from `sleep` to `httpbin` are now failed:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
000
command terminated with exit code 56
{{< /text >}}

Before moving on the next tasks, remove this bad destination rule to make mutual TLS work again:

{{< text bash >}}
$ kubectl delete --ignore-not-found=true bad-rule
{{< /text >}}

## Verifying requests

This task illustrates different kind of responses for the requests in plain-text, TLS without client certificate and TLS with client certificate. All requests
are sent from a client sidecar, so that they can access the keys and certificates in the same way that proxy sidecars do.

> In Istio 1.0, `curl` is included in proxy image, however it might be removed in future releases. In that case, you will need to install `curl` manually.

1. Plain-text requests fail as TLS is required to talk to `httpbin`. Note the exit code is 56 (failure with receiving network data).

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl http://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 56
    {{< /text >}}

1. TLS requests without client certificate also fail, but with exit code 35 (a problem occurred somewhere in the SSL/TLS handshake).

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' -k
    000
    command terminated with exit code 35
    {{< /text >}}

1. TLS request with client certificate succeed as expected:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
    200
    {{< /text >}}

> Istio uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) as service identity, which
offers stronger security than service name (refer [here](/docs/concepts/security/#identity) for more information). Thus the certificates used in Istio do
not have service names, which is the information that `curl` needs to verify server identity. As a result, we use `curl` option `-k` to prevent the `curl`
client from aborting when failing to find and verify the server name (i.e., `httpbin.default.svc.cluster.local`) in the certificate provided by the server.

## Cleanup

{{< text bash >}}
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
$ kubectl delete --ignore-not-found=true -f @samples/sleep/sleep.yaml@
{{< /text >}}

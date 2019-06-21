---
title: Mutual TLS Deep-Dive
description: Shows you how to verify and test Istio's automatic mutual TLS authentication.
weight: 10
keywords: [security,mutual-tls]
---

Through this task, you can have closer look at mutual TLS and learn its settings. This task assumes:

* You have completed the [authentication policy](/docs/tasks/security/authn-policy/) task.
* You are familiar with using authentication policy to enable mutual TLS.
* Istio runs on Kubernetes with global mutual TLS enabled. You can follow our [instructions to install Istio](/docs/setup/kubernetes/).
If you already have Istio installed, you can add or modify authentication policies and destination rules to enable mutual TLS as described in this [task](/docs/tasks/security/authn-policy/#globally-enabling-istio-mutual-tls).
* You have deployed the [httpbin]({{< github_tree >}}/samples/httpbin) and [sleep]({{< github_tree >}}/samples/sleep) with Envoy sidecar in the `default` namespace. For example, below is the command to deploy those services with [manual sidecar injection](/docs/setup/kubernetes/additional-setup/sidecar-injection/#manual-sidecar-injection):

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

## Verify Citadel runs properly

[Citadel](/docs/concepts/security/#pki) is Istio's key management service. Citadel must run properly for mutual TLS to work correctly. Verify the
cluster-level Citadel runs properly with the following command:

{{< text bash >}}
$ kubectl get deploy -l istio=citadel -n istio-system
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-citadel   1         1         1            1           1m
{{< /text >}}

Citadel is up if the "AVAILABLE" column is 1.

## Verify keys and certificates installation

Istio automatically installs necessary keys and certificates for mutual TLS authentication in all sidecar containers. Run command below to confirm key and certificate files exist under `/etc/certs`:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- ls /etc/certs
cert-chain.pem
key.pem
root-cert.pem
{{< /text >}}

{{< tip >}}
`cert-chain.pem` is Envoy's cert that needs to be presented to the other side. `key.pem` is Envoy's private key
paired with Envoy's cert in `cert-chain.pem`. `root-cert.pem` is the root cert to verify the peer's cert.
In this example, we only have one Citadel in a cluster, so all Envoys have the same `root-cert.pem`.
{{< /tip >}}

Use the `openssl` tool to check if certificate is valid (current time should be in between `Not Before` and `Not After`)

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

Please check [Istio identity](/docs/concepts/security/#istio-identity) for more information about  _service identity_ in Istio.

## Verify mutual TLS configuration

Use the `istioctl` tool to check if the mutual TLS settings are in effect. The `istioctl` command needs the client's pod because the destination rule depends on the client's namespace.
You can also provide the destination service to filter the status to that service only.

{{< tip >}}
This tool only check the TLS setting consistency between destination rules and authentication policies. It does not take into account whether the
workloads have sidecar or not (i.e, whether those policy/destination rule can be enforced). In other words, status `CONFLICT` doesn't always mean traffic is broken.
{{< /tip >}}

The following commands identify the authentication policy for the `httpbin.default.svc.cluster.local` service and identify the destination rules for the service as seen from the same pod of the `sleep` app:

{{< text bash >}}
$ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ istioctl authn tls-check ${SLEEP_POD} httpbin.default.svc.cluster.local
{{< /text >}}

In the following example output you can see that:

* Mutual TLS is consistently setup for `httpbin.default.svc.cluster.local` on port 8000.
* Istio uses the mesh-wide `default` authentication policy.
* Istio has the `default` destination rule in the `istio-system` namespace.

{{< text plain >}}
HOST:PORT                                  STATUS     SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8000     OK         mTLS       mTLS       default/            default/istio-system
{{< /text >}}

The output shows:

* `STATUS`: whether the TLS settings are consistent between the server, the `httpbin` service in this case, and the client or clients making calls to `httpbin`.

* `SERVER`: the mode used on the server.

* `CLIENT`: the mode used on the client or clients.

* `AUTHN POLICY`: the name and namespace of the authentication policy. If the policy is the mesh-wide policy, namespace is blank, as in this case: `default/`

* `DESTINATION RULE`: the name and namespace of the destination rule used.

To illustrate the case when there are conflicts, add a service-specific destination rule for `httpbin` with incorrect TLS mode:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "bad-rule"
  namespace: "default"
spec:
  host: "httpbin.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

Run the same `istioctl` command as above, you now see the status is `CONFLICT`, as client is in `HTTP` mode while server is in `mTLS`.

{{< text bash >}}
$ istioctl authn tls-check ${SLEEP_POD} httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS       SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8000     CONFLICT     mTLS       HTTP       default/            bad-rule/default
{{< /text >}}

You can also confirm that requests from `sleep` to `httpbin` are now failing:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
503
{{< /text >}}

Before you continue, remove the bad destination rule to make mutual TLS work again with the following command:

{{< text bash >}}
$ kubectl delete destinationrule --ignore-not-found=true bad-rule
{{< /text >}}

## Verify requests

This task shows how a server with mutual TLS enabled responses to requests that are:

* In plain-text
* With TLS but without client certificate
* With TLS with a client certificate

To perform this task, you want to by-pass client proxy. A simplest way to do so is to issue request from `istio-proxy` container.

1. Confirm that plain-text requests fail as TLS is required to talk to `httpbin` with the following command:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl http://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 56
    {{< /text >}}

    {{< tip >}}
    Note that the exit code is 56. The code translates to a failure to receive network data.
    {{< /tip >}}

1. Confirm TLS requests without client certificate also fail:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' -k
    000
    command terminated with exit code 35
    {{< /text >}}

    {{< tip >}}
    This time the exit code is 35, which corresponds to a problem occurring somewhere in the SSL/TLS handshake.
    {{< /tip >}}

1. Confirm TLS request with client certificate succeed:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
    200
    {{< /text >}}

{{< tip >}}
Istio uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) as service identity, which
offers stronger security than service name (for more details, see [Istio identity](/docs/concepts/security/#istio-identity)). Thus, the certificates Istio uses do
not have service names, which is the information that `curl` needs to verify server identity. To prevent the `curl` client from aborting, we use `curl`
with the `-k` option. The option prevents the client from verifying and looking for the server name, for example, `httpbin.default.svc.cluster.local` in the
certificate provided by the server.
{{< /tip >}}

## Cleanup

{{< text bash >}}
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
$ kubectl delete --ignore-not-found=true -f @samples/sleep/sleep.yaml@
{{< /text >}}

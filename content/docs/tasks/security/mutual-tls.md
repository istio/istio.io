---
title: Testing Mutual TLS
description: Shows you how to verify and test Istio's automatic mutual TLS authentication.
weight: 10
---

Through this task, you will learn how to:

* Verify the Istio mutual TLS Authentication setup

* Manually test the authentication

## Before you begin

This task assumes you have a Kubernetes cluster:

* Installed Istio with global mutual TLS enabled:

    ```command
    $ kubectl apply -f @install/kubernetes/istio-auth.yaml@
    ```
    _**OR**_
    Using [Helm](/docs/setup/kubernetes/helm-install/) with `global.mtls.enabled` to `true`.

> Starting with Istio 0.7, you can use [authentication policy](/docs/concepts/security/authn-policy/) to configure mutual TLS for all/selected services in a namespace (repeated for all namespaces to get global setting). See [authentication policy task](/docs/tasks/security/authn-policy/)

* For demo, deploy [httpbin](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/httpbin) and [sleep](https://github.com/istio/istio/tree/master/samples/sleep) with Envoy sidecar. For simplicity, the demo is setup in the `default` namespace. If you wish to use a different namespace,  please add `-n yournamespace` appropriately to the example commands in the next section.

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    ```

## Verifying Istio's mutual TLS authentication setup

### Verifying Citadel

Verify the cluster-level Citadel is running:

```command
$ kubectl get deploy -l istio=citadel -n istio-system
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-citadel   1         1         1            1           1m
```

Citadel is up if the "AVAILABLE" column is 1.

### Verifying service configuration

* Check installation mode. If mutual TLS is enabled by default (e.g `istio-demo-auth.yaml` was used when installing Istio), you can expect to see uncommented `authPolicy: MUTUAL_TLS` in the configmap.

    ```command
    $ kubectl get configmap istio -o yaml -n istio-system | grep authPolicy | head -1
    ```

* Check authentication policies. Mutual TLS can also be enabled (or disabled) per service(s) by authentication policy. A policy, if exist, will overwrite the configmap setting for the targeted services. Unfortunately, there is no quick way to get relevant policies for a service, other than examining all policies in the applicable namespace:

    ```command
    $ kubectl get policies.authentication.istio.io -n default -o yaml
    ```

* Check destination rule. Starting with Istio 0.8, destination rule's [traffic policy](/docs/reference/config/istio.networking.v1alpha3/#TrafficPolicy) is used to configure client side to use (or not use) mutual TLS. For backward compatibility, the _default_ traffic policy is inferred from configmap flag (i.e, if `authPolicy: MUTUAL_TLS`, _default_ traffic policy also be `MUTUAL_TLS`). If there is authentication policy overrules this setting for some services, it should accompany with the appropriate destination rule(s). Similar to authentication policy, the only way to verify the settings is to manually check all rules:

    ```command
    $ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml
    ```

    > Note that the destination rules scoping model is not limited to namespaces. Thus, it's necessary to examine rules in all namespaces.

### Verifying keys and certificates installation

Istio automatically installs necessary keys and certificates for mutual TLS authentication in all sidecar containers.

```command
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- ls /etc/certs
cert-chain.pem
key.pem
root-cert.pem
```

> `cert-chain.pem` is Envoy's cert that needs to be presented to the other side. `key.pem` is Envoy's private key
paired with Envoy's cert in `cert-chain.pem`. `root-cert.pem` is the root cert to verify the peer's cert.
In this example, we only have one Citadel in a cluster, so all Envoys have the same `root-cert.pem`.

Use the `oppenssl` tool to check if certificate is valid (current time should be in between `Not Before` and `Not After`)

```command
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep Validity -A 2
Validity
        Not Before: May 17 23:02:11 2018 GMT
        Not After : Aug 15 23:02:11 2018 GMT
```

You can also check the _identity_ of the client certificate:

```command
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
        X509v3 Subject Alternative Name:
            URI:spiffe://cluster.local/ns/default/sa/default
```

Please check [secure naming](/docs/concepts/security/mutual-tls/#workflow) for more information about  _service identity_ in Istio.

## Testing the authentication setup

Assuming mutual TLS authentication is properly turned on, it should not affect communication from one service to another when both sides have the Envoy sidecar. However, requests from pod without sidecar, or requests directly from sidecar without a client certificate should fail. Examples below illustrates this behavior.

1. Request from `sleep` app container to `httpbin` service should succeed (return `200`)

    ```command
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    200
    ```

1. Request from `sleep` _proxy_ container to `httpbin` service on the other hand fails, as request does not use TLS nor provide a client certificate

    ```command
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 56
    ```
    ```command
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 77
    ```

1. However, request will success if client certificate is provided

    ```command
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k'
    200
    ```

    > Istio uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) as service identity, which offers stronger security than service name (refer [here](/docs/concepts/security/mutual-tls/#identity) for more information). Thus the certificates used in Istio do not have service names, which is the information that `curl` needs to verify server identity. As a result, we use `curl` option `-k` to prevent the `curl` client from aborting when failing to find and verify the server name (i.e., httpbin.ns.svc.cluster.local) in the certificate provided by the server.

1. Request from pod without sidecar. For this demo, let's install another `sleep` service without sidecar. To avoid name conflicts, we put it in different namespace.

    ```command
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    ```

1. Wait after the pod status changes to `Running`, issue the familiar `curl` command. The request should fail as the pod doesn't have a sidecar to help initiate TLS communication.

    ```command
    kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n legacy) -c sleep -n legacy -- curl httpbin.default:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 56
    ```

## What's next

* Learn more about the design principles behind Istio's automatic mutual TLS authentication
  between all services in this [blog](/blog/2017/0.1-auth/).

---
title: Provisioning Identity through SDS
description: Shows how to enable SDS (secret discovery service) for Istio identity provisioning.
weight: 30
keywords: [security,auth-sds]
aliases:
    - /docs/tasks/security/auth-sds/
---

This task shows how to enable
[SDS (secret discovery service)](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration)
for Istio identity provisioning.

By default, the keys and certificates of Istio workloads are generated
by Citadel and distributed to sidecars through secret-volume mounted files.
This approach has the following minor drawbacks:

* Performance regression during certificate rotation:
  When certificate rotation happens, Envoy is hot restarted to pick up the new
  key and certificate, causing performance regression.

* Potential security vulnerability:
  The workload private keys are distributed through Kubernetes secrets,
  with known
  [risks](https://kubernetes.io/docs/concepts/configuration/secret/#risks).

These issues can be addressed by enabling the SDS identity provision flow.
This workflow can be described as follows:

1. The workload sidecar Envoy requests the key and certificates from the Istio
   Agent: Istio Agent is the SDS server.
   In the request, Envoy passes a Kubernetes service account JWT to the agent.

1. Istio Agent generates a key pair and sends the CSR request to Citadel:
   Citadel verifies the JWT and issues the certificate to the Istio Agent.

1. Istio Agent sends the key and certificate back to the workload sidecar.

The SDS approach has the following benefits:

* The private key never leaves the container: It is only in the Istio Agent
  and Envoy sidecar's memory.

* The secret volume mount is no longer needed: The reliance on the Kubernetes
  secrets is eliminated.

* The sidecar Envoy is able to dynamically renew the key and certificate
  through the SDS API: Certificate rotations no longer require Envoy to restart.

## Before you begin

Follow the [Istio installation guide](/docs/setup/install/istioctl/) to set up Istio with the SDS profile.

## Service-to-service mutual TLS using key/certificate provisioned through SDS

Follow the [authentication policy task](/docs/tasks/security/authentication/authn-policy/) to
setup test services.

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
{{< /text >}}

Verify all mutual TLS requests succeed:

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

## Verifying no secret-volume mounted file is generated

To verify that no secret-volume mounted file is generated, access the deployed
workload sidecar container:

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo  -- /bin/bash
{{< /text >}}

As you can see there is no secret file mounted at `/etc/certs` folder.

## Cleanup

1. Clean up the test services and the Istio control plane:

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ kubectl delete -f istio-auth-sds.yaml
    {{< /text >}}

## Caveats

Currently, the SDS identity provision flow has the following caveats:

* SDS support is currently in [Alpha](/about/feature-stages/#security-and-policy-enforcement).

* Smoothly migrating a cluster from using secret volume mount to using
  SDS is a work in progress.

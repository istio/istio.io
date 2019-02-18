---
title: Provisioning Identity through SDS
description: Shows how to enable SDS (secret discovery service) for Istio identity provisioning.
weight: 70
keywords: [security,auth-sds]
---

This task shows how to enable
[SDS (secret discovery service)](https://www.envoyproxy.io/docs/envoy/latest/configuration/secret#config-secret-discovery-service)
for Istio identity provisioning.

Prior to Istio 1.1, the keys and certificates of Istio workloads were generated
by Citadel and distributed to sidecars through secret-volume mounted files,
this approach has the following minor drawbacks:

* Performance regression during certificate rotation:
  When certificate rotation happens, Envoy is hot restarted to pick up the new
  key and certificate, causing performance regression.

* Potential security vulnerability:
  The workload private keys are distributed through Kubernetes secrets,
  with known
  [risks](https://kubernetes.io/docs/concepts/configuration/secret/#risks).

These issues are addressed in Istio 1.1 through the SDS identity provision flow.
The workflow can be described as follows.

1. The workload sidecar Envoy requests the key and certificates from the Citadel
   agent: The Citadel agent is a SDS server, which runs as per-node `DaemonSet`.
   In the request, Envoy passes a Kubernetes service account JWT to the agent.

1. The Citadel agent generates a key pair and sends the CSR request to Citadel:
   Citadel verifies the JWT and issues the certificate to the Citadel agent.

1. The Citadel agent sends the key and certificate back to the workload sidecar.

This approach has the following benefits:

* The private key never leaves the node: It is only in the Citadel agent
  and Envoy sidecar's memory.

* The secret volume mount is no longer needed: The reliance on the Kubernetes
  secrets is eliminated.

* The sidecar Envoy is able to dynamically renew the key and certificate
  through the SDS API: Certificate rotations no longer require Envoy to restart.

## Before you begin

* Set up Istio by following the instructions using
  [Helm](/docs/setup/kubernetes/helm-install/) with SDS setup and global mutual
  TLS enabled:

    {{< text bash >}}
    $ cat install/kubernetes/namespace.yaml > istio-auth-sds.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-* >> istio-auth-sds.yaml
    $ helm dep update --skip-refresh install/kubernetes/helm/istio
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml >> istio-auth-sds.yaml
    $ kubectl create -f istio-auth-sds.yaml
    {{< /text >}}

## Service-to-service mutual TLS using key/certificate provisioned through SDS

Follow the [authentication policy task](/docs/tasks/security/authn-policy/) to
setup test services.

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
$ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n bar
$ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n bar
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

Clean up test services and Istio control plane:

{{< text bash >}}
$ kubectl delete ns foo
$ kubectl delete ns bar
$ kubectl delete -f istio-auth-sds.yaml
{{< /text >}}

## Caveats

Currently, the SDS identity provision flow has the following caveats:

* You still need secret volume mount for enabling the control plane security.
  Enabling SDS for the control plane security remains a work in progress.

* Smoothly migrating a cluster from using secret volume mount to using
  SDS is a work in progress.

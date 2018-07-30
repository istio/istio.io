---
title: Health Checking of Istio Services
description: Shows how to do health checking for Istio services.
weight: 65
keywords: [security,health-check]
---

This task shows how to use [Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) for health checking of Istio services.

There are three options for liveness and readiness probes in Kubernetes:

1. Command
1. HTTP request
1. TCP request

This task provides examples for the first two options with Istio mutual TLS enabled and disabled, respectively.

## Before you begin

* Understand [Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), Istio
[authentication policy](/docs/concepts/security/#authentication-policies) and [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (meaning use `istio.yaml` as described in [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/kubernetes/helm-install/)).

## Liveness and readiness probes with command option

In this section, you configure health checking when mutual TLS is disabled, then when mutual TLS is enabled.

### Mutual TLS disabled

Run this command to deploy [liveness]({{< github_file >}}/samples/health-check/liveness-command.yaml) in the default namespace:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

Wait for a minute and check the pod status:

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           1m
{{< /text >}}

The number '0' in the 'RESTARTS' column means liveness probes worked fine. Readiness probes work in the same way and you can modify `liveness-command.yaml` accordingly to try it yourself.

### Mutual TLS enabled

To enable mutual TLS for services in the default namespace, you must configure an authentication policy and a destination rule.
Follow these steps to complete the configuration:

1. To configure the authentication policy, run:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      peers:
      - mtls: {}
    EOF
    {{< /text >}}

1. To configure the destination rule, run:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: "networking.istio.io/v1alpha3"
    kind: "DestinationRule"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      host: "*.default.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

Run this command to re-deploy the service:

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

Repeat the check status command to verify that the liveness probes work:

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

### Cleanup

Remove the mutual TLS policy and corresponding destination rule added in the steps above:

1. To remove the mutual TLS policy, run:

    {{< text bash >}}
    $ kubectl delete policies default
    {{< /text >}}

1. To remove the corresponding destination rule, run:

    {{< text bash >}}
    $ kubectl delete destinationrules default
    {{< /text >}}

## Liveness and readiness probes with HTTP request option

This section shows how to configure health checking with the HTTP request option.

### Mutual TLS is disabled

Run this command to deploy [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) in the default namespace:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

Wait for a minute and check the pod status to make sure the liveness probes work with '0' in the 'RESTARTS' column.

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

### Mutual TLS is enabled

Again, enable mutual TLS for services in the default namespace by adding namespace-wide authentication policy and a destination rule:

1. To configure the authentication policy, run:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      peers:
      - mtls: {}
    EOF
    {{< /text >}}

1. To configure the destination rule, run:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: "networking.istio.io/v1alpha3"
    kind: "DestinationRule"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      host: "*.default.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

Run these commands to re-deploy the service:

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

Wait for a minute and check the pod status to make sure the liveness probes work with '0' in the 'RESTARTS' column.

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-67d5db65f5-765bb   2/2       Running   0          1m
{{< /text >}}

Note that the image in [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) exposes two ports: 8001 and 8002 ([source code]({{< github_file >}}/samples/health-check/server.go)). In this deployment, port 8001 serves the regular traffic while port 8002 is used for liveness probes. Because the Istio proxy only intercepts ports that are explicitly declared in the `containerPort` field, traffic to 8002 port bypasses the Istio proxy regardless of whether Istio mutual TLS is enabled. However, if you use port 8001 for both regular traffic and liveness probes, health check will fail when mutual TLS is enabled because the HTTP request is sent from Kubelet, which does not send client certificate to the `liveness-http` service.

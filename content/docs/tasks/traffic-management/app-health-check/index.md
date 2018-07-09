---
title: Health Checking of Istio Services
description: Shows how to do health checking for Istio services.
weight: 65
keywords: [security,health-check]
---

This task shows how to use [Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) for health checking on Istio services.

There are three options for liveness and readiness probes in Kubernetes: 1) command; 2) http request; 3) tcp request. In this task, we provide examples for the first two options with Istio mutual TLS enabled and disabled, respectively.

## Before you begin

* Understand [Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), Istio [authentication policy](/docs/concepts/security/authn-policy/) and [mutual TLS authentication](/docs/concepts/security/mutual-tls/) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use istio.yaml as described in [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/kubernetes/helm-install/)).

## Liveness and readiness probes with command option

In this section, we show how to configure health checking when mutual TLS is disabled, then how it works when mutual TLS is enabled.

### Mutual TLS disabled

Run this command to deploy [liveness]({{< github_file >}}/samples/health-check/liveness-command.yaml) in the default namespace:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

Wait for a minute and check the pod status

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           1m
{{< /text >}}

The number '0' in the 'RESTARTS' column means liveness probes works fine. Readiness probes works in the same way and you can modify liveness-command.yaml accordingly to try it yourself.

### Mutual TLS enabled

Run this command to enable mutual TLS for services in the default namespace.

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
  - mtls:
EOF
{{< /text >}}

Run this command to re-deploy the service:

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

And repeat the same steps as in above section to verify that the liveness probes works.

## Liveness and readiness probes with http request option

This section shows how to configure health checking with the HTTP request option.

### Mutual TLS is disabled

Run this command to remove the mutual TLS policy.

{{< text bash >}}
$ cat <<EOF | istioctl delete -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
  - mtls:
EOF
{{< /text >}}

Run this command to deploy [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) in the default namespace:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

Wait for a minute and check the pod status to make sure the liveness probes works with the 'RESTARTS' column to be '0'.

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

### Mutual TLS is enabled

Run this command to enable mutual TLS for services in the default namespace.

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
EOF
{{< /text >}}

Run these commands to re-deploy the service:

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

Wait for a minute and check the pod status to make sure the liveness probes works with the 'RESTARTS' column to be '0'.

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-67d5db65f5-765bb   2/2       Running   0          1m
{{< /text >}}

Note that the image in [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) exposes two ports: 8001 and 8002 ([source code]({{< github_file >}}/samples/health-check/server.go)). In this deployment, port 8001 serves the regular traffic while port 8002 is used for liveness probes. Since Istio proxy only intercepts ports that are explicitly declared at `containerPort` field, traffic to 8002 port will bypass Istio proxy no matter Istio mutual TLS is enabled or not. However, if we use port 8001 for both regular traffic and liveness probes, health check will fail when mutual TLS is enabled since the http request is sent from Kubelet, which does not send client certificate to the liveness-http service.

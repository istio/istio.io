---
title: Health Check on Istio Services
description: Shows how to do health check for Istio services.
weight: 65
keywords: [security,health-check]
---

This task shows how to use [Kubernetes liveness and readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) for health check on Istio services.

There are three options for liveness and readiness probe in Kubernetes: 1) command; 2) http request; 3) tcp request. In this task, we provide examples for the first two options with Istio mutual TLS enabeld and disabled, respecitively. We will cover the third option soon.

## Before you begin

* Understand [Kubernetes liveness and readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), Istio [authentication policy](/docs/concepts/security/authn-policy/) and [mutual TLS authentication](/docs/concepts/security/mutual-tls/) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use `install/kubernetes/istio-demo.yaml` as described in [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/kubernetes/helm-install/)).

## Liveness and Readiness Probe with Command Option

In this section, we first show configure health check with mutual TLS disabled and then show the health check with mutual TLS enabled since currently your cluster has mutual TLS disabled.

### Mutual TLS Disabled

Run this command to deploy [liveness](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/health-check/liveness-command.yaml) on default namespace:

```command
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
```

Wait for a minute and check the pod status
```command
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           1m
```

The number '0' in 'RESTARTS' column means liveness probe works fine. Readiness probe works in the same way and you can modify liveness-command.yaml accordingly to try it yourself.

### Mutual TLS Enabled

Run this command to enable mutual TLS for services on default namespace.

```bash
cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
  - mtls:
EOF
```

Run this command to re-deploy the service:

```command
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
```

And repeat the same steps as in above subsection to verify that liveness probe works.

## Liveness and Readiness Probe with Http Request Option

This section shows how to configure health check with http request option.

### Mutual TLS Disabled

Run this command to remove the mutual TLS policy.

```bash
cat <<EOF | istioctl delete -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
  - mtls:
EOF
```

Run this command to deploy [liveness-http](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/health-check/liveness-http.yaml) on default namespace:

```command
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
```

Wait for a minute and check the pod status to make sure liveness probe works with RESTARTS column to be '0'.

```command
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
```

### Mutual TLS Enabled

Run this command to enable mutual TLS for services on default namespace.

```bash
cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
EOF
```

Run this command to re-deploy the service:

```command
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
```

Wait for a minute and check the pod status to make sure liveness probe works with RESTARTS column to be '0'.

```command
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-67d5db65f5-765bb   2/2       Running   0          1m

Note that the image in [liveness-http](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/health-check/liveness-http.yaml) exposes two ports: 8001 and 8002 ([source code](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/health-check/server.go)). In this deployment, port 8001 serves the regular traffic while port 8002 is used for liveness probe. Since Istio proxy only intercepts ports that are explicitly declared at 'containerPort' fields, traffic to 8002 port will bypass Istio proxy no matter Istio mutual TLS is enabled or not. However, if we use port 8001 for both regualr traffic and liveness probe, health check will fail when mutual TLS is enabled since the http request is sent from Kubelet, which does not send client certificate to the liveness-http service.

Note: we will have a permissive mode in AuthenticationPolicy soon so a port can take both http and mutual TLS traffic. With this mode, liveness probe should work even when regular traffic and health check are on the same port. This could be a workaround for liveness check even though mutual TLS is not actually enforced. In the meantime, we are actively working on a complete solution.

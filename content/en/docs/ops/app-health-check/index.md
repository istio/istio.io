---
title: Health Checking of Istio Services
description: Shows how to do health checking for Istio services.
weight: 1
aliases:
  - /docs/tasks/traffic-management/app-health-check/
  - /docs/ops/security/health-checks-and-mtls/
  - /help/ops/setup/app-health-check
  - /help/ops/app-health-check
keywords: [security,health-check]
---

[Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
offer three different options:

1. Command
1. TCP request
1. HTTP request

This task shows how to use these approaches in Istio with mutual TLS is enabled.

Command and TCP type probes work with Istio regardless of whether or not mutual TLS is enabled. The HTTP request approach requires different Istio configuration with
mutual TLS enabled.

## Before you begin

* Understand [Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), Istio
[authentication policy](/docs/concepts/security/#authentication-policies) and [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (meaning use `istio.yaml` as described in [installation steps](/docs/setup/install/kubernetes/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/install/helm/)).

## Liveness and readiness probes with command option

First, you need to configure health checking with mutual TLS enabled.

To enable mutual TLS for services in the default namespace, you must configure an authentication policy and a destination rule.
Follow these steps to complete the configuration:

1. To configure the authentication policy, run:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
    $ kubectl apply -f - <<EOF
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

Run the following command to deploy the service:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

Repeat the check status command to verify that the liveness probes work:

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

## Liveness and readiness probes with HTTP request option

This section shows how to configure health checking with the HTTP request option when mutual TLS is enabled.

Kubernetes HTTP health check request is sent from Kubelet, which does not have Istio issued certificate to the `liveness-http` service. So when mutual TLS is enabled, the health check request will fail.

We have two options to solve the problem: probe rewrites and separate ports.

### Probe rewrite

This approach rewrites the application `PodSpec` readiness/liveness probe, such that the probe request will be sent to
[Pilot agent](/docs/reference/commands/pilot-agent/). Pilot agent then redirects the
request to application, and strips the response body only returning the response code.

You have two ways to enable Istio to rewrite the liveness HTTP probes.

#### Enable via Helm Option Globally

[Install Istio](/docs/setup/install/helm/) with the `sidecarInjectorWebhook.rewriteAppHTTPProbe=true`
[Helm installation option](/docs/reference/config/installation-options/#sidecarinjectorwebhook-options).

**Alternatively**, update the configuration map of Istio sidecar injection:

{{< text bash >}}
$ kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e "s/ rewriteAppHTTPProbe: false/ rewriteAppHTTPProbe: true/" | kubectl apply -f -
{{< /text >}}

The above installation option and configuration map, each instruct the sidecar injection process to automatically
rewrite the Kubernetes pod's spec, so health checks are able to work under mutual TLS. No need to update your app or pod
spec by yourself.

{{< warning >}}
The configuration changes above (by Helm or by the configuration map) effect all Istio app deployments.
{{< /warning >}}

#### Use Annotations on Pod

<!-- Add samples YAML or kubectl patch? -->

Rather than install Istio with different Helm options, you can annotate the [Pod object](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) with `sidecar.istio.io/rewriteAppHTTPProbers: "true"`.  If you annotate any other [Kubernetes objects](https://kubernetes.io/docs/concepts/#kubernetes-objects), the annotation will be ignored.

{{< text yaml >}}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: liveness-http
spec:
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
{{< /text >}}

This approach allows you to enable the health check prober rewrite gradually on each deployment without reinstalling Istio.

#### Re-deploy the liveness health check app

Instructions below assume you turn on the feature via Helm flag globally.
Annotations works the same.

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http-same-port.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http-same-port.yaml@)
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

This feature is not currently turned on by default. We'd like to [hear your feedback](https://github.com/istio/istio/issues/10357)
on whether we should change this to default behavior for Istio installation.

### Separate port

Another alternative is to use separate port for health checking and regular traffic.

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

Note that the image in [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) exposes two ports: 8001 and 8002 ([source code]({{< github_file >}}/samples/health-check/server.go)). In this deployment, port 8001 serves the regular traffic while port 8002 is used for liveness probes.

### Cleanup

Remove the mutual TLS policy and corresponding destination rule added in the steps above:

{{< text bash >}}
$ kubectl delete policies default
$ kubectl delete destinationrules default
{{< /text >}}

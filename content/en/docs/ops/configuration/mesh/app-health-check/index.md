---
title: Health Checking of Istio Services
description: Shows how to do health checking for Istio services.
weight: 50
aliases:
  - /docs/tasks/traffic-management/app-health-check/
  - /docs/ops/security/health-checks-and-mtls/
  - /help/ops/setup/app-health-check
  - /help/ops/app-health-check
  - /docs/ops/app-health-check
  - /docs/ops/setup/app-health-check
keywords: [security,health-check]
owner: istio/wg-user-experience-maintainers
test: yes
---

[Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
describes several ways to configure liveness and readiness probes:

1. [Command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)
1. [HTTP request](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request)
1. [TCP probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-tcp-liveness-probe)

The command approach works with no changes required, but HTTP requests and TCP probes require Istio to make changes to the pod configuration.

The health check requests to the `liveness-http` service are sent by Kubelet.
This becomes a problem when mutual TLS is enabled, because the Kubelet does not have an Istio issued certificate.
Therefore the health check requests will fail.

TCP probe checks need special handling, because Istio redirects all incoming traffic into the sidecar, and so all TCP ports appear open.  The Kubelet simply checks if some process is listening on the specified port, and so the probe will always succeed as long as the sidecar is running.

Istio solves both these problems by rewriting the application `PodSpec` readiness/liveness probe,
so that the probe request is sent to the [sidecar agent](/docs/reference/commands/pilot-agent/).
For HTTP requests, the sidecar agent redirects the request to the application and strips the response body, only returning the response code.  For TCP probes, the sidecar agent will then do the port check while avoiding the traffic redirection.

The rewriting of problematic probes is enabled by default in all built-in Istio
[configuration profiles](/docs/setup/additional-setup/config-profiles/) but can be disabled as described below.

## Liveness and readiness probes using the command approach

Istio provides a [liveness sample]({{< github_file >}}/samples/health-check/liveness-command.yaml) that
implements this approach. To demonstrate it working with mutual TLS enabled,
first create a namespace for the example:

{{< text bash >}}
$ kubectl create ns istio-io-health
{{< /text >}}

To configure strict mutual TLS, run:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-io-health"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Next, run the following command to deploy the sample service:

{{< text bash >}}
$ kubectl -n istio-io-health apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

To confirm that the liveness probes are working, check the status of the sample pod to verify that it is running.

{{< text bash >}}
$ kubectl -n istio-io-health get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

## Liveness and readiness probes using the HTTP or TCP approach {#liveness-and-readiness-probes-using-the-http-request-approach}

As stated previously, Istio uses probe rewrite to implement HTTP/TCP probes by default. You can disable this
feature either for specific pods, or globally.

### Disable the probe rewrite for a pod {#disable-the-http-probe-rewrite-for-a-pod}

You can [annotate the pod](/docs/reference/config/annotations/) with `sidecar.istio.io/rewriteAppHTTPProbers: "false"`
to disable the probe rewrite option. Make sure you add the annotation to the
[pod resource](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) because it will be ignored
anywhere else (for example, on an enclosing deployment resource).

{{< text yaml >}}
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
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
EOF
{{< /text >}}

This approach allows you to disable the health check probe rewrite gradually on individual deployments,
without reinstalling Istio.

### Disable the probe rewrite globally

[Install Istio](/docs/setup/install/istioctl/) using `--set values.sidecarInjectorWebhook.rewriteAppHTTPProbe=false`
to disable the probe rewrite globally. **Alternatively**, update the configuration map for the Istio sidecar injector:

{{< text bash >}}
$ kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -
{{< /text >}}

## Cleanup

Remove the namespace used for the examples:

{{< text bash >}}
$ kubectl delete ns istio-io-health
{{< /text >}}

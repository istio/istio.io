---
title: Citadel Health Checking
description: Shows how to enable Citadel health checking with Kubernetes.
weight: 70
keywords: [security,health-check]
---

You can enable Citadel's health checking feature
to detect the failures of the Citadel CSR (Certificate Signing Request) service.
Citadel periodically sends CSRs to its CSR service and verifies the response.

The _prober client_ module in Citadel periodically checks the health status of Citadel's CSR gRPC server.
If Citadel is healthy, the _prober client_ updates the _modification time_ of the _health status file_.
Otherwise, it does nothing. Citadel relies on a
[Kubernetes liveness and readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
with command line to check the _modification time_ of the _health status file_ on the pod.
If the file is not updated for a period, Kubelet will restart the Citadel container.

Note: because Citadel health checking currently only monitors the health status of CSR service API,
this feature is not needed if the production setup is not using the
[SDS](/docs/tasks/security/auth-sds/) or [Mesh Expansion](/docs/setup/kubernetes/additional-setup/mesh-expansion/).

## Before you begin

To complete this task, you can install Istio using one of the following paths:

* To setup Istio without using Helm, follow the instructions in the
  [Kubernetes installation guide](/docs/setup/kubernetes/install/kubernetes/). Remember to enable global mutual TLS with:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

* Use [Helm](/docs/setup/kubernetes/install/helm/) to setup Istio and set the `global.mtls.enabled` flag to `true`.

{{< tip >}}
Use an [authentication policy](/docs/concepts/security/#authentication-policies) to configure mutual TLS for
all or only selected services in a namespace. You must repeat the policy for all namespaces to configure the setting globally.
See the [authentication policy task](/docs/tasks/security/authn-policy/) for details.
{{< /tip >}}

## Deploying Citadel with health checking

To enable health checking, redeploy Citadel using the configuration in `istio-citadel-with-health-check.yaml`:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-citadel-with-health-check.yaml
{{< /text >}}

## Verifying the health checker is working

Citadel will log the health checking results. Run the following in command line:

{{< text bash >}}
$ kubectl logs `kubectl get po -n istio-system | grep istio-citadel | awk '{print $1}'` -n istio-system | grep "CSR signing service"
{{< /text >}}

You will see the output similar to:

{{< text plain >}}
... CSR signing service is healthy (logged every 100 times).
{{< /text >}}

The log above indicates the periodic health checking is working.
The default health checking interval is 15 seconds and is logged once every 100 checks.

## (Optional) Configuring the health checking

This section talks about how to modify the health checking configuration. Open the file
`install/kubernetes/istio-citadel-with-health-check.yaml`, and locate the following lines.

{{< text plain >}}
...
  - --liveness-probe-path=/tmp/ca.liveness # path to the liveness health checking status file
  - --liveness-probe-interval=60s # interval for health checking file update
  - --probe-check-interval=15s    # interval for health status check
livenessProbe:
  exec:
    command:
    - /usr/local/bin/istio_ca
    - probe
    - --probe-path=/tmp/ca.liveness # path to the liveness health checking status file
    - --interval=125s               # the maximum time gap allowed between the file mtime and the current sys clock.
  initialDelaySeconds: 60
  periodSeconds: 60
...
{{< /text >}}

The paths to the health status files are `liveness-probe-path` and `probe-path`.
You should update the paths in Citadel and in the `livenessProbe` at the same time.
If Citadel is healthy, the value of the `liveness-probe-interval` entry determines the interval used to update the
health status file.
The Citadel health checking controller uses the value of the `probe-check-interval` entry to determine the interval to
call the Citadel CSR service.
The `interval` is the maximum time elapsed since the last update of the health status file, for the prober to consider
Citadel as healthy.
The values in the `initialDelaySeconds` and `periodSeconds`entries determine the initial delay and the interval between
each activation of the `livenessProbe`.

Prolonging `probe-check-interval` will reduce the health checking overhead, but there will be a greater lagging for the
prober to get notified on the unhealthy status.
To avoid the prober restarting Citadel due to temporary unavailability, the `interval` on the prober can be
configured to be more than `N` times of the `liveness-probe-interval`. This will allow the prober to tolerate `N-1`
continuously failed health checks.

## Cleanup

*   To disable health checking on Citadel:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

*   To remove Citadel:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-citadel-with-health-check.yaml
    {{< /text >}}

---
title: Citadel Health Checking
description: Shows how to enable Citadel health checking with Kubernetes.
weight: 70
keywords: [security,health-check]
---

Citadel has a health checking feature that can be optionally enabled.
Currently, the health checking feature is able to detect the failures of Citadel CSR signing service,
by periodically sending CSRs to the API and verifying the response.

Citadel contains a _prober client_ module that periodically checks the health status of Citadel's gRPC server.
If Citadel is healthy, the _prober client_ updates the _modification time_ of the _health status file_
(the file is always empty). Otherwise, it does nothing. Citadel relies on a
[Kubernetes liveness and readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
with command line to check the _modification time_ of the _health status file_ on the pod.
If the file is not updated for a period, the probe will be triggered and Kubelet will restart the Citadel container.

Note: because Citadel health checking currently only monitors the health status of CSR service API,
this feature is not needed if the production setup is not using the
[SDS](/docs/tasks/security/auth-sds/) or [Mesh Expansion](/docs/setup/kubernetes/mesh-expansion/).

## Before you begin

* Set up Istio by following the instructions in the
  [Kubernetes quick start](/docs/setup/kubernetes/quick-start/) with global mutual TLS enabled:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

    _**OR**_

    Using [Helm](/docs/setup/kubernetes/helm-install/) with `global.mtls.enabled` set to `true`.

{{< tip >}}
You can use [authentication policy](/docs/concepts/security/#authentication-policies) to configure mutual TLS for
all/selected services in a namespace (repeated for all namespaces to get global setting).
See the [authentication policy task](/docs/tasks/security/authn-policy/) for details.
{{< /tip >}}

## Deploying Citadel with health checking

Redeploy Citadel with health checking enabled.

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
The health checking interval is (by default) 15 seconds. It is logged every 100 times.

## (Optional) Configuring the health checking

Optionally, adjust the health checking configuration to meet your own needs. Open the file
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

The `liveness-probe-path` and `probe-path` are the paths to the health status file, configured at Citadel and the
prober.
The `liveness-probe-interval` is the interval to update the health status file (if Citadel is healthy).
The `probe-check-interval` is the interval for Citadel health checking controller to call the Citadel CSR service.
The `interval` is the maximum time elapsed since the last update of the health status file, for the prober to consider
Citadel as healthy.
`initialDelaySeconds` and `periodSeconds` are the initial delay and the interval between activations of the probe.

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

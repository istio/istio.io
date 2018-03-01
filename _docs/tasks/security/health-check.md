---
title: Enabling Istio CA health check
overview: This task shows how to enable Istio CA health check.

order: 70

layout: docs
type: markdown
---
{% include home.html %}

This task shows how to enable Istio CA health check. Note this is an alpha feature since Istio V0.6.

Since Istio V0.6, Istio CA has a health check feature that can be optionally enabled.
By default, the normal Istio deployment process does not enable this feature.
Currently, the health check feature is able to detect the failures of the CA CSR signing service,
by periodically sending CSRs to the API. More health check features are coming shortly.

The Istio CA contains a _prober client_ module that periodically checks the CA's status (currently only the health
status of the gRPC server).
If the Istio CA is healthy, the _prober client_ updates the _modificate time_ of the _health status file_
(the file is always empty). Otherwise, it does nothing. Istio CA relies on a
[K8s liveness and readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
with command line to check the _modification time_ of the _health status file_ on the pod.
If the file is not updated for a period, the probe will be triggered and Kubelet will restart the CA container.

Note: because the Istio CA health check currently only monitors the health status of CSR service API,
this feature is not needed if the production setup is not using the
[Istio Mesh Expansion]({{home}}/docs/setup/kubernetes/mesh-expansion.html) (which requires the CSR service API).

## Before you begin

* Set up Istio by following the instructions in the
  [quick start]({{home}}/docs/setup/kubernetes/quick-start.html).
  Note that authentication should be enabled at step 5 in the
  [installation steps]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps).

## Deploying the Istio CA with health check

Deploy the Istio CA with health check enabled.

```bash
kubectl apply -f install/kubernetes/istio-ca-with-health-check.yaml
```

Deploy the `istio-ca` service so that the CSR service can be found by the health checker.

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: istio-ca
  namespace: istio-system
  labels:
    istio: istio-ca
spec:
  ports:
    - port: 8060
  selector:
    istio: istio-ca
EOF
```

## Verifying the health checker is working

Isito CA will log the health check results. Run the following in command line:

```bash
kubectl logs `kubectl get po -n istio-system | grep istio-ca | awk '{print $1}'` -n istio-system
```

You will see the output similar to:
```bash
...
2018-02-27T04:29:56.128081Z     info    CSR successfully signed.
...
2018-02-27T04:30:11.081791Z     info    CSR successfully signed.
...
2018-02-27T04:30:25.485315Z     info    CSR successfully signed.
...
```

The log above indicates the periodic health check is working.
Observe that the health check interval is about 15 seconds, which is the default health check interval.

## (Optional) Configuring the health check

Optionally, adjust the health check configuration to meet your own needs. Open the file
`install/kubernetes/istio-ca-with-health-check.yaml`, and locate the following lines.

```bash
...
  - --liveness-probe-path=/tmp/ca.liveness # path to the liveness health check status file
  - --liveness-probe-interval=60s # interval for health check file update
  - --probe-check-interval=15s    # interval for health status check
  - --logtostderr
  - --stderrthreshold
  - INFO
livenessProbe:
  exec:
    command:
    - /usr/local/bin/istio_ca
    - probe
    - --probe-path=/tmp/ca.liveness # path to the liveness health check status file
    - --interval=125s               # the maximum time gap allowed between the file mtime and the current sys clock.
  initialDelaySeconds: 60
  periodSeconds: 60
...
```

The `liveness-probe-path` and `probe-path` are the path to the health status file, configured at the Istio CA and the
prober;
the `liveness-probe-interval` is the interval to update the health status file, if the Istio CA is healthy;
the `probe-check-interval` is the interval for the Istio CA health check.
The `interval` is the maximum time elapsed since the last update of the health status file, for the prober to consider
the Istio CA as healthy.
`initialDelaySeconds` and `periodSeconds` are the intial delay and the probe running period.

Prolonging `probe-check-interval` will reduce the health check overhead, but there will be a greater lagging for the
prober to get notified on the unhealthy status.
To avoid the prober restarting the Istio CA due to temporary unavailablily, the `interval` on the prober can be
configured to be more than `N` times of the `liveness-probe-interval`. This will allow the prober to tolerate `N-1`
continuously failed health checks.

## Cleanup

* To disable health check on the Istio CA:
  ```bash
  kubectl apply -f install/kubernetes/istio-auth.yaml
  kubectl delete svc istio-ca -n istio-system
  ```

* To remove the Istio CA:

  ```bash
  kubectl delete -f install/kubernetes/istio-ca-with-health-check.yaml
  kubectl delete svc istio-ca -n istio-system
  ```

## What's next

* Read the [Istio CA arguments](https://github.com/istio/istio/blob/master/security/cmd/istio_ca/main.go).

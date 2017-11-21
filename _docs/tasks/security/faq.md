---
title: FAQ
overview: Common issues, known limitations and work-around, and other frequently asked questions on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

* _How can I enable/disable mTLS encryption after I installed Istio?_

  The most straightforward way to enable/disable mTLS is by entirely
  uninstalling and re-installing Istio.

  If you are an advanced user and understand the risks you can also do the following:
  ```
  kubectl edit configmap -n istio-system istio
  ```
  comment out or uncomment out `authPolicy: MUTUAL_TLS` to toggle mTLS and then
  ```
  kubectl delete pods -n istio-system -l istio=pilot
  ```
  to restart Pilot, after a few seconds (depending on your `*RefreshDelay`) your
  Envoy proxies will have picked up the change from Pilot. During that time your
  services may be unavailable.

  We are working on a smoother solution.

* _Can a service with Istio Auth enabled communicate with a service without
  Istio?_

  This is not supported currently, but will be in the near future.

* _Can I enable Istio Auth with some services while disable others in the
  same cluster?_

  (Require version 0.3 or above) You can use service-level annotations to disable (or enable) Istio Auth for particular service-port. The annotation key should be `auth.istio.io/{port_number}`, and the value should be `NONE` (to disable), or `MUTUAL_TLS` (to enable).

  Example: disable Istio Auth on port 9080 for service `details`.
  ```yaml
  kind: Service
  metadata:
    name: details
    labels:
      app: details
    annotations:
      auth.istio.io/9080: NONE
  ```

* _How can I use Kubernetes liveness and readiness for service health check
  with Istio Auth enabled?_

  If Istio Auth is enabled, http and tcp health check from kubelet will not
  work since they do not have Istio Auth issued certs. A workaround is to
  use a [liveness command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command)
  for health check, e.g., one can install curl in the service pod and curl itself
  within the pod. The Istio team is actively working on a solution.

  An example of readinessProbe:

  ```
  livenessProbe:
    exec:
      command:
      - curl
      - -f
      - http://localhost:8080/healthz # Replace port and URI by your actual health check
    initialDelaySeconds: 10
    periodSeconds: 5
  ```

* _Can I access the Kubernetes API Server with Auth enabled?_

  No. Kubernetes API server does not have Istio sidecar so it cannot handle requests from a pod with Istio sidecar and mTLS enable. However, starting v0.3, we will have option to disable Istio Auth for traffic to API server (or any other similar control services). See the next question for more details.

* _How to disable Auth on clients to access the Kubernetes API Server?_  

  In Istio v0.3 and above, we add option to the Istio configmap to specify services that do not accept mTLS. The default list contains `kubernetes.default.svc.cluster.local`, which is a typical Kubernetes API server service name.

  If the API server has different name in your system, or you want to exclude mTLS for more control services, edit the `mtlsExcludedServices` in the Istio config map and restart pilot.
  ```bash
  kubectl edit configmap -n istio-system istio

  kubectl delete pods -n istio-system -l istio=pilot
  ```

  > Note: DO NOT use this setting for services that are managed by Istio (i.e. using Istio sidecar). Instead, use service-level annotations to overwrite the authentication policy (see above).

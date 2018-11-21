---
title: Requirements for Pods and Services
description:  Describes the requirements for Kubernetes pods and services to run Istio.
weight: 80
keywords: [kubernetes,sidecar,sidecar-injection]
---

To be a part of the service mesh, pods and services in a Kubernetes
cluster must satisfy the following requirements:

* _**Named ports**:_ Service ports must be named. The port names must be of
  the form `<protocol>[-<suffix>]` with _http_, _http2_, _grpc_, _mongo_, or _redis_
  as the `<protocol>` in order to take advantage of Istio's routing features.
  For example, `name: http2-foo` or `name: http` are valid port names, but
  `name: http2foo` is not.  If the port name does not begin with a recognized
  prefix or if the port is unnamed, traffic on the port will be treated as
  plain TCP traffic (unless the port [explicitly](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service)
  uses `Protocol: UDP` to signify a UDP port).

* _**Service association**:_ If a pod belongs to multiple
  [Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/),
  the services cannot use the same port number for different protocols, for instance HTTP and TCP.

* _**Deployments with app and version labels**:_ It is recommended that pods deployed using
  the Kubernetes `Deployment` have an explicit `app` label and `version` label in the
  deployment specification. Each deployment specification should have a
  distinct `app` label with a value indicating something meaningful, with `version`
  indicating the version of the app that the particular deployment corresponds to. The
  `app` label is used to add contextual information in distributed
  tracing. The `app` and `version` labels are also used to add contextual information
  in the metric telemetry collected by Istio.

* _**`NET_ADMIN` capability**:_ If
  [pod security policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)
  are [enforced](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies) in your
  cluster, your pods must have the `NET_ADMIN` capability allowed. The initialization containers of
  the Envoy proxies require this capability. To check which capabilities are allowed for your pods, check if their
  [service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) can use a
  pod security policy that allows the `NET_ADMIN` capability.
  If you don't specify a service account in your pods' deployment, the pods run as the `default` service account in
  their deployment's namespace.
  To check which capabilities are allowed for the service account of your pods, run the following command:

    {{< text bash >}}
    $ for psp in $(kubectl get psp); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:<your namespace>:<your service account>) = yes ]; then kubectl get psp $psp -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

    For example, to check which capabilities are allowed for the `default` service account in the `default` namespace,
    run the following command:

    {{< text bash >}}
    $ for psp in $(kubectl get psp); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:default:default) = yes ]; then kubectl get psp $psp -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
    {{< /text >}}

    If you see `NET_ADMIN` or `*` in the list of capabilities of one of the allowed policies for your service account,
    your pods have permission to run the Istio init containers. Otherwise, you must
    [provide such permission](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies).

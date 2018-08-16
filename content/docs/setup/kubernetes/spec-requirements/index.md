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

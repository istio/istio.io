---
title: Overview
description: Provides a conceptual overview of traffic management in Istio and the features it enables.

weight: 1

---

{% include home.html %}

This page provides an overview of how traffic management works
in Istio, including the benefits of its traffic management
principles. It assumes that you've already read [What Is Istio?]({{home}}/docs/concepts/what-is-istio/overview.html)
and are familiar with Istio's high-level architecture. You can
find out more about individual traffic management features in the other
guides in this section.

## Pilot and Envoy

The core component used for traffic management in Istio is
[Pilot](./pilot.html), which manages and configures all the Envoy
proxy instances deployed in a particular Istio service mesh. It lets you
specify what rules you want to use to route traffic between Envoy proxies
and configure failure recovery features such as timeouts, retries, and
circuit breakers. It also maintains a canonical model of all the services
in the mesh and uses this to let Envoys know about the other instances in
the mesh via its discovery service.

Each Envoy instance maintains [load balancing information](./load-balancing.html)
based on the information it gets from Pilot and periodic health-checks
of other instances in its load-balancing pool, allowing it to intelligently
distribute traffic between destination instances while following its specified
routing rules.

## Traffic management benefits

Using Istio's traffic management model essentially decouples traffic flow
and infrastructure scaling, letting operators specify via Pilot what
rules they want traffic to follow rather than which specific pods/VMs should
receive traffic - Pilot and intelligent Envoy proxies look after the
rest. So, for example, you can specify via Pilot that you want 5%
of traffic for a particular service to go to a canary version irrespective
of the size of the canary deployment, or send traffic to a particular version
depending on the content of the request.

{% include figure.html width='85%' ratio='69.52%'
    img='./img/pilot/TrafficManagementOverview.svg'
    alt='Traffic Management with Istio'
    title='Traffic Management with Istio'
    caption='Traffic Management with Istio'
    %}

Decoupling traffic flow from infrastructure scaling like this allows Istio
to provide a variety of traffic management features that live outside the
application code. As well as dynamic [request routing](request-routing.html)
for A/B testing, gradual rollouts, and canary releases, it also handles
[failure recovery](handling-failures.html) using timeouts, retries, and
circuit breakers, and finally [fault injection](fault-injection.html) to
test the compatibility of failure recovery policies across services. These
capabilities are all realized through the Envoy sidecars/proxies deployed
across the service mesh.


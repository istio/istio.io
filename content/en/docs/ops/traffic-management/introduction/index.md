---
title: Introduction to Network Operations
description: An introduction to Istio networking operational aspects.
weight: 1
aliases:
    - /help/ops/traffic-management/introduction
    - /help/ops/introduction
---
This section is intended as a guide to operators of an Istio based
deployment.  It will provide information an operator of a Istio deployment
would need to manage the networking aspects of an Istio service mesh.  Much
of the information and many of the procedures that an Istio operator
would require are already documented in other sections of the Istio
documentation so this section will rely heavily on pointers to that
other content.

## Key Istio concepts

When attempting to understand, monitor or troubleshoot the networking within
an Istio deployment it is critical to understand the fundamental Istio
concepts starting with the service mesh.  The service mesh is described
in [Architecture]/docs/ops/architecture/).  As noted
in the architecture section Istio has a distinct control plane and a data
plane and operationally it will be important to be able to monitor the
network state of both.  The service mesh is a fully interconnected set of
proxies that are utilized in both the control and data plane to provide
the Istio features.

Another key concept to understand is how Istio performs traffic management.
This is described in [Traffic Management Explained](/docs/concepts/traffic-management).
Traffic management allows fine grained control with respect to what external
traffic can enter or exit the mesh and how those requests are routed.  The
traffic management configuration also dictates how requests between
microservices within the mesh are handled.  Full details on how to
configure the traffic management is available
here: [Traffic Management Configuration](/docs/tasks/traffic-management).

The final concept that is essential for the operator to understand is how
Istio uses gateways to allow traffic into the mesh or control how requests originating
in the mesh access external services. This is described with a
configuration example here:
[Istio Gateways](/docs/concepts/traffic-management/#gateways)

## Network layers beneath the mesh

Istio's service mesh runs on top of the networking provided by the
infrastructure environment (e.g. Kubernetes) on which the Istio mesh
is deployed.  Istio has certain requirements of this networking layer.
This guide will not attempt to provide any operational insight to this
networking layer as many options exist.  In the case of Kubernetes a
good reference to understand the container networking layer is
[Kubernetes Cluster Operator](https://kubernetes.io/docs/user-journeys/users/cluster-operator/foundational/).
Istio has the following requirements of the networking infrastructure
underneath it:

* The mapping of a service name to workload IP is discoverable by Pilot (this is more a service discovery requirement than a networking requirement)

* The Pilot discovery process can reach the environment specific API server for service discovery.

* Service endpoints have L3 reachability to all endpoints for services in the Istio mesh.

* Any firewall or ACL rules at the infrastructure networking layer don't conflict with any of the Istio layer 3-7 traffic management rules

* Any firewall or ACL rules at the infrastructure networking layer don't conflict with any of the ports used for Istio control traffic

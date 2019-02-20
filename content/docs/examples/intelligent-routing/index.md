---
title: Intelligent Routing
description: Demonstrates how to use various traffic management capabilities of an Istio service mesh.
weight: 20
keywords: [traffic-management,routing]
aliases:
    - /docs/guides/intelligent-routing/index.html
---

This example demonstrates how to use various traffic management capabilities
of an Istio service mesh.

## Overview

Deploying a microservice-based application in an Istio service mesh allows one
to externally control service monitoring and tracing, request (version) routing, resiliency testing,
security and policy enforcement, etc., in a consistent way across the services,
for the application as a whole.

In this example, we will use the [Bookinfo sample application](/docs/examples/bookinfo/)
to show how operators can dynamically configure request routing and fault injection
for a running application.

## Before you begin

* Install the Istio control plane by following the instructions
  corresponding to your platform [installation guide](/docs/setup/).

* Run the Bookinfo sample application by following the applicable
  [application deployment instructions](/docs/examples/bookinfo/#deploying-the-application).

## Tasks

1. [Request routing](/docs/tasks/traffic-management/request-routing/) This task will first
   direct all incoming traffic for the Bookinfo application to the v1 version of the
   `reviews` service. It will then send traffic only from a specific test user to version v2,
   leaving all other users unaffected.

1. [Fault injection](/docs/tasks/traffic-management/fault-injection/) We will now use Istio to
   test the resiliency of the Bookinfo application by injecting an artificial delay in
   requests between the `reviews:v2` and `ratings` services. Observing the resulting behavior
   as the test user, we will notice that the v2 version of the `reviews` service has a bug.
   Note that all other users are unaware of this testing against the live system.

1. [Traffic Shifting](/docs/tasks/traffic-management/traffic-shifting/) Finally, we will
   use Istio to gradually migrate traffic for all users from v2 to a v3 version of
   the `reviews` service, one which includes the fix for the bug discovered in v2.

## Cleanup

When you're finished experimenting with the Bookinfo sample, you can
uninstall it by following the
[Bookinfo cleanup instructions](/docs/examples/bookinfo/#cleanup)
corresponding to your environment.

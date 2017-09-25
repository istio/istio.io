---
title: Intelligent Routing
overview: This guide demonstrates how to use various traffic management capabilities of an Istio service mesh.

order: 20
layout: docs
type: markdown
---
{% include home.html %}

This guide demonstrates how to use various traffic management capabilities
of an Istio service mesh.

## Overview

Deploying a microservice-based application in an Istio service mesh allows one
to externally control service monitoring and tracing, request (version) routing, resilience testing,
security and policy enforcement, etc., in a consistent way across the services,
for the application as a whole.

In this guide, we will use the [Bookinfo sample application]({{home}}/docs/guides/bookinfo.html)
to show how operators can dynamically configure request routing and fault injection
for a running application.

## Before you begin

* Install the Istio control plane by following the instructions
  corresponding to your platform [installation guide]({{home}}/docs/setup/).

* Run the Bookinfo sample application by following the applicable
  [application deployment instructions]({{home}}/docs/guides/bookinfo.html#deploying-the-application).

## Tasks

1. [Request routing]({{home}}/docs/tasks/request-routing.html) This task will first
   direct all incoming traffic for the Bookinfo application to the v1 version of the
   reviews service. It will then send traffic only from a specific test user to version v2,
   leaving all other users unaffected.

1. [Fault injection]({{home}}/docs/tasks/fault-injection.html) We will now use Istio to
   test the resiliency of the Bookinfo application by injecting and artificial delay in
   requests between the reviews:v2 and ratings services. Observing the resulting behavior,
   as the test user, we will notice that the v2 version of the reviews service has a bug.
   Note that all other users are oblivious to this testing against the live system.

1. [Version migration]({{home}}/docs/tasks/version-migration.html) Finally, we will
   use Istio to gradually migrate traffic for all users from to the v3 version of
   the reviews service, which includes the fix for the bug discovered in v2.

## Cleanup

When you're finished experimenting with the BookInfo sample, you can
uninstall it by following the
[Bookinfo cleanup instructions]({{home}}/docs/guides/bookinfo.html#cleanup)
corresponding to your environment.

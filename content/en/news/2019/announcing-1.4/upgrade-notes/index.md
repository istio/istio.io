---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.4.
weight: 20
---

This page describes changes you need to be aware of when upgrading from
Istio 1.3 to 1.4.  Here, we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.3.

## Traffic Management

Services of type `http` are no longer allowed on port 443. This change was made to prevent protocol conflicts with external HTTPS services.

If you depend on this behavior, there are a few options:

* Move the application to another port.
* Change the protocol from type `http` to type `tcp`
* Specify the environment variable `PILOT_BLOCK_HTTP_ON_443=false` to the Pilot deployment. Note: this may be removed in future releases.

See [Protocol Selection](/docs/ops/traffic-management/protocol-selection/) for more information about specifying the protocol of a port

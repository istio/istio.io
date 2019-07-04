---
title: Secure Control of Egress Traffic in Istio, part 3
subtitle: Use Istio Egress Traffic Control to prevent attacks involving egress traffic
description: Use Istio Egress Traffic Control to prevent attacks involving egress traffic.
publishdate: 2019-07-16
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,egress,security,gateway,tls]
---

Welcome to part 3 in our new series about secure control of egress traffic in Istio.
In [the first part in the series](/blog/2019/egress-traffic-control-in-istio-part-1/), I presented the attacks involving
egress traffic and the requirements we collected for a secure control system for egress traffic.
In [the second part in the series](/blog/2019/egress-traffic-control-in-istio-part-2/), I presented the Istio way of
securing egress traffic and showed how you can prevent the attacks using Istio.

In this installment, I compare secure control of egress traffic in Istio with alternative solutions such as Kubernetes
Network Policies and legacy egress proxies/firewalls.

## Summary

Hopefully, I managed to convince you that Istio is an effective tool to prevent attacks involving egress
traffic.

---
title: "Regression in Istio 1.14.2 and Istio 1.13.6"
description: "CVE-2022-31045 found in latest Istio 1.14.2 and Istio 1.13.6"
publishdate: 2022-07-26
attribution: "Jacob Delgado"
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

## Do not use Istio 1.14.2 and Istio 1.13.6

Due to a process issue, [CVE-2022-31045](news/security/istio-security-2022-005/#cve-2022-31045) was not included in our Istio 1.14.2 and Istio 1.13.6 builds.

At this time we suggest you do not install it in a production environment or downgrade to Istio 1.14.1 or Istio 1.13.5 until
Istio 1.14.3 and Istio 1.13.7 are released later this week.

We apologize for this inconvience.

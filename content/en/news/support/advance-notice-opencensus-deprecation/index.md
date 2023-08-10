---
title: Advance notice of Istio deprecating OpenCensus
subtitle: Support Announcement
description: Advance notice of Istio deprecating OpenCensus.
publishdate: 2023-08-17
---

OpenCensus has [sunsetted](https://opentelemetry.io/blog/2023/sunsetting-opencensus) on July 31st, 2023.

The OpenCensus sunsetting will impact Istio's usage of OpenCensus in tracing, logging, and metrics. Istio
plans to use OpenTelemetry exporters with the OpenTelemetry collector to provide matching telemetry capabilities.

This is an advance notice of Istio deprecating OpenCensus, which is tentatively scheduled to Oct. 10, 2024.
At that point Istio will stop supporting OpenCensus, so we encourage you to start planning the transition to
OpenTelemetry in Istio. If you don't plan this, you may put yourself in the position of having to do a major upgrade on a short timeframe.

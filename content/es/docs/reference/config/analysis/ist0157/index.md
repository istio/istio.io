---
title: InvalidTelemetryProvider
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a Telemetry resource with empty providers is set, and it will be ignored if the `defaultProviders` in MeshConfig is empty.

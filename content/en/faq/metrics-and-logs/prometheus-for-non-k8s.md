---
title: Can the Prometheus adapter be used in non-Kubernetes environments?
weight: 60
test: n/a
---

You can use docker-compose to install Prometheus. Also,
without the Kubernetes API server, components such as Mixer will need local configuration for rules/handlers/instances.

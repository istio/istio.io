---
title: Can the Prometheus adapter be used in non-Kubernetes environments?
weight: 60
---

You can use docker-compose to install Prometheus, similar to when you [install](/docs/setup/consul/quick-start/#deploy-your-application) your application. Also,
without the Kubernetes API server, components such as Mixer will need local configuration for rules/handlers/instances.

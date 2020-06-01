---
title: Reworking our Addon Integrations
description: A new way to manage installation of telemetry addons.
publishdate: 2020-06-10
attribution: John Howard (Google)
keywords: [telemetry,addons,integrations,grafana,prometheus]
target_release: 1.6
test: n/a
---

In Istio 1.6, we are introducing a new method for integration with telemetry addons (Grafana, Prometheus, Zipkin, Jaeger, Kiali, etc).

In previous releases, these addons were bundled as part of the Istio installation. At the time, this was incredibly useful as it allowed users to quickly get started without dealing with complicated configurations to install and integrate with these applications. However, it came with a number of issues. Our installations were not as up to date or feature rich as upstream installation methods, meaning users were left missing out on some of the great features provided by these applications such as persistent storage, features like `Alertmanager` for Prometheus, and advanced security settings. Additionally, integration with existing deployments that were using these features was more challenging than it should be.

## Changes

In order to address these gaps, we have made a number of changes:
* Added a new [Integrations](/docs/ops/integrations/) documentation section to explain what applications Istio can integrate with, how to use them, and best practices.
* Reduced the amount of configuration required to set up telemetry Addons
  * Grafana dashboards are now [published to `grafana.com`](/docs/ops/integrations/grafana/#import-from-grafana-com).
  * Prometheus can now scrape all Istio pods [using standard `prometheus.io` annotations](/docs/ops/integrations/prometheus/#option-2-metrics-merging). This allows most Prometheus deployments to work with Istio without any special configuration.
* We are removing the bundled addon installations as part of istioctl and the operator. Istio will not concern itself with installing components that are not delivered by the Istio project. As a result, Istio will stop shipping installation artifacts related to addons. Istio will guarantee version compatibility where necessary. It is the user's responsibility to install these components using official documentation and artifacts provided by the respective projects, following the [Integrations](/docs/ops/integrations/) documentation. For demos, users can deploy simple yaml files from the `samples/addons/` folder.

We hope these changes allow users to make the most of these addons to fully experience what Istio can offer.

## Timeline

* Istio 1.6: the new demo deployments are available under `samples/addons/` directory.
* Istio 1.7: Upstream installation methods or the new samples deployment are the recommended installation methods. Installation by istioctl is deprecated.
* Istio 1.8: Installation of addons by istioctl is removed.


---
title: Reworking our Addon Integrations
description: A new way to manage installation of telemetry addons.
publishdate: 2020-06-04
attribution: John Howard (Google)
keywords: [telemetry,addons,integrations,grafana,prometheus]
---

Starting with Istio 1.6, we are introducing a new method for integration with telemetry addons, such as Grafana, Prometheus, Zipkin, Jaeger, and Kiali.

In previous releases, these addons were bundled as part of the Istio installation. This allowed users to quickly get started with Istio without any complicated configurations to install and integrate these addons. However, it came with some issues:

* The Istio addon installations were not as up to date or feature rich as upstream installation methods. Users were left missing out on some of the great features provided by these applications, such as:
    * Persistent storage
    * Features like `Alertmanager` for Prometheus
    * Advanced security settings
*  Integration with existing deployments that were using these features was more challenging than it should be.

## Changes

In order to address these gaps, we have made a number of changes:

* Added a new [Integrations](/docs/ops/integrations/) documentation section to explain which applications Istio can integrate with, how to use them, and best practices.

* Reduced the amount of configuration required to set up telemetry addons

    * Grafana dashboards are now [published to `grafana.com`](/docs/ops/integrations/grafana/#import-from-grafana-com).

    * Prometheus can now scrape all Istio pods [using standard `prometheus.io` annotations](/docs/ops/integrations/prometheus/#option-2-metrics-merging). This allows most Prometheus deployments to work with Istio without any special configuration.

* Removed the bundled addon installations from `istioctl` and the operator. Istio does not install components that are not delivered by the Istio project. As a result, Istio will stop shipping installation artifacts related to addons. However, Istio will guarantee version compatibility where necessary. It is the user's responsibility to install these components by using the official [Integrations](/docs/ops/integrations/) documentation and artifacts provided by the respective projects. For demos, users can deploy simple YAML files from the [`samples/addons/` directory]({{< github_tree >}}/samples/addons).

We hope these changes allow users to make the most of these addons so as to fully experience what Istio can offer.

## Timeline

* Istio 1.6: The new demo deployments for telemetry addons are available under `samples/addons/` directory.
* Istio 1.7: Upstream installation methods or the new samples deployment are the recommended installation methods. Installation by `istioctl` is deprecated.
* Istio 1.8: Installation of addons by `istioctl` is removed.

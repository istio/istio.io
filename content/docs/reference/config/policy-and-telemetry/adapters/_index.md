---
title: Adapters
description: Mixer adapters allow Istio to interface to a variety of infrastructure backends for such things as metrics and logs.
weight: 40
type: section-index
aliases:
    - /docs/reference/config/mixer/adapters/index.html
    - /docs/reference/config/adapters/
---

## The relationship between adapters and templates

|Adapter|Kind|Template|
|---|---|---|
|[`Apigee`](/docs/reference/config/policy-and-telemetry/adapters/apigee/)|`apigee`|[`authorization`](/docs/reference/config/policy-and-telemetry/templates/authorization/), [analytics](/docs/reference/config/policy-and-telemetry/templates/analytics/)|
|[`Circonus`](/docs/reference/config/policy-and-telemetry/adapters/circonus/)|`circonus`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/)|
|[`CloudMonitor`](/docs/reference/config/policy-and-telemetry/adapters/cloudmonitor/)|`cloudmonitor`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/)|
|[`CloudWatch`](/docs/reference/config/policy-and-telemetry/adapters/cloudwatch/)|`cloudwatch`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/)|
|[`Datadog`](/docs/reference/config/policy-and-telemetry/adapters/datadog/)|`dogstatsd`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/)|
|[`Denier`](/docs/reference/config/policy-and-telemetry/adapters/denier)|`denier`|[`checknothing`](/docs/reference/config/policy-and-telemetry/templates/checknothing/), [`listentry`](/docs/reference/config/policy-and-telemetry/templates/listentry/), [`quota`](/docs/reference/config/policy-and-telemetry/templates/quota/)|
|[`Fluentd`](/docs/reference/config/policy-and-telemetry/adapters/fluentd/)|`fluentd`|[`logentry`](/docs/reference/config/policy-and-telemetry/templates/logentry/)|
|[`Kubernetes Env`](/docs/reference/config/policy-and-telemetry/adapters/kubernetesenv/)|`kubernetesenv`|[`kubernetesenv`](/docs/reference/config/policy-and-telemetry/templates/kubernetes/)|
|[`List`](/docs/reference/config/policy-and-telemetry/adapters/list/)|`list`|[`listentry`](/docs/reference/config/policy-and-telemetry/templates/listentry/)|
|[`Memory quota`](/docs/reference/config/policy-and-telemetry/adapters/memquota/)|`memquota`|[`quota`](/docs/reference/config/policy-and-telemetry/templates/quota/)|
|[`OPA`](/docs/reference/config/policy-and-telemetry/adapters/opa/)|`opa`|[`authorization`](/docs/reference/config/policy-and-telemetry/templates/authorization/)|
|[`Prometheus`](/docs/reference/config/policy-and-telemetry/adapters/prometheus/)|`prometheus`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/)|
|[`RBAC`](/docs/reference/config/policy-and-telemetry/adapters/rbac/)|`rbac`|[`authorization`](/docs/reference/config/policy-and-telemetry/templates/authorization/)|
|[`Redis Quota`](/docs/reference/config/policy-and-telemetry/adapters/redisquota/)|`redisquota`|[`quota`](/docs/reference/config/policy-and-telemetry/templates/quota/)|
|[`Service Control`](/docs/reference/config/policy-and-telemetry/adapters/servicecontrol/)|`servicecontrol`|[`servicecontroller`](/docs/reference/config/policy-and-telemetry/templates/servicecontrolreport/), [`quota`](/docs/reference/config/policy-and-telemetry/templates/quota/), [`apikey`](/docs/reference/config/policy-and-telemetry/templates/apikey/)|
|[`SignalFx`](/docs/reference/config/policy-and-telemetry/adapters/signalfx/)|`signalfx`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/), [`tracespan`](/docs/reference/config/policy-and-telemetry/templates/tracespan/)|
|[`SolarWinds`](/docs/reference/config/policy-and-telemetry/adapters/solarwinds/)|`solarwinds`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/), [`logentry`](/docs/reference/config/policy-and-telemetry/templates/logentry/)|
|[`Stackdriver`](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/)|`stackdriver`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/), [`logentry`](/docs/reference/config/policy-and-telemetry/templates/logentry/), [`tracespan`](/docs/reference/config/policy-and-telemetry/templates/tracespan/)|
|[`StatsD`](/docs/reference/config/policy-and-telemetry/adapters/statsd/)|`statsd`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/)|
|[`Stdio`](/docs/reference/config/policy-and-telemetry/adapters/stdio/)|`stdio`|[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/), [`logentry`](/docs/reference/config/policy-and-telemetry/templates/logentry/)|

To implement a new adapter for Mixer, please refer to the
[Adapter Developer's Guide](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide).

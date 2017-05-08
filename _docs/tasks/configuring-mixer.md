---
title: Configuring Mixer
overview: Shows how to configure Mixer.
          
order: 38

layout: docs
type: markdown
---
{% include home.html %}
{% capture aspectConfig %}{{home}}/docs/reference/api/mixer/aspects{% endcapture %}
{% capture adapterConfig %}{{home}}/docs/reference/api/mixer/adapters{% endcapture %}
{% capture mixerConfig %}{{home}}/docs/reference/api/mixer/mixer-config.html{% endcapture %}

This task shows how to configure Mixer.

## Before you begin

* [Install Istio](./installing-istio.html) in your kubernetes
  cluster.

* Deploy the [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application.

* Initialize the application version routing by running the following
  commands:
  
  ```bash
  istioctl create -f route-rule-all-v1.yaml
  istioctl replace -f route-rule-reviews-v2-v3.yaml
  ```

## Overview

Mixer configuration expresses system behavior by specifying three 
key pieces of information: **what** action to take, **how** to take that action, and **when** to take that action.

* **What action to take:** _Aspect_ configuration defines _what_ action to take. These actions include
      logging, metrics collection, list checks, quota enforcement and others. 
      _Descriptors_ are named and re-usable parts of the aspect configuration.
      For example the `metrics` aspect defines the [`MetricDescriptor`]({{mixerConfig}}#istio.mixer.v1.config.descriptor.MetricDescriptor) and refers to the MetricDescriptor instances by name.

* **How to take that action:** _Adapter_ configuration defines _how_ to take an action.
      The metrics adapter configuration includes details of the infrastructure backends.

* **When to take that action:** `Selectors` and `subjects` define _when_ to take an action.
      Selectors are attribute-based expressions like `response.code == 200` and Subjects
      are hierarchical resource names like `myservice.namespace.svc.cluster.local`.


## Configuration steps

Consider the following aspect configuration that [enables rate limits](./rate-limiting.md).
```yaml
- aspects:
  - kind: quotas
    params:
      quotas:
      - descriptorName: RequestCount
        maxAmount: 5
        expiration: 1s
        labels:
          label1: target.service
```
It _uses_ `RequestCount` to describe the quota. 
The following is an example of the `RequestCount` descriptor.
```yaml
name: RequestCount
rate_limit: true
labels:
   label1: 1 # STRING
```
In this example, `rate_limit` is `true`, hence the `aspect` must specify an `expiration`.
Similarly, the `aspect` must supply one label of type `string`.
 
Mixer delegates the work of applying rate limits to an `adapter` that implements the `quotas` kind. 
`Adapters.yml` defines this configuration.

```yaml
- name: default
  kind: quotas
  impl: memQuota
  params:
    minDeduplicationDuration: 2s
```

The `memQuota` adapter in the above example takes one parameter. An operator may switch from 
`memQuota` to `redisQuota` by specifying an alternate `quotas` adapter.

```yaml
- name: default
  kind: quotas
  impl: redisQuota
  params:
    redisServerUrl: redisHost:6379
    minDeduplicationDuration: 2s
```

The following example shows how to use a `selector` to apply rate limits selectively.

```yaml
- selector: source.labels["app"]=="reviews" && source.labels["version"] == "v3"  
  aspects:
  - kind: quotas
    params:
      quotas:
      - descriptorName: RequestCount
        maxAmount: 5
        expiration: 1s
        labels:
          label1: target.service
```

## Aspect associations 
The steps outlined in the previous section apply to all of Mixer's aspects.
Each aspect requires specific `desciptors` and `adapters`.
The following table enumerates valid combinations of the `aspects`, the `descriptors` and the `adapters`.


|Aspect   |Descriptors               |Adapters
|-----------------------------------------------
|[Quota enforcement]({{aspectConfig}}/quotas.html ) | [QuotaDescriptor]({{mixerConfig}}#istio.mixer.v1.config.descriptor.QuotaDescriptor) |  [memQuota]({{adapterConfig}}/memQuota.html), [redisQuota]({{adapterConfig}}/redisQuota.html) 
|[Metrics collection]({{aspectConfig}}/metrics.html)| [MetricDescriptor]({{mixerConfig}}#metricdescriptor) |[prometheus]({{adapterConfig}}/prometheus.html),[statsd]({{adapterConfig}}/statsd.html)  
|[Whitelist/Blacklist]({{aspectConfig}}/lists.html)| None |[genericListChecker]({{adapterConfig}}/genericListChecker.html),[ipListChecker]({{adapterConfig}}/ipListChecker.html)  
|[Access logs]({{aspectConfig}}/accessLogs.html)|[LogEntryDescriptor]({{mixerConfig}}#logentrydescriptor)  |[stdioLogger]({{adapterConfig}}/stdioLogger.html)
|[Application logs]({{aspectConfig}}/applicationLogs.html)|[LogEntryDescriptor]({{mixerConfig}}#logentrydescriptor)  |[stdioLogger]({{adapterConfig}}/stdioLogger.html)
|[Deny Request]({{aspectConfig}}/denials.html)| None |[denyChecker]({{adapterConfig}}/denyChecker.html)

Istio uses [`protobufs`](https://developers.google.com/protocol-buffers/) to define configuration schemas. The [Writing Configuration]({{home}}/docs/reference/writing-config.html) document explains how to express `proto` definitions as `yaml`.


## Organization of configuration
Aspect configuration applies to a `subject`. A `Subject` is a resource in a hierarchy.
Typically `subject` is the fully qualified name of a service, namespace or a cluster. An aspect configuration may apply
to the `subject` resource and its sub-resources.

## Pushing configuration
`istioctl` pushes configuration changes to the API server.
As of the alpha release, the API server supports pushing only aspect rules. 

A temporary workaround allows you to push `adapters.yml` and `descriptors.yml` as follows.
1. Find the mixer pod
    ```
    kubectl get pods -l istio=mixer
    NAME                           READY     STATUS    RESTARTS   AGE
    istio-mixer-2657627433-3r0nn   1/1       Running   0          2d
    ```
2. Fetch adapters.yml from Mixer
    ```
    kubectl cp istio-mixer-2657627433-3r0nn:/etc/opt/mixer/configroot/scopes/global/adapters.yml  adapters.yml
    ```

3. Edit the file and push it back.
    ```
    kubectl cp adapters.yml istio-mixer-2657627433-3r0nn:/etc/opt/mixer/configroot/scopes/global/adapters.yml 
    ```
4. `/etc/opt/mixer/configroot/scopes/global/descriptors.yml` is similarly updated.
5. View Mixer logs to see validation errors since the above operation bypasses the API server.

## Default configuration
Mixer provides default definitions for commonly used 
[descriptors](https://github.com/istio/mixer/blob/master/testdata/configroot/scopes/global/descriptors.yml) and 
[adapters](https://github.com/istio/mixer/blob/master/testdata/configroot/scopes/global/adapters.yml).

## What's next

* Learn more about [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Mixer Config]({{home}}/docs/concepts/policy-and-control/mixer-config.html).
* Discover the full [Attribute Vocabulary]({{home}}/docs/reference/api/mixer/attribute-vocabulary.html).

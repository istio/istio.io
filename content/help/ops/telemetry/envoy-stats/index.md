---
title: Envoy Statistics
description: Fine-grained control of Envoy statistics.
weight: 95
---

The Envoy proxy keeps detailed statistics about network traffic.

Envoy's statistics only cover the traffic for a particular Envoy instance.  See
[Telemetry](/docs/tasks/telemetry/) for persistent per-service Istio telemetry.  The
statistics recorded by Envoy can provide more information about specific pod instances.

To see the statistics for a pod,

```
kubectl exec -it $POD  -c istio-proxy  -- sh -c 'curl localhost:15000/stats'
```

See [the Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/cluster_manager/cluster_stats) for an explanation of the data recorded.

By default, Istio configures Envoy to record minimal statistics.  The default collection
keys are `cluster_manager`, `listener_manager`, `http_mixer_filter`, `tcp_mixer_filter`, `server`, and `cluster.xds-grpc`.  To see the Envoy settings for collection use  
`istioctl proxy-config bootstrap` following [these instructions](https://istio.io/help/ops/traffic-management/proxy-cmd/).
Consult the `statsMatcher` JSON element.

Configure Envoy to record statistics for inbound or outbound traffic by adding the
`sidecar.istio.io/statsInclusionPrefixes` annotation to the pod template in a Kubernetes Deployment.
Add `cluster.outbound` for gather data about outbound traffic activity and circuit breaking.
To gather data on inbound traffic add `listener`.  A sample annotation including `cluster.outbound`
can be seen in _samples/httpbin/sample-client/fortio-deploy.yaml_.

You can cause Envoy to gather less data than usual by overriding the defaults.  Use
`sidecar.istio.io/statsInclusionPrefixes: cluster_manager,listener_manager` for the least possible statistics
collection.

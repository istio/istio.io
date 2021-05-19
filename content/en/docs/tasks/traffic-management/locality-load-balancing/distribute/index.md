---
title: Locality weighted distribution
description: This guide demonstrates how to configure locality distribution.
weight: 20
keywords: [locality,load balancing,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---
Follow this guide to configure the distribution of traffic across localities.

Before proceeding, be sure to complete the steps under
[before you begin](/docs/tasks/traffic-management/locality-load-balancing/before-you-begin).

In this task, you will use the `Sleep` pod in `region1` `zone1` as the source of
requests to the `HelloWorld` service. You will configure Istio with the following
distribution across localities:

Region | Zone | % of traffic
------ | ---- | ------------
`region1` | `zone1` | 70
`region1` | `zone2` | 20
`region2` | `zone3` | 0
`region3` | `zone4` | 10

## Configure Weighted Distribution

Apply a `DestinationRule` that configures the following:

- [Outlier detection](/docs/reference/config/networking/destination-rule/#OutlierDetection)
  for the `HelloWorld` service. This is required in order for distribution to
  function properly. In particular, it configures the sidecar proxies to know
  when endpoints for a service are unhealthy.

- [Weighted Distribution](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/locality_weight.html?highlight=weight)
  for the `HelloWorld` service as described in the table above.

{{< text bash >}}
$ kubectl --context="${CTX_PRIMARY}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      localityLbSetting:
        enabled: true
        distribute:
        - from: region1/zone1/*
          to:
            "region1/zone1/*": 70
            "region1/zone2/*": 20
            "region3/zone4/*": 10
    outlierDetection:
      consecutive5xxErrors: 100
      interval: 1s
      baseEjectionTime: 1m
EOF
{{< /text >}}

## Verify the distribution

Call the `HelloWorld` service from the `Sleep` pod:

{{< text bash >}}
$ kubectl exec --context="${CTX_R1_Z1}" -n sample -c sleep \
  "$(kubectl get pod --context="${CTX_R1_Z1}" -n sample -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.sample:5000/hello
{{< /text >}}

Repeat this a number of times and verify that the number of replies
for each pod match the expected percentage in the table at the top of
this guide.

**Congratulations!** You successfully configured locality distribution!

## Next steps

[Cleanup](/docs/tasks/traffic-management/locality-load-balancing/cleanup)
resources and files from this task.

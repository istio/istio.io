---
title: Single Multi-Zone Cluster Load Balancer Standalone Example
description: This example demonstrates the traffic shifting between zones within a single cluster.
weight: 40
keywords: [locality,load balancing]
test: no
owner: istio/wg-networking-maintainers
---

## Before you begin

This guide requires that you have a Kubernetes cluster with any of the
[supported Kubernetes versions:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.
We will create a single cluster with 3 workers and label them with different zone names like below.

{{< text bash >}}
$ kubectl get node
NAME                          STATUS   ROLES           AGE    VERSION
istio-testing-control-plane   Ready    control-plane   3d7h   v1.27.1
istio-testing-worker          Ready    <none>          3d7h   v1.27.1
istio-testing-worker2         Ready    <none>          3d7h   v1.27.1
istio-testing-worker3         Ready    <none>          3d7h   v1.27.1
{{< /text >}}

Add zone label to 3 workers with us-south10, us-south12 and us-south13:
{{< text bash >}}
$ kubectl label node istio-testing-worker topology.kubernetes.io/zone=us-south10
$ kubectl label node istio-testing-worker2 topology.kubernetes.io/zone=us-south12
kubectl label node istio-testing-worker3 topology.kubernetes.io/zone=us-south13
{{< /text >}}

{{< text bash >}}
$ kubectl get nodes -L topology.kubernetes.io/zone
NAME                          STATUS   ROLES           AGE    VERSION   ZONE
istio-testing-control-plane   Ready    control-plane   3d7h   v1.27.1
istio-testing-worker          Ready    <none>          3d7h   v1.27.1   us-south10
istio-testing-worker2         Ready    <none>          3d7h   v1.27.1   us-south12
istio-testing-worker3         Ready    <none>          3d7h   v1.27.1   us-south13
{{< /text >}}

## Istiod Isolation
We will edit the istiod deployment to use Pod topology spread constraints to deploy istiod instance in each zone and ensure that all sidecars from each zone connect to their local istiod instance. 

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
  namespace: istio-system
spec:
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: istiod
...
{{< /text >}}


## Deploy HelloWorld to 3 different zones

we will add node affinity rule in [samples/helloworld/helloworld.yaml](https://raw.githubusercontent.com/istio/istio/release-1.18/samples/helloworld/helloworld.yaml) to assign the pod to certain zone: 

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-us-south10
  labels:
    app: helloworld
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
  template:
    metadata:
      labels:
        app: helloworld
    spec:
      affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
              - matchExpressions:
                - key: topology.kubernetes.io/zone
                  operator: In
                  values:
                    - us-south10
...
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl get pod -o wide
NAME                                     READY   STATUS    RESTARTS   AGE   IP            NODE                    NOMINATED NODE   READINESS GATES
helloworld-us-south10-55c5c89785-dsg4s   1/2     Running   0          34h   10.244.1.7    istio-testing-worker    <none>           <none>
helloworld-us-south12-99775b858-vlnps    2/2     Running   0          34h   10.244.3.6    istio-testing-worker2   <none>           <none>
helloworld-us-south13-8bb7f48d-852jw     2/2     Running   0          34h   10.244.2.10   istio-testing-worker3   <none>           <none>
{{< /text >}}

## Deploy `Sleep`

Deploy the `Sleep` application to `us-south10`:

we will add node affinity rule in [samples/sleep/sleep.yaml](https://raw.githubusercontent.com/istio/istio/release-1.18/samples/sleep/sleep.yaml) to assign the pod to zone `us-south10`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
...
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep-us-south10
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
              - matchExpressions:
                - key: topology.kubernetes.io/zone
                  operator: In
                  values:
                    - us-south10
...
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl get pod -o wide
NAME                                     READY   STATUS    RESTARTS   AGE   IP            NODE                    NOMINATED NODE   READINESS GATES
helloworld-us-south10-55c5c89785-dsg4s   1/2     Running   0          34h   10.244.1.7    istio-testing-worker    <none>           <none>
helloworld-us-south12-99775b858-vlnps    2/2     Running   0          34h   10.244.3.6    istio-testing-worker2   <none>           <none>
helloworld-us-south13-8bb7f48d-852jw     2/2     Running   0          34h   10.244.2.10   istio-testing-worker3   <none>           <none>
sleep-us-south10-6b544777c6-x66xv        2/2     Running   0          36h   10.244.1.6    istio-testing-worker    <none>           <none>
{{< /text >}}

## Configure locality failover

Apply a `DestinationRule` that configures the following:

- [Outlier detection](/docs/reference/config/networking/destination-rule/#OutlierDetection)
  for the `HelloWorld` service. This is required in order for failover to
  function properly. In particular, it configures the sidecar proxies to know
  when endpoints for a service are unhealthy, eventually triggering a failover
  to the next locality.

- [Failover](/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting-Failover)
  policy between regions. This ensures that failover beyond a region boundary
  will behave predictably.

- [Connection Pool](/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-http)
  policy that forces each HTTP request to use a new connection. This task utilizes
  Envoy's [drain](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/draining)
  function to force a failover to the next locality. Once drained, Envoy will reject
  new connection requests. Since each request uses a new connection, this results in failover
  immediately following a drain. **This configuration is used for demonstration purposes only.**

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.default.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        maxRequestsPerConnection: 1
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failover:
          - from: us-south10
            to: us-south12
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
EOF
{{< /text >}}

## Verify traffic stays in `us-south10`

Call the `HelloWorld` service from the `Sleep` pod:

{{< text bash >}}
$ kubectl exec -c sleep \
  "$(kubectl get pod -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.default:5000/hello
Hello version: v1, instance: helloworld-us-south10-6f7479cf56-fggxc
{{< /text >}}

Verify that the `instance` in the response is from `us-south10`.

Repeat this several times and verify that the response is always the same.

## Failover to `us-south12`

Next, trigger a failover to `us-south12`. To do this, you
[drain the Envoy sidecar proxy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/draining#draining)
for `HelloWorld` in `us-south10`:

{{< text bash >}}
$ kubectl exec helloworld-us-south10-55c5c89785-dsg4s -c istio-proxy -- curl -sSL -X POST 127.0.0.1:15000/drain_listeners
OK
{{< /text >}}

Call the `HelloWorld` service from the `Sleep` pod:

{{< text bash >}}
$ kubectl exec -c sleep \
  "$(kubectl get pod -l \
  app=sleep -o jsonpath='{.items[0].metadata.name}')" \
  -- curl -sSL helloworld.default:5000/hello
Hello version: v1, instance: helloworld-us-south12-99775b858-vlnps
{{< /text >}}

The first call will fail, which triggers the failover. Repeat the command
several more times and verify that the `instance` in the response is always
`us-south12`.
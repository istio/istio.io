---
title: Canary Deployments using Istio
description: Using Istio to create autoscaled canary deployments.
publishdate: 2017-06-14
last_update: 2018-05-16
attribution: Frank Budinsky
keywords: [traffic-management,canary]
aliases:
    - /blog/canary-deployments-using-istio.html
target_release: 0.7
---

{{< tip >}}
This post was updated on May 16, 2018 to use the latest version of the traffic management model.
{{< /tip >}}

One of the benefits of the [Istio](/) project is that it provides the control needed to deploy canary services. The idea behind
canary deployment (or rollout) is to introduce a new version of a service by first testing it using a small percentage of user
traffic, and then if all goes well, increase, possibly gradually in increments, the percentage while simultaneously phasing out
the old version. If anything goes wrong along the way, we abort and rollback to the previous version. In its simplest form,
the traffic sent to the canary version is a randomly selected percentage of requests, but in more sophisticated schemes it
can be based on the region, user, or other properties of the request.

Depending on your level of expertise in this area, you may wonder why Istio's support for canary deployment is even needed, given that platforms like Kubernetes already provide a way to do [version rollout](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment) and [canary deployment](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments). Problem solved, right? Well, not exactly. Although doing a rollout this way works in simple cases, it’s very limited, especially in large scale cloud environments receiving lots of (and especially varying amounts of) traffic, where autoscaling is needed.

## Canary deployment in Kubernetes

As an example, let's say we have a deployed service, **helloworld** version **v1**, for which we would like to test (or simply rollout) a new version, **v2**. Using Kubernetes, you can rollout a new version of the **helloworld** service by simply updating the image in the service’s corresponding [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) and letting the [rollout](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment) happen automatically. If we take particular care to ensure that there are enough **v1** replicas running when we start and [pause](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#pausing-and-resuming-a-deployment) the rollout after only one or two **v2** replicas have been started, we can keep the canary’s effect on the system very small. We can then observe the effect before deciding to proceed or, if necessary, [rollback](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment). Best of all, we can even attach a [horizontal pod autoscaler](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment) to the Deployment and it will keep the replica ratios consistent if, during the rollout process, it also needs to scale replicas up or down to handle traffic load.

Although fine for what it does, this approach is only useful when we have a properly tested version that we want to deploy, i.e., more of a blue/green, a.k.a. red/black, kind of upgrade than a "dip your feet in the water" kind of canary deployment. In fact, for the latter (for example, testing a canary version that may not even be ready or intended for wider exposure), the canary deployment in Kubernetes would be done using two Deployments with [common pod labels](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#using-labels-effectively). In this case, we can’t use autoscaling anymore because it’s now being done by two independent autoscalers, one for each Deployment, so the replica ratios (percentages) may vary from the desired ratio, depending purely on load.

Whether we use one deployment or two, canary management using deployment features of container orchestration platforms like Docker, Mesos/Marathon, or Kubernetes has a fundamental problem: the use of instance scaling to manage the traffic; traffic version distribution and replica deployment are not independent in these systems. All replica pods, regardless of version, are treated the same in the `kube-proxy` round-robin pool, so the only way to manage the amount of traffic that a particular version receives is by controlling the replica ratio. Maintaining canary traffic at small percentages requires many replicas (e.g., 1% would require a minimum of 100 replicas). Even if we ignore this problem, the deployment approach is still very limited in that it only supports the simple (random percentage) canary approach. If, instead, we wanted to limit the visibility of the canary to requests based on some specific criteria, we still need another solution.

## Enter Istio

With Istio, traffic routing and replica deployment are two completely independent functions. The number of pods implementing services are free to scale up and down based on traffic load, completely orthogonal to the control of version traffic routing. This makes managing a canary version in the presence of autoscaling a much simpler problem. Autoscalers may, in fact, respond to load variations resulting from traffic routing changes, but they are nevertheless functioning independently and no differently than when loads change for other reasons.

Istio’s [routing rules](/docs/concepts/traffic-management/#routing-rules) also provide other important advantages; you can easily control
fine-grained traffic percentages (e.g., route 1% of traffic without requiring 100 pods) and you can control traffic using other criteria (e.g., route traffic for specific users to the canary version). To illustrate, let’s look at deploying the **helloworld** service and see how simple the problem becomes.

We begin by defining the **helloworld** Service, just like any other Kubernetes service, something like this:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
name: helloworld
labels:
  app: helloworld
spec:
  selector:
    app: helloworld
  ...
{{< /text >}}

We then add 2 Deployments, one for each version (**v1** and **v2**), both of which include the service selector’s `app: helloworld` label:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: helloworld
        version: v1
    spec:
      containers:
      - image: helloworld-v1
        ...
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: helloworld
        version: v2
    spec:
      containers:
      - image: helloworld-v2
        ...
{{< /text >}}

Note that this is exactly the same way we would do a [canary deployment](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments) using plain Kubernetes, but in that case we would need to adjust the number of replicas of each Deployment to control the distribution of traffic. For example, to send 10% of the traffic to the canary version (**v2**), the replicas for **v1** and **v2** could be set to 9 and 1, respectively.

However, since we are going to deploy the service in an [Istio enabled](/docs/setup/) cluster, all we need to do is set a routing
rule to control the traffic distribution. For example if we want to send 10% of the traffic to the canary, we could use `kubectl`
to set a routing rule something like this:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - helloworld
  http:
  - route:
    - destination:
        host: helloworld
        subset: v1
      weight: 90
    - destination:
        host: helloworld
        subset: v2
      weight: 10
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
{{< /text >}}

After setting this rule, Istio will ensure that only one tenth of the requests will be sent to the canary version, regardless of how many replicas of each version are running.

## Autoscaling the deployments

Because we don’t need to maintain replica ratios anymore, we can safely add Kubernetes [horizontal pod autoscalers](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to manage the replicas for both version Deployments:

{{< text bash >}}
$ kubectl autoscale deployment helloworld-v1 --cpu-percent=50 --min=1 --max=10
deployment "helloworld-v1" autoscaled
{{< /text >}}

{{< text bash >}}
$ kubectl autoscale deployment helloworld-v2 --cpu-percent=50 --min=1 --max=10
deployment "helloworld-v2" autoscaled
{{< /text >}}

{{< text bash >}}
$ kubectl get hpa
NAME           REFERENCE                 TARGET  CURRENT  MINPODS  MAXPODS  AGE
Helloworld-v1  Deployment/helloworld-v1  50%     47%      1        10       17s
Helloworld-v2  Deployment/helloworld-v2  50%     40%      1        10       15s
{{< /text >}}

If we now generate some load on the **helloworld** service, we would notice that when scaling begins, the **v1** autoscaler will scale up its replicas significantly higher than the **v2** autoscaler will for its replicas because **v1** pods are handling 90% of the load.

{{< text bash >}}
$ kubectl get pods | grep helloworld
helloworld-v1-3523621687-3q5wh   0/2       Pending   0          15m
helloworld-v1-3523621687-73642   2/2       Running   0          11m
helloworld-v1-3523621687-7hs31   2/2       Running   0          19m
helloworld-v1-3523621687-dt7n7   2/2       Running   0          50m
helloworld-v1-3523621687-gdhq9   2/2       Running   0          11m
helloworld-v1-3523621687-jxs4t   0/2       Pending   0          15m
helloworld-v1-3523621687-l8rjn   2/2       Running   0          19m
helloworld-v1-3523621687-wwddw   2/2       Running   0          15m
helloworld-v1-3523621687-xlt26   0/2       Pending   0          19m
helloworld-v2-4095161145-963wt   2/2       Running   0          50m
{{< /text >}}

If we then change the routing rule to send 50% of the traffic to **v2**, we should, after a short delay, notice that the **v1** autoscaler will scale down the replicas of **v1** while the **v2** autoscaler will perform a corresponding scale up.

{{< text bash >}}
$ kubectl get pods | grep helloworld
helloworld-v1-3523621687-73642   2/2       Running   0          35m
helloworld-v1-3523621687-7hs31   2/2       Running   0          43m
helloworld-v1-3523621687-dt7n7   2/2       Running   0          1h
helloworld-v1-3523621687-gdhq9   2/2       Running   0          35m
helloworld-v1-3523621687-l8rjn   2/2       Running   0          43m
helloworld-v2-4095161145-57537   0/2       Pending   0          21m
helloworld-v2-4095161145-9322m   2/2       Running   0          21m
helloworld-v2-4095161145-963wt   2/2       Running   0          1h
helloworld-v2-4095161145-c3dpj   0/2       Pending   0          21m
helloworld-v2-4095161145-t2ccm   0/2       Pending   0          17m
helloworld-v2-4095161145-v3v9n   0/2       Pending   0          13m
{{< /text >}}

The end result is very similar to the simple Kubernetes Deployment rollout, only now the whole process is not being orchestrated and managed in one place. Instead, we’re seeing several components doing their jobs independently, albeit in a cause and effect manner.
What's different, however, is that if we now stop generating load, the replicas of both versions will eventually scale down to their minimum (1), regardless of what routing rule we set.

{{< text bash >}}
$ kubectl get pods | grep helloworld
helloworld-v1-3523621687-dt7n7   2/2       Running   0          1h
helloworld-v2-4095161145-963wt   2/2       Running   0          1h
{{< /text >}}

## Focused canary testing

As mentioned above, the Istio routing rules can be used to route traffic based on specific criteria, allowing more sophisticated canary deployment scenarios. Say, for example, instead of exposing the canary to an arbitrary percentage of users, we want to try it out on internal users, maybe even just a percentage of them. The following command could be used to send 50% of traffic from users at *some-company-name.com* to the canary version, leaving all other users unaffected:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - helloworld
  http:
  - match:
    - headers:
        cookie:
          regex: "^(.*?;)?(email=[^;]*@some-company-name.com)(;.*)?$"
    route:
    - destination:
        host: helloworld
        subset: v1
      weight: 50
    - destination:
        host: helloworld
        subset: v2
      weight: 50
  - route:
    - destination:
        host: helloworld
        subset: v1
EOF
{{< /text >}}

As before, the autoscalers bound to the 2 version Deployments will automatically scale the replicas accordingly, but that will have no affect on the traffic distribution.

## Summary

In this article we’ve seen how Istio supports general scalable canary deployments, and how this differs from the basic deployment support in Kubernetes. Istio’s service mesh provides the control necessary to manage traffic distribution with complete independence from deployment scaling. This allows for a simpler, yet significantly more functional, way to do canary test and rollout.

Intelligent routing in support of canary deployment is just one of the many features of Istio that will make the production deployment of large-scale microservices-based applications much simpler. Check out [istio.io](/) for more information and to try it out.
The sample code used in this article can be found [here]({{< github_tree >}}/samples/helloworld).

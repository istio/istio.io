---
title: Understand your Mesh with Istioctl Describe
description: Shows you how to use istioctl describe to verify the configurations of a pod in your mesh.
weight: 30
keywords: [traffic-management, istioctl, debugging, kubernetes]
aliases:
  - /docs/ops/troubleshooting/istioctl-describe
---

{{< boilerplate experimental-feature-warning >}}

In Istio 1.3, we included the [`istioctl experimental describe`](/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod)
command. This CLI command provides you with the information needed to understand
the configuration impacting a {{< gloss >}}pod{{< /gloss >}}. This guide shows
you how to use this experimental sub-command to see if a pod is in the mesh and
verify its configuration.

The basic usage of the command is as follows:

{{< text bash >}}
$ istioctl experimental describe pod <pod-name>[.<namespace>]
{{< /text >}}

Appending a namespace to the pod name has the same affect as using the `-n` option
of `istioctl` to specify a non-default namespace.

{{< tip >}}
Just like all other `istioctl` commands, you can replace `experimental`
with `x` for convenience.
{{< /tip >}}

This guide assumes you have deployed the [Bookinfo](/docs/examples/bookinfo/)
sample in your mesh. If you haven't already done so,
[start the application's services](/docs/examples/bookinfo/#start-the-application-services)
and [determine the IP and port of the ingress](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port)
before continuing.

## Verify a pod is in the mesh

The `istioctl describe` command returns a warning if the {{< gloss >}}Envoy{{< /gloss >}}
proxy is not present in a pod or if the proxy has not started. Additionally, the command warns
if some of the [Istio requirements for pods](/docs/ops/deployment/requirements/)
are not met.

For example, the following command produces a warning indicating a `kubernetes-dashboard`
pod is not part of the service mesh because it has no sidecar:

{{< text bash >}}
$ export DASHBOARD_POD=$(kubectl -n kube-system get pod -l k8s-app=kubernetes-dashboard -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod -n kube-system $DASHBOARD_POD
WARNING: kubernetes-dashboard-7996b848f4-nbns2.kube-system is not part of mesh; no Istio sidecar
--------------------
Error: failed to execute command on sidecar: error execing into kubernetes-dashboard-7996b848f4-nbns2/kube-system istio-proxy container: container istio-proxy is not valid for pod kubernetes-dashboard-7996b848f4-nbns2
{{< /text >}}

The command will not produce such a warning for a pod that is part of the mesh,
the Bookinfo `ratings` service for example, but instead will output the Istio configuration applied to the pod:

{{< text bash >}}
$ export RATINGS_POD=$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')
$ istioctl experimental describe pod $RATINGS_POD
Pod: ratings-v1-f745cf57b-qrxl2
Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP
Pilot reports that pod enforces HTTP/mTLS and clients speak HTTP
{{< /text >}}

The output shows the following information:

- The ports of the service container in the pod, `9080` for the `ratings` container in this example.
- The ports of the `istio-proxy` container in the pod, `15090` in this example.
- The protocol used by the service in the pod, `HTTP` over port `9080` in this example.
- The mutual TLS settings for the pod.

## Verify destination rule configurations

You can use `istioctl describe` to see what
[destination rules](/docs/concepts/traffic-management/#destination-rules) apply to requests
to a pod. For example, apply the Bookinfo
[mutual TLS destination rules]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml):

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Now describe the `ratings` pod again:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pod: ratings-v1-f745cf57b-qrxl2
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP
DestinationRule: ratings for "ratings"
   Matching subsets: v1
      (Non-matching subsets v2,v2-mysql,v2-mysql-vm)
   Traffic Policy TLS Mode: ISTIO_MUTUAL
Pilot reports that pod enforces HTTP/mTLS and clients speak mTLS
{{< /text >}}

The command now shows additional output:

- The `ratings` destination rule applies to request to the `ratings` service.
- The subset of the `ratings` destination rule that matches the pod, `v1` in this example.
- The other subsets defined by the destination rule.
- The pod accepts either HTTP or mutual TLS requests but clients use mutual TLS.

## Verify virtual service configurations

When [virtual services](/docs/concepts/traffic-management/#virtual-services) configure
routes to a pod, `istioctl describe` will also include the routes in its output.
For example, apply the
[Bookinfo virtual services]({{< github_file>}}/samples/bookinfo/networking/virtual-service-all-v1.yaml)
that route all requests to `v1` pods:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

Then, describe a pod implementing `v1` of the `reviews` service:

{{< text bash >}}
$ export REVIEWS_V1_POD=$(kubectl get pod -l app=reviews,version=v1 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   1 HTTP route(s)
{{< /text >}}

The output contains similar information to that shown previously for the `ratings` pod,
but it also includes the virtual service's routes to the pod.

The `istioctl describe` command doesn't just show the virtual services impacting the pod.
If a virtual service configures the service host of a pod but no traffic will reach it,
the command's output includes a warning. This case can occur if the virtual service
actually blocks traffic by never routing traffic to the pod's subset. For
example:

{{< text bash >}}
$ export REVIEWS_V2_POD=$(kubectl get pod -l app=reviews,version=v2 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V2_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Route to non-matching subset v1 for (everything)
{{< /text >}}

The warning includes the cause of the problem, how many routes were checked, and
even gives you information about the other routes in place. In this example,
no traffic arrives at the `v2` pod because the route in the virtual service directs all
traffic to the `v1` subset.

If you now delete the Bookinfo destination rules:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

You can see another useful feature of `istioctl describe`:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Warning: Route to subset v1 but NO DESTINATION RULE defining subsets!
{{< /text >}}

The output shows you that you deleted the destination rule but not the virtual
service that depends on it. The virtual service routes traffic to the `v1`
subset, but there is no destination rule defining the `v1` subset.
Thus, traffic destined for version `v1` can't flow to the pod.

If you refresh the browser to send a new request to Bookinfo at this
point, you would see the following message: `Error fetching product reviews`.
To fix the problem, reapply the destination rule:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

Reloading the browser shows the app working again and
running `istioctl experimental describe pod $REVIEWS_V1_POD` no longer produces
warnings.

## Verifying traffic routes

The `istioctl describe` command shows split traffic weights too.
For example, run the following command to route 90% of traffic to the `v1` subset
and 10% to the `v2` subset of the the `reviews` service:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-90-10.yaml@
{{< /text >}}

Now describe the `reviews v1` pod:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   Weight 90%
{{< /text >}}

The output shows that the `reviews` virtual service has a weight of 90% for the
`v1` subset.

This function is also helpful for other types of routing. For example, you can deploy
header-specific routing:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
{{< /text >}}

Then, describe the pod again:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 2 HTTP routes)
      Route to non-matching subset v2 for (when headers are end-user=jason)
      Route to non-matching subset v3 for (everything)
{{< /text >}}

The output produces a warning since you are describing a pod in the `v1` subset.
However, the virtual service configuration you applied routes traffic to the `v2`
subset if the header contains `end-user=jason` and to the `v3` subset in all
other cases.

## Verifying strict mutual TLS

Following the [mutual TLS migration](/docs/tasks/security/authentication/mtls-migration/)
instructions, you can enable strict mutual TLS for the `ratings` service:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "ratings-strict"
spec:
  targets:
  - name: ratings
  peers:
  - mtls:
      mode: STRICT
EOF
{{< /text >}}

Run the following command to describe the `ratings` pod:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pilot reports that pod enforces mTLS and clients speak mTLS
{{< /text >}}

The output reports that requests to the the `ratings` pod are now locked down and secure.

Sometimes, however, a deployment breaks when switching mutual TLS to `STRICT`.
The likely cause is that the destination rule didn't match the new configuration.
For example, if you configure the Bookinfo clients to not use mutual TLS using the
[plain HTTP destination rules]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml):

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

If you open Bookinfo in your browser, you see `Ratings service is currently unavailable`.
To learn why, run the following command:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
...
WARNING Pilot predicts TLS Conflict on ratings-v1-f745cf57b-qrxl2 port 9080 (pod enforces mTLS, clients speak HTTP)
  Check DestinationRule ratings/default and AuthenticationPolicy ratings-strict/default
{{< /text >}}

The output includes a warning describing the conflict
between the destination rule and the authentication policy.

You can restore correct behavior by applying a destination rule that uses
mutual TLS:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

## Conclusion and cleanup

Our goal with the `istioctl x describe` command is to help you understand the
traffic and security configurations in your Istio mesh.

We would love to hear your ideas for improvements!
Please join us at [https://discuss.istio.io](https://discuss.istio.io).

To remove the Bookinfo pods and configurations used in this guide, run the
following commands:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl delete -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

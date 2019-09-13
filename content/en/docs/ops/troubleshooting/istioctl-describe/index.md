---
title: Understanding your mesh with istioctl describe
description: Shows you how to use istioctl to determine the traffic management applied to a pod.
weight: 90
keywords: [traffic-management, istioctl, debugging]
---

{{< boilerplate experimental-feature-warning >}}

In Istio 1.3, we included the experimental
[`describe pod`](/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod)
sub-command for `istioctl`. We designed this tool to help find and
understand the configuration that impacts a pod.  This task shows you how
to use the experimental sub-command to see if a pod is in the mesh and
view its traffic and security configuration.

## Confirm the Pod is in the Service Mesh

`describe pod` warns if the Envoy container is not present or has not
started.  It will warn if [Istio requirements](/docs/setup/additional-setup/requirements/) are not met.

For example, `istioctl x describe pod $(kubectl -n kube-system get pod -l k8s-app=kubernetes-dashboard -o jsonpath='{.items[0].metadata.name}').kube-system` reports

{{< text plain >}}
WARNING: kubernetes-dashboard-7996b848f4-nbns2.kube-system is not part of mesh; no Istio sidecar
{{< /text >}}

## `istioctl experimental describe pod` tutorial

If the pod is part of the mesh `describe` will show the configuration that affects the pod.

First, let us deploy Bookinfo.  Follow the steps to
[start the application services](/docs/examples/bookinfo/#start-the-application-services) and
[determine the ingress IP and port](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) before continuing.

Let's describe a pod:

{{< text bash >}}
$ export RATINGS_POD=$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')
$ istioctl experimental describe pod $RATINGS_POD
{{< /text >}}

The output tells us which containers the pod exposes, the Istio protocol for the microservice on port 9080, and the mutual TLS settings for the pod.

{{< text plain >}}
Pod: ratings-v1-f745cf57b-qrxl2
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP
Pilot reports that pod enforces HTTP/mTLS and clients speak HTTP
{{< /text >}}

## Destination Rules

Next we apply the destination rules suggested by the documentation.  I used mutual TLS,
so I must apply `destination-rule-all-mtls.yaml`:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
$ istioctl x describe pod $RATINGS_POD
{{< /text >}}

Applying `destination-rule-all-mtls.yaml` created four destination rules: `details`, `productpage`, `ratings`, and `reviews`.

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
{{< /text >}}

Now `istioctl x describe` shows additional output:

{{< text plain >}}
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

The destination rule now appears in the output.  This tells us that the `ratings` destination rule is present, and that it defines the subset `v1` which matches this pod.
Clients talking to the ratings microservice will use mutual TLS.

## Virtual Services

Now I will follow the Bookinfo example to [Request Routing](/docs/tasks/traffic-management/request-routing/) and define some virtual services:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
{{< /text >}}

After applying this rule I "describe" the _reviews-v1_ pod:

{{< text bash >}}
$ export REVIEWS_V1_POD=$(kubectl get pod -l app=reviews,version=v1 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V1_POD
{{< /text >}}

The output resembles what we saw before the virtual services were defined, but we now see that they are present:

{{< text plain >}}
VirtualService: reviews
   1 HTTP route(s)
{{< /text >}}

After applying _virtual-service-all-v1.yaml_ the traffic all goes to version 1.  The "stars disappear".  If this was a real cluster, someone might notice the logs to v2/v3
are no longer appearing.  Users might notice features and not working.  `describe` will not
just report the virtual services that configure a pod.  If it seems that a virtual service
configures a pod, but actually blocks traffic by never routing to the pod's subset, the output will include a warning.

{{< text bash >}}
$ export REVIEWS_V2_POD=$(kubectl get pod -l app=reviews,version=v2 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V2_POD
{{< /text >}}

The warning "No destinations match pod subsets" tells us the problem.
No traffic will arrive due to the virtual service destinations.

{{< text plain >}}
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Route to non-matching subset v1 for (everything)
{{< /text >}}

Oh no!  I must revert!  I'll delete the bogus Istio configuration:

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
{{< /text >}}

If I refresh the browser at this point the stars do not appear.  Instead I see
*Error fetching product details!* and *Error fetching product reviews!*  Instead of
panic, I `describe`:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V2_POD
{{< /text >}}

{{< text plain >}}
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Warning: Route to UNKNOWN subset v1.  No DestinationRule.
{{< /text >}}

At this point I look back and realize I deleted the destination rules, not the virtual service I intended to.  The virtual service is still there, still routing to subset `v1`, but without a destination rule defining `v1` to mean the selector `version:v1`, traffic cannot flow to any pods.

To fix the problem:

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
{{< /text >}}

Reloading the browser shows the app has reappeared along with the stars.  `istioctl experimental describe pod $REVIEWS_V2_POD` no longer gives warnings.

## Mutual TLS

Let's follow the [Mutual TLS Migration](/docs/tasks/security/mtls-migration/) instructions to enable strict mutual TLS, but targeting ratings:

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

Now `istioctl x describe pod $RATINGS_POD` reports

{{< text plain >}}
Pilot reports that pod enforces mTLS and clients speak mTLS
{{< /text >}}

That's locked down!

If things break when mutual TLS is made `STRICT` it often means that the destination rule didn't match.  For example, if I _destination-rule-all.yaml_ is used instead of `destination-rule-all-mtls.yaml`:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml   # oops wrong filename
{{< /text >}}

At this point the browser shows *Ratings service is currently unavailable*.  Why?

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
{{< /text >}}

The output is the same except the final line which now reads

{{< text plain >}}
WARNING Pilot predicts TLS Conflict on ratings-v1-f745cf57b-qrxl2 port 9080 (pod enforces mTLS, clients speak HTTP)
  Check DestinationRule ratings/default and AuthenticationPolicy ratings-strict/default
{{< /text >}}

Restore correct behavior with `kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml`.

## Summary of traffic rules

The tool will show a bit about the rules.  For example, let's deploy the 90/10 traffic
split:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
sleep 3
$ istioctl x describe pod $REVIEWS_V1_POD
{{< /text >}}

Let's deploy header-specific routing:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml
$ sleep 3
$ istioctl x describe pod $REVIEWS_V1_POD
{{< /text >}}

## Conclusion and cleanup

I hope `istioctl x describe` helps you to understand the traffic and security rules
used in your Istio deployment.  If you have ideas for improvements please post on
[https://discuss.istio.io](https://discuss.istio.io).

To remove the book info pods used for this tutorial, follow [these instructions](/docs/examples/bookinfo/#cleanup) or run

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml
$ kubectl delete -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
$ kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
{{< /text >}}

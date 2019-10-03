---
title: Understand Your Mesh with `istioctl describe`
description: Shows you how to use `istioctl describe` to verify the configurations of a pod in your mesh.
weight: 90
keywords: [traffic-management, istioctl, debugging, kubernetes]
---

{{< boilerplate experimental-feature-warning >}}

In Istio 1.3, we included the [`istioctl experimental describe pod`](/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod)
command. This CLI command provides you with the information needed to understand
the configuration impacting a {{< gloss >}}pod{{< /gloss >}}. This task shows
you how to use this experimental sub-command to see if a pod is in the mesh and
verify its configuration.

The basic usage of the command is as follows:

{{< text bash >}}
$ istioctl experimental describe <pod-name>
{{< /text>}}

The command above includes the `experimental` label, but you can replace it with
`x` for convenience. The value of `<pod-name>` is the name Kubernetes randomly
assigns to the pods in the cluster. For convenience in this task, we obtain
`<pod-name>` via `kubectl` and store it in environmental variables throughout.

This task assumes you have deployed the [Bookinfo](/docs/examples/bookinfo/)
sample in your mesh. If you haven't done so, [start the application's services](/docs/examples/bookinfo/#start-the-application-services)
and [determine the IP and port of the ingress](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) before continuing.

## Verify the pod is in the mesh

The `describe pod` command returns a warning if the Envoy proxy is not present
in the pod or if the proxy has not started. Additionally, the command warns if
the [Istio requirements for pods](/docs/setup/additional-setup/requirements/)
are not met.

For example, the following command produces a warning indicating the pod is not
in the service mesh and the lack of a sidecar.

{{< text bash >}}
$ istioctl x describe pod $(kubectl -n kube-system get pod -l k8s-app=kubernetes-dashboard -o jsonpath='{.items[0].metadata.name}').kube-system
WARNING: kubernetes-dashboard-7996b848f4-nbns2.kube-system is not part of mesh; no Istio sidecar
{{< /text >}}

## Verify the `ratings` service is in the mesh

Once Bookinfo is deployed as part of the mesh, `describe pod` can show the
configuration applied the pod.

To describe the pod running the `ratings` {{< gloss >}}service{{< /gloss >}}, run:

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

- The containers exposed by the pod.
- The port of the service in the pod, `9080` for `ratings` in the example.
- The port of the `istio-proxy` in the pod, `15090` in the example.
- The protocol used by the service in the pod, `HTTP` over the `9080` port in
  the example.
- The mutual TLS settings for the pod.

## Verify destination rule configurations

We recommend you use [destination rules](/docs/concepts/traffic-management/#destination-rules)
to apply certain configurations to services on your mesh.

One common example is enabling mutual TLS.
For Bookinfo, we have a [mutual TLS configuration file]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml)
that creates four destination rules, one per service in Bookinfo: `details`,
`productpage`, `ratings`, and `reviews`. Apply the configuration file and
describe the pod:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
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

- The `ratings` destination rule for `"ratings"`.
- The `v1` subset the `ratings` destination rule defines.
- The fact that this pod matches the `v1` subset.
- The fact that clients talking to the `ratings` service use mutual TLS.

## Verify virtual service configurations

For traffic management, we recommend you [route your requests](/docs/tasks/traffic-management/request-routing/).

In Istio, you can do this using [virtual services](/docs/concepts/traffic-management/#why-use-virtual-services).
For Bookinfo, we have a [configuration file]({{< github_file>}}/samples/bookinfo/networking/virtual-service-all-v1.yaml)
that defines a virtual service to route all traffic to `v1` of the the services.

The following commands set the `REVIEWS_V1_POD` environmental variable to store
the the pod's name, apply the configuration file and describe the pod.

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
$ export REVIEWS_V1_POD=$(kubectl get pod -l app=reviews,version=v1 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V1_POD
VirtualService: reviews
   1 HTTP route(s)
{{< /text >}}

The output contains the same information as before but it also includes the
defined virtual services.

Routing all traffic to the `v1` subset makes the stars disappear from the
rating. In a real cluster, you would notice that the logs for the `v2` and `v3`
versions no longer appear. For users, features appear not to be working.

The command doesn't just show the virtual services impacting the pod. If a
virtual service appears to configure a pod but no traffic reaches it, the
command's output includes a warning. This case can occur if the virtual service
actually blocks traffic because it never routes traffic to the pod's subset. For
example:

{{< text bash >}}
$ export REVIEWS_V2_POD=$(kubectl get pod -l app=reviews,version=v2 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V2_POD
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Route to non-matching subset v1 for (everything)
{{< /text >}}

The warning includes the cause of the problem, how many routes were checked, and
even gives you some information about the other routes in place. In our example,
no traffic arrives to the pod because the route in the virtual service directs all
traffic to the `v1` subset and the destination pod is in the `v2` subset of the
service.

At first, you would think this issue has a simple solution: delete the incorrect
Istio configuration.

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
{{< /text >}}

If you refresh the browser to send a new request to Bookinfo after deleting the
configuration, you won't see the stars appear. Instead, you see the following
messages: `Error fetching product details!` and `Error fetching product reviews!`.

Try not to panic, instead use `istioctl describe`:

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V2_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Warning: Route to subset v1 but NO DESTINATION RULE defining subsets!
{{< /text >}}

The output shows us that we deleted the destination rules, and not the virtual
service. The virtual service still routes all traffic to the `v1` subset, but
there is no destination rule defining the `v1` subset. Thus, traffic with the
`version:v1` selector can't flow to any pods.

We can fix the problem with the following commands:

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
{{< /text >}}

Reloading the browser shows the app working and showing stars for the ratings.
Running `istioctl experimental describe pod $REVIEWS_V2_POD` no longer produces warnings.

## Verifying strict mutual TLS

Following the [mutual TLS migration](/docs/tasks/security/mtls-migration/)
instructions, we can enable strict mutual TLS, but targeting the `ratings` service:

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

We can run the following command to describe the `$RATINGS_POD` pod:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pilot reports that pod enforces mTLS and clients speak mTLS
{{< /text >}}

The output reports that's locked down!

When your deployment breaks while switching mutual TLS to `STRICT`, the likely
culprit is that the destination rule didn't match the new configuration.

For example, could use this [configuration file]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml)
to setup the destination rules:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
{{< /text >}}

If you open Bookinfo in your browser, you see `Ratings service is currently unavailable`.
To learn why, run the following command:

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
WARNING Pilot predicts TLS Conflict on ratings-v1-f745cf57b-qrxl2 port 9080 (pod enforces mTLS, clients speak HTTP)
  Check DestinationRule ratings/default and AuthenticationPolicy ratings-strict/default
{{< /text >}}

The output remained unchanged except for the warning describing the conflict
between the destination rule and the authentication policy.

You can restore correct behavior applying a destination rule that contemplates
strict mutual TLS:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
{{< text bash >}}

## Verifying traffic routes

The command shows traffic route information too. For example, we can apply a traffic
split and then describe the pod:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
sleep 3
{{< /text >}}

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   Weight 90%
{{< /text >}}

The output shows that the `reviews` virtual service has a weight of 90% for the
`v1` subset. This information shows that the traffic split we applied routes 90%
of traffic to the `v1` subset and 10% to the `v2` subset of the the `reviews`
service.

This function is helpful for other types of routing. For example, we can deploy
header-specific routing and describe the pod:

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml
$ sleep 3
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 2 HTTP routes)
      Route to non-matching subset v2 for (when headers are end-user=jason)
      Route to non-matching subset v3 for (everything)
{{< /text >}}

The output produces a warning since we are describing a pod in the `v1` subset.
However, the virtual service configuration we applied routes traffic to the `v2`
subset if the header contains `end-user=jason` and to the `v3` subset in all
other cases.

## Conclusion and cleanup

Our goal with the `istioctl x describe` command is to help you understand the
traffic and security configurations in your Istio mesh.

We would love to hear your ideas for improvements!
Please join us at [https://discuss.istio.io](https://discuss.istio.io).

To remove the bookinfo pods and configurations used in this task, run the
following commands:

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml
$ kubectl delete -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
$ kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
{{< /text >}}

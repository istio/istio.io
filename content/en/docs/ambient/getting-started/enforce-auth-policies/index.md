---
title: Enforce authorization policies
description: Enforce Layer 4 and Layer 7 authorization policies in an ambient mesh.
weight: 4
---

After you have added your application to ambient mode, you can secure application access using Layer 4
authorization policies.

This feature lets you control access to and from a service based on client workload
identities that are automatically issued to all workloads in the mesh.

## 1. Enforce Layer 4 authorization policy

Let's create an [authorization policy](/docs/reference/config/security/authorization-policy/) that is applied to the pods with the `app: productpage` label and it allows calls to be made to the `productpage` from the the service account `cluster.local/ns/default/sa/bookinfo-gateway-istio`. This is the service account that's used by the bookinfo gateway you deployed in the previous step.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  selector:
    matchLabels:
      app: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/bookinfo-gateway-istio
EOF
{{< /text >}}

If you open the Bookinfo application in [your browser](http://localhost:8080/productpage), you should see the product page, just like before. However, if you try to access the `productpage` service from a different service account, you should see an error.

Let's try accessing Bookinfo application from a `sleep` pod:

{{< text bash >}}
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml
{{< /text >}}

Since the `sleep` pod is using a different service account, it will not have access the `productpage` service:

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s "http://productpage:9080/productpage"
command terminated with exit code 56
{{< /text >}}

## 2. Enforce Layer 7 authorization policy

To enforce Layer 7 policies you will deploy a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} for the namespace. This proxy will handle all Layer 7 traffic entering the namespace.

{{< text bash >}}
$ istioctl x waypoint apply --enroll-namespace --wait
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

You can view the waypoint proxy and make sure it has the `Programmed=True` status:

{{< text bash >}}
$ kubectl get gtw waypoint
NAME       CLASS            ADDRESS       PROGRAMMED   AGE
waypoint   istio-waypoint   10.96.58.95   True         61s
{{< /text >}}

Let's update the authorization policy and explicitly allow the `sleep` service to send a`GET` request to the `productpage` service, but perform no other operations:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/sleep
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

Note the `targetRefs` field is used to specify the target service for the authorization policy. The rules section is similar as before, btu this time we added the `to` section to specify the operation that is allowed.

Let's confirm the new waypoint proxy is enforcing the updated authorization policy:

{{< text bash >}}
$ # This fails with an RBAC error because we're not using a GET operation
$ kubectl exec deploy/sleep -- curl -s "http://productpage:9080/productpage" -X DELETE
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # This fails with an RBAC error because the identity of the reviews-v1 service is not allowed
$ kubectl exec deploy/reviews-v1 -- curl -s http://productpage:9080/
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # This works as we're explicitly allowing GET requests from the sleep pod
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}


## 3. Next steps

With the waypoint proxy in place, you can now enforce Layer 7 policies in the namespace. In addition to authorization policies, we can use the waypoint proxy to split traffic between services. This is useful when doing canary deployments or A/B testing.
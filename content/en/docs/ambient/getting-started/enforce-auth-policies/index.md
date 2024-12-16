---
title: Enforce authorization policies
description: Enforce Layer 4 and Layer 7 authorization policies in an ambient mesh.
weight: 4
owner: istio/wg-networking-maintainers
test: yes
---

After you have added your application to the ambient mesh, you can secure application access using Layer 4 authorization policies.

This feature lets you control access to and from a service based on the client workload
identities that are automatically issued to all workloads in the mesh.

## Enforce Layer 4 authorization policy

Let's create an [authorization policy](/docs/reference/config/security/authorization-policy/) that restricts which services can communicate with the `productpage` service. The policy is applied to pods with the `app: productpage` label, and it allows calls only from the the service account `cluster.local/ns/default/sa/bookinfo-gateway-istio`. This is the service account that is used by the Bookinfo gateway you deployed in the previous step.

{{< text syntax=bash snip_id=deploy_l4_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-ztunnel
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

If you open the Bookinfo application in your browser (`http://localhost:8080/productpage`), you will see the product page, just as before. However, if you try to access the `productpage` service from a different service account, you should see an error.

Let's try accessing Bookinfo application from a different client in the cluster:

{{< text syntax=bash snip_id=deploy_curl >}}
$ kubectl apply -f @samples/curl/curl.yaml@
{{< /text >}}

Since the `curl` pod is using a different service account, it will not have access the `productpage` service:

{{< text bash >}}
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage"
command terminated with exit code 56
{{< /text >}}

## Enforce Layer 7 authorization policy

To enforce Layer 7 policies, you first need a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} for the namespace. This proxy will handle all Layer 7 traffic entering the namespace.

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

You can view the waypoint proxy and make sure it has the `Programmed=True` status:

{{< text bash >}}
$ kubectl get gtw waypoint
NAME       CLASS            ADDRESS       PROGRAMMED   AGE
waypoint   istio-waypoint   10.96.58.95   True         42s
{{< /text >}}

Adding a [L7 authorization policy](/docs/ambient/usage/l7-features/) will explicitly allow the `curl` service to send `GET` requests to the `productpage` service, but perform no other operations:

{{< text syntax=bash snip_id=deploy_l7_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-waypoint
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
        - cluster.local/ns/default/sa/curl
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

Note the `targetRefs` field is used to specify the target service for the authorization policy of a waypoint proxy. The rules section is similar as before, but this time you added the `to` section to specify the operation that is allowed.

Remember that our L4 policy instructed the ztunnel to only allow connections from the gateway? We now need to update it to also allow connections from the waypoint.

{{< text syntax=bash snip_id=update_l4_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: productpage-ztunnel
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
        - cluster.local/ns/default/sa/waypoint
EOF
{{< /text >}}

{{< tip >}}
To learn about how to enable more of Istio's features, read the [Layer 7 features user guide](/docs/ambient/usage/l7-features/).
{{< /tip >}}

Confirm the new waypoint proxy is enforcing the updated authorization policy:

{{< text bash >}}
$ # This fails with an RBAC error because you're not using a GET operation
$ kubectl exec deploy/curl -- curl -s "http://productpage:9080/productpage" -X DELETE
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # This fails with an RBAC error because the identity of the reviews-v1 service is not allowed
$ kubectl exec deploy/reviews-v1 -- curl -s http://productpage:9080/productpage
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # This works as you're explicitly allowing GET requests from the curl pod
$ kubectl exec deploy/curl -- curl -s http://productpage:9080/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

## Next steps

With the waypoint proxy in place, you can now enforce Layer 7 policies in the namespace. In addition to authorization policies, [you can use the waypoint proxy to split traffic between services](../manage-traffic/). This is useful when doing canary deployments or A/B testing.

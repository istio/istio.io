## Secure application access {#secure}

After you have added your application to an ambient mode mesh, you can secure application access using Layer 4
authorization policies. This feature lets you control access to and from a service based on client workload
identities, but not at the Layer 7 level, such as HTTP methods like `GET` and `POST`.

### Layer 4 authorization policy

1. Explicitly allow the `sleep` and gateway service accounts to call the `productpage` service:

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
            - cluster.local/ns/default/sa/sleep
            - cluster.local/$GATEWAY_SERVICE_ACCOUNT
    EOF
    {{< /text >}}

1. Confirm the above authorization policy is working:

    {{< text bash >}}
    $ # this should succeed
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ # this should succeed
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ # this should fail with a connection reset error code 56
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    command terminated with exit code 56
    {{< /text >}}

### Layer 7 authorization policy

1.  Install the Kubernetes Gateway API CRDs, which don’t come installed by default on most Kubernetes clusters:

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}


1. Using the Kubernetes Gateway API, you can deploy a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} for your namespace:

    {{< text bash >}}
    $ istioctl x waypoint apply --enroll-namespace --wait
    waypoint default/waypoint applied
    namespace default labeled with "istio.io/use-waypoint: waypoint"
    {{< /text >}}

1. View the waypoint proxy; you should see the details of the gateway resource with `Programmed=True` status:

    {{< text bash >}}
    $ kubectl get gtw waypoint
    NAME       CLASS            ADDRESS       PROGRAMMED   AGE
    waypoint   istio-waypoint   10.96.58.95   True         61s
    {{< /text >}}

1. Update your `AuthorizationPolicy` to explicitly allow the `sleep` service to `GET` the `productpage` service, but perform no other operations:

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

1. Confirm the new waypoint proxy is enforcing the updated authorization policy:

    {{< text bash >}}
    $ # this should fail with an RBAC error because it is not a GET operation
    $ kubectl exec deploy/sleep -- curl -s "http://productpage:9080/productpage" -X DELETE
    RBAC: access denied
    {{< /text >}}

    {{< text bash >}}
    $ # this should fail with an RBAC error because the identity is not allowed
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/
    RBAC: access denied
    {{< /text >}}

    {{< text bash >}}
    $ # this should continue to work
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

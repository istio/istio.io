---
title: Control Headers and Routing
description: Shows how to modify request headers and routing using policy adapters.
weight: 20
keywords: [policies,routing]
---

This task demonstrates how to use a policy adapter to manipulate request headers and routing.

## Before you begin

* Set up Istio on Kubernetes by following the instructions in the
  [Installation guide](/zh/docs/setup/).

    {{< warning >}}
    Policy enforcement **must** be enabled in your cluster for this task. Follow the steps in
    [Enabling Policy Enforcement](/zh/docs/tasks/policy-enforcement/enabling-policy/) to ensure that policy enforcement is enabled.
    {{< /warning >}}

* Follow the set-up instructions in the [ingress task](/zh/docs/tasks/traffic-management/ingress/) to configure an ingress using a gateway.

* Customize the [virtual service](/zh/docs/reference/config/networking/virtual-service/)
  configuration for the `httpbin` service containing two route rules that allow traffic for paths `/headers` and
  `/status`:

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "*"
      gateways:
      - httpbin-gateway
      http:
      - match:
        - uri:
            prefix: /headers
        - uri:
            prefix: /status
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

## Output-producing adapters

In this task, we are using a sample policy adapter `keyval`. In addition to
a policy check result, this adapter returns an output with a single field
called `value`. The adapter is configured with a lookup table, which it uses to
populate the output value, or return `NOT_FOUND` error status if the input
instance key is not present in the lookup table.

1. Deploy the demo adapter:

    {{< text bash >}}
    $ kubectl run keyval --image=gcr.io/istio-testing/keyval:release-1.1 --namespace istio-system --port 9070 --expose
    {{< /text >}}

1. Enable the `keyval` adapter by deploying its template and configuration descriptors:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/policy/keyval-template.yaml@
    $ kubectl apply -f @samples/httpbin/policy/keyval.yaml@
    {{< /text >}}

1. Create a handler for the demo adapter with a fixed lookup table:

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: handler
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      adapter: keyval
      connection:
        address: keyval:9070
      params:
        table:
          jason: admin
    EOF
    {{< /text >}}

1. Create an instance for the handler with the `user` request header as a lookup key:

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: instance
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      template: keyval
      params:
        key: request.headers["user"] | ""
    EOF
    {{< /text >}}

## Request header operations

1. Ensure the _httpbin_ service is accessible through the ingress gateway:

    {{< text bash >}}
    $ curl http://$INGRESS_HOST:$INGRESS_PORT/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        ...
        "X-Envoy-Internal": "true"
      }
    }
    {{< /text >}}

    The output should be the request headers as they are received by the _httpbin_ service.

1. Create a rule for the demo adapter:

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      actions:
      - handler: keyval.istio-system
        instances: [ keyval ]
        name: x
      requestHeaderOperations:
      - name: user-group
        values: [ x.output.value ]
    EOF
    {{< /text >}}

1. Issue a new request to the ingress gateway with the header `key` set to value `jason`:

    {{< text bash >}}
    $ curl -Huser:jason http://$INGRESS_HOST:$INGRESS_PORT/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "User": "jason",
        "User-Agent": "curl/7.58.0",
        "User-Group": "admin",
        ...
        "X-Envoy-Internal": "true"
      }
    }
    {{< /text >}}

    Note the presence of the `user-group` header with the value derived from the
    rule application of the adapter. The expression `x.output.value` in the rule
    evaluates to the populated `value` field returned by the `keyval` adapter.

1. Modify the rule to rewrite the URI path to a different virtual service route
   if the check succeeds:

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      match: source.labels["istio"] == "ingressgateway"
      actions:
      - handler: keyval.istio-system
        instances: [ keyval ]
      requestHeaderOperations:
      - name: :path
        values: [ '"/status/418"' ]
    EOF
    {{< /text >}}

1. Repeat the request to the ingress gateway:

    {{< text bash >}}
    $ curl -Huser:jason -I http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 418 Unknown
    server: istio-envoy
    ...
    {{< /text >}}

    Note that the ingress gateway changed the route _after_ the rule application
    of the policy adapter. The modified request may use a different route and
    destination and is subject to the traffic management configuration.

    The modified request is not checked again by the policy engine within the
    same proxy. Therefore, we recommend to use this feature in gateways, so
    that the server-side policy checks take effect.

## Cleanup

Delete the policy resources for the demo adapter:

{{< text bash >}}
$ kubectl delete rule/keyval handler/keyval instance/keyval adapter/keyval template/keyval -n istio-system
$ kubectl delete service keyval -n istio-system
$ kubectl delete deployment keyval -n istio-system
{{< /text >}}

Complete the clean-up instructions in [ingress task](/zh/docs/tasks/traffic-management/ingress/).


---
title: OPA
description: Information on how to integrate with Open Policy Agent (OPA).
weight: 20
keywords: [integration,opa,authorization]
aliases:
  - /docs/tasks/traffic-management/ingress/opa/
  - /docs/examples/advanced-gateways/opa/
owner: istio/wg-environments-maintainers
test: no
---

[Open Policy Agent (OPA)](https://www.openpolicyagent.org/) is a general-purpose policy engine that can be used to enforce policies across the stack. OPA can be integrated with Istio to enforce authorization policies.

## Understanding Attribute-Based Access Control

Attribute-Based Access Control (ABAC) is an access control model that grants or denies requests based on their attributes - such as the resource and the user. OPA can be used to enforce ABAC policies in Istio.

Istio provides a way to enforce natively RBAC (Role-Based Access Control) policies. However, ABAC policies can be more flexible and can be used to enforce more complex policies.

## How Istio and OPA Work Together

Istio (istio-proxy) is based on [Envoy Proxy](https://www.envoyproxy.io/). certain capabilities of Envoy are configured in filters, being one of them the `ext_authz` filter. This filter can be used to call an external authorization service, like OPA.

While OPA supports this natively, any service that implements the [Envoy's gRPC External Authorization API](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto) can be used.

{{< image width="75%"
    link="./filters.png"
    alt="Filters"
    >}}

When a request is made to an Istio service that is defined with an AuthorizationPolicy, the `ext_authz` filter is called. This filter will call OPA to check if the request is allowed. OPA will evaluate the request against the policies defined and return a decision to Envoy (istio-proxy).

{{< image width="75%"
    link="./opa1.png"
    alt="OPA"
    >}}

### Advanced use-cases

The Envoy's Authorization Service allows receiving from the Authorization server additional attributes that can be used not only to make the decision but also to enrich the request and the response.

{{< text json >}}
{
  "headers": [],
  "headers_to_remove": [],
  "dynamic_metadata": {...},
  "response_headers_to_add": [],
  "query_parameters_to_set": [],
  "query_parameters_to_remove": []
}
{{< /text >}}

When OPA returns its response with these attributes, Envoy (istio-proxy) can modify the request and the response based on the returned attributes:

- Adding headers to the request
- Removing headers from the request
- Adding headers to the response
- Adding query parameters to the request
- Removing query parameters from the request
- Adding dynamic metadata to the request

This last feature, adding dynamic metadata, is very powerful as it allows other filters in Envoy to retrieve the metadata from OPA to run functionality.

{{< image width="75%"
    link="./metadata.png"
    alt="OPA"
    >}}

i.e. OPA rules return metadata that then a Rate Limit filter can use to apply rate limiting based on the metadata. (more on this in the Rate Limiting section [here](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rate_limit_filter#example-3))

## How to Integrate OPA with Istio

To integrate OPA with Istio, you need to deploy OPA with the [Envoy Plugin](https://www.openpolicyagent.org/docs/latest/envoy-tutorial-istio/).

This plugin is the implementation of the Envoy's gRPC Authorization service integrated into the OPA server.

A portion of OPA server configuration:

{{< text yaml >}}
[...]
config.yaml: |
  plugins:
    envoy_ext_authz_grpc:
      addr: :9191 # Port where istio-proxy will connect to
      path: istio/authz/allow # Path to the Rego rule within the loaded policies
  decision_logs:
    console: true
{{< /text >}}

Then, you need to configure Istio to define OPA as an `extensionProvider`. When installing Istio, in the IstioOperator spec or the Helm values file, you need to define the extensionProvider as follows:

{{< text yaml >}}
[...]
extensionProviders:
- name: "opa.local" # Name you want to use to reference the OPA service
  envoyExtAuthzGrpc:
    service: "opa.opa.svc.cluster.local"
    port: "9191"
[...]
{{< /text >}}

Finally, you need to define the AuthorizationPolicy in Istio to call OPA for the services that you want to enforce the ABAC policies.

Notice that you can define multiple `extensionProviders` so that different services connect to different OPA servers.

In this case:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: my-opa-authz
  namespace: istio-system # This enforce the policy on all the mesh being istio-system the mesh config namespace
spec:
  selector: # From all the services in the mesh, the policy will apply to the ones with the label ext-authz: enabled
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: "opa.local"
  rules: [{}] # Empty rules, it will apply to selectors
{{< /text >}}

### OPA Policies

OPA policies use the domain-specific [policy language called Rego](https://www.openpolicyagent.org/docs/latest/policy-language/). Rego is a declarative language designed to help policy authors express their logic in a clear and concise way.

An example of a policy to demonstrate all the capabilities described before could be:

{{< text rego >}}
package mypackage.mysubpackage

import rego.v1

request_headers := input.attributes.request.http.headers

force_unauthenticated if request_headers["x-force-unauthenticated"] == "enabled"

default allow := false

allow if {
  not force_unauthenticated
  request_headers["x-force-authorized"] == "true"
}

default status_code := 403

status_code := 200 if allow

status_code := 401 if force_unauthenticated

default body := "Unauthorized Request"

body := "Authentication Failed" if force_unauthenticated

myrule := {
  "body": body,
  "http_status": status_code,
  "allowed": allow,
  "headers": {"x-validated-by": "my-security-checkpoint"},
  "response_headers_to_add": {"x-add-custom-response-header": "added"},
  "request_headers_to_remove": ["x-force-authorized"],
  "dynamic_metadata": {"my-new-metadata": "my-new-value"},
}
{{< /text >}}

Notice that with this rego, the OPA’s Envoy plugin config should be as follows:

{{< text yaml >}}
[...]
plugins:
  envoy_ext_authz_grpc:
    addr: ":9191"
    path: mypackage/mysubpackage/myrule # Default path for grpc plugin
{{< /text >}}

---
title: JwksUriFetchUnrestricted
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when there are `RequestAuthentication` resources in the mesh, but istiod does not have
the `BLOCKED_CIDRS_IN_JWKS_URIS` environment variable set.

Istiod gets the JSON Web Key Set (JWKS) from the `jwksUri` of each `RequestAuthentication`. Without
`BLOCKED_CIDRS_IN_JWKS_URIS`, istiod can send requests to all addresses, including internal
addresses. A user that can create a `RequestAuthentication` can then make istiod send requests to
internal services.

## An example

You will receive a message like this:

{{< text plain >}}
Warning [IST0175] (Deployment istio-system/istiod) BLOCKED_CIDRS_IN_JWKS_URIS is not configured but 2 RequestAuthentication resource(s) exist (default/jwt-example, foo/jwt-example). Consider configuring it to restrict JWKS URI fetches to trusted networks.
{{< /text >}}

## How to resolve

Set `BLOCKED_CIDRS_IN_JWKS_URIS` on istiod to a comma-separated list of the CIDR ranges that istiod must not
connect to. For example:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      env:
        BLOCKED_CIDRS_IN_JWKS_URIS: "10.0.0.0/8,169.254.169.254/32"
{{< /text >}}

---
title: Denials and White/Black Listing
description: Shows how to control access to a service using simple denials or white/black listing.
weight: 20
keywords: [policies,denial,whitelist,blacklist]
aliases:
    - /docs/tasks/basic-access-control.html
    - /docs/tasks/security/basic-access-control/index.html
    - /docs/tasks/security/secure-access-control/index.html
---

This task shows how to control access to a service using simple denials, attribute-based white or black listing, or IP-based white or black listing.

## Before you begin

* Set up Istio on Kubernetes by following the instructions in the
  [Installation guide](/docs/setup/kubernetes/).

    {{< warning >}}
    Policy enforcement **must** be enabled in your cluster for this task. Follow the steps in
    [Enabling Policy Enforcement](/docs/tasks/policy-enforcement/enabling-policy/) to ensure that policy enforcement is enabled.
    {{< /warning >}}

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

* Initialize the application version routing to direct `reviews` service
  requests from test user "jason" to version v2 and requests from any other
  user to v3.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    and then run the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

    {{< tip >}}
    If you are using a namespace other than `default`,
    use `kubectl -n namespace ...` to specify the namespace.
    {{< /tip >}}

## Simple _denials_

Using Istio you can control access to a service based on any attributes that are available within Mixer.
This simple form of access control is based on conditionally denying requests using Mixer selectors.

Consider the [Bookinfo](/docs/examples/bookinfo/) sample application where the `ratings` service is accessed by multiple versions
of the `reviews` service. We would like to cut off access to version `v3` of the `reviews` service.

1.  Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).

    If you log in as user "jason", you should see black rating stars with each review,
    indicating that the `ratings` service is being called by the "v2" version of the `reviews` service.

    If you log in as any other user (or logout) you should see red rating stars with each review,
    indicating that the `ratings` service is being called by the "v3" version of the `reviews` service.

1.  Explicitly deny access to version `v3` of the `reviews` service.

    Run the following command to set up the deny rule along with a handler and an instance.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-label-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

    Notice the following in the `denyreviewsv3` rule:

    {{< text plain >}}
    match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
    {{< /text >}}

    It matches requests coming from the workload `reviews` with label `v3` to the workload `ratings`.

    This rule uses the `denier` adapter to deny requests coming from version `v3` of the reviews service.
    The adapter always denies requests with a preconfigured status code and message.
    The status code and the message is specified in the [denier](/docs/reference/config/policy-and-telemetry/adapters/denier/)
    adapter configuration.

1.  Refresh the `productpage` in your browser.

    If you are logged out or logged in as any user other than "jason" you will no longer see red ratings stars because
    the `reviews:v3` service has been denied access to the `ratings` service.
    In contrast, if you log in as user "jason" (the `reviews:v2` user) you continue to see
    the black ratings stars.

## Attribute-based _whitelists_ or _blacklists_

Istio supports attribute-based whitelists and blacklists. The following
whitelist configuration is equivalent to the `denier` configuration in the
previous section. The rule effectively rejects requests from version `v3` of
the `reviews` service.

1.  Remove the denier configuration that you added in the previous section.

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label-crd.yaml@
    {{< /text >}}

1.  Verify that when you access the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`) without logging in, you see red stars.
    After performing the following steps you will no longer be able to see stars unless you are logged in as "jason".

1.  Apply configuration for the [`list`](/docs/reference/config/policy-and-telemetry/adapters/list/)
    adapter that white-lists versions `v1, v2`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-whitelist.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-whitelist-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  Verify that when you access the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`) without logging in, you see **no** stars.
Verify that after logging in as "jason" you see black stars.

## IP-based _whitelists_ or _blacklists_

Istio supports _whitelists_ and _blacklists_ based on IP address. You can
configure Istio to accept or reject requests from a specific IP address or a
subnet.

1. Verify you can access the Bookinfo `productpage` found at
   `http://$GATEWAY_URL/productpage`. You won't be able to access it once you
   apply the rules below.

1.  Apply configuration for the [list](/docs/reference/config/policy-and-telemetry/adapters/list/)
    adapter that white-lists subnet `"10.57.0.0\16"` at the ingress gateway:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-ip.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-ip-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  Try to access the Bookinfo `productpage` at
    `http://$GATEWAY_URL/productpage` and verify that you get an error similar
    to: `PERMISSION_DENIED:staticversion.istio-system:<your mesh source ip> is
    not whitelisted`

## Cleanup

* Remove the Mixer configuration for simple denials:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

* Remove the Mixer configuration for attribute-based white- and blacklisting:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-whitelist.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-whitelist-crd.yaml@
    {{< /text >}}

* Remove the Mixer configuration for IP-based white- and blacklisting:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-ip.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-ip-crd.yaml@
    {{< /text >}}

* Remove the application routing rules:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

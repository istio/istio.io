---
title: Basic Access Control
description: Shows how to control access to a service using the Kubernetes labels.
weight: 20
keywords: [security,access-control]
aliases:
    - /docs/tasks/basic-access-control.html
---

This task shows how to control access to a service using the Kubernetes labels.

## Before you begin

* Set up Istio on Kubernetes by following the instructions in the
  [Installation guide](/docs/setup/kubernetes/).

* Deploy the [Bookinfo](/docs/guides/bookinfo/) sample application.

*   Initialize the application version routing to direct `reviews` service requests from
    test user "jason" to version v2 and requests from any other user to v3.

    ```command
    $ istioctl create -f @samples/bookinfo/routing/route-rule-all-v1.yaml@
    ```

    Save the following YAML snippet as `route-rule-reviews-jason-v2-v3.yaml`:

    ```yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
        - reviews
      http:
      - match:
        - headers:
            cookie:
              regex: "^(.*?;)?(user=jason)(;.*)?$"
        route:
        - destination:
            host: reviews
            subset: v2
      - route:
        - destination:
            host: reviews
            subset: v3
    ```

    and then run the following command:

    ```command
    $ istioctl replace -f route-rule-reviews-jason-v2-v3.yaml
    ```

    > If you have conflicting rules that you set in previous tasks,
    > use `istioctl replace` instead of `istioctl create`.
    >
    > If you are using a namespace other than `default`,
    > use `istioctl -n namespace ...` to specify the namespace.

## Access control using _denials_

Using Istio you can control access to a service based on any attributes that are available within Mixer.
This simple form of access control is based on conditionally denying requests using Mixer selectors.

Consider the [Bookinfo](/docs/guides/bookinfo/) sample application where the `ratings` service is accessed by multiple versions
of the `reviews` service. We would like to cut off access to version `v3` of the `reviews` service.

1.  Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage).

    If you log in as user "jason", you should see black rating stars with each review,
    indicating that the `ratings` service is being called by the "v2" version of the `reviews` service.

    If you log in as any other user (or logout) you should see red rating stars with each review,
    indicating that the `ratings` service is being called by the "v3" version of the `reviews` service.

1.  Explicitly deny access to version `v3` of the `reviews` service.

    Run the following command to set up the deny rule along with a handler and an instance.

    ```command
    $ istioctl create -f @samples/bookinfo/kube/mixer-rule-deny-label.yaml@
    Created config denier/default/denyreviewsv3handler at revision 2882105
    Created config checknothing/default/denyreviewsv3request at revision 2882106
    Created config rule/default/denyreviewsv3 at revision 2882107
    ```

    Notice the following in the `denyreviewsv3` rule:

    ```plain
    match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
    ```

    It matches requests coming from the service `reviews` with label `v3` to the service `ratings`.

    This rule uses the `denier` adapter to deny requests coming from version `v3` of the reviews service.
    The adapter always denies requests with a preconfigured status code and message.
    The status code and the message is specified in the [denier](/docs/reference/config/policy-and-telemetry/adapters/denier/)
    adapter configuration.

1.  Refresh the `productpage` in your browser.

    If you are logged out or logged in as any user other than "jason" you will no longer see red ratings stars because
    the `reviews:v3` service has been denied access to the `ratings` service.
    In contrast, if you log in as user "jason" (the `reviews:v2` user) you continue to see
    the black ratings stars.

## Access control using _whitelists_

Istio also supports attribute-based whitelists and blacklists. The following whitelist configuration is equivalent to the
`denier` configuration in the previous section. The rule effectively rejects requests from version `v3` of the `reviews` service.

1.  Remove the denier configuration that you added in the previous section.

    ```command
    $ istioctl delete -f @samples/bookinfo/kube/mixer-rule-deny-label.yaml@
    ```

1. Verify that when you access the Bookinfo `productpage` (http://$GATEWAY_URL/productpage) without logging in, you see red stars.
   After performing the following steps you will no longer be able to see stars unless you are logged in as "jason".

1.  Create configuration for the [`list`](/docs/reference/config/policy-and-telemetry/adapters/list/)
    adapter that lists versions `v1, v2`.
    Save the following YAML snippet as `whitelist-handler.yaml`:

    ```yaml
    apiVersion: config.istio.io/v1alpha2
    kind: listchecker
    metadata:
      name: whitelist
    spec:
      # providerUrl: ordinarily black and white lists are maintained
      # externally and fetched asynchronously using the providerUrl.
      overrides: ["v1", "v2"]  # overrides provide a static list
      blacklist: false
    ```

    and then run the following command:

    ```command
    $ istioctl create -f whitelist-handler.yaml
    ```

1.  Extract the version label by creating an instance of the [`listentry`](/docs/reference/config/policy-and-telemetry/templates/listentry/) template.
Save the following YAML snippet as `appversion-instance.yaml`:

    ```yaml
    apiVersion: config.istio.io/v1alpha2
    kind: listentry
    metadata:
      name: appversion
    spec:
      value: source.labels["version"]
    ```

    and then run the following command:

    ```command
    $ istioctl create -f appversion-instance.yaml
    ```

1.  Enable `whitelist` checking for the ratings service.
Save the following YAML snippet as `checkversion-rule.yaml`:

    ```yaml
        apiVersion: config.istio.io/v1alpha2
        kind: rule
        metadata:
          name: checkversion
        spec:
          match: destination.labels["app"] == "ratings"
          actions:
          - handler: whitelist.listchecker
            instances:
            - appversion.listentry
    ```

    and then run the following command:

    ```command
    $ istioctl create -f checkversion-rule.yaml
    ```

1. Verify that when you access the Bookinfo `productpage` (http://$GATEWAY_URL/productpage) without logging in, you see **no** stars.
Verify that after logging in as "jason" you see black stars.

## Cleanup

*   Remove the mixer configuration:

    ```command
    $ istioctl delete -f checkversion-rule.yaml
    $ istioctl delete -f appversion-instance.yaml
    $ istioctl delete -f whitelist-handler.yaml
    ```

*   Remove the application routing rules:

    ```command
    $ istioctl delete -f @samples/bookinfo/routing/route-rule-all-v1.yaml@
    ```

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/guides/bookinfo/#cleanup) instructions
  to shutdown the application.

## What's next

* Learn how to securely control access based on the service account [here](/docs/tasks/security/secure-access-control/).

* Learn more about [Mixer](/docs/concepts/policies-and-telemetry/overview/) and [Mixer Config](/docs/concepts/policies-and-telemetry/config/).

* Discover the full [Attribute Vocabulary](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).

* Understand the differences between Kubernetes network policies and Istio
access control policies from this
[blog](/blog/2017/0.1-using-network-policy/).

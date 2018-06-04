---
title: Control Egress TCP Traffic
description: Describes how to configure Istio to route TCP traffic from services in the mesh to external services.
weight: 41
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. A quick reminder: by default, Istio-enabled applications are unable to access URLs outside the cluster. To enable such access, a [ServiceEntry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) for the external service must be defined, or, alternatively, [direct access to external services](/docs/tasks/traffic-management/egress/#calling-external-services-directly) must be configured.

This task describes how to configure Istio to expose external TCP services to applications inside the Istio service mesh.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) sample application which will be used as a test source for external calls.

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
    ```

    **Note**: any pod that you can execute `curl` from is good enough.

## Using Istio service entries to enable external TCP traffic

In this task we access `wikipedia.org` by HTTPS originated from the application. This task demonstrates the use case where an application cannot use HTTP with TLS origination by the sidecar proxy. Using HTTP with TLS origination by the sidecar proxy is described in the [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task. In that task, `https://google.com` was accessed by issuing HTTP requests to `http://www.google.com:443`.

The HTTPS traffic originated from the application will be treated by Istio as _opaque_ TCP. To enable such traffic, we define a TCP `ServiceEntry` on port 443. In TCP service entries, as opposed to HTTP-based ones, the destinations are specified by IPs or by blocks of IPs in [CIDR notation](https://tools.ietf.org/html/rfc2317).

Let's assume for the sake of this example that we want to access `wikipedia.org` by the domain name. This means that we have to specify all the IPs of `wikipedia.org` in our TCP `ServiceEntry`. Fortunately, the IPs of `wikipedia.org` are published [here]( https://www.mediawiki.org/wiki/Wikipedia_Zero/IP_Addresses). It is a list of IP blocks in [CIDR notation](https://tools.ietf.org/html/rfc2317): `91.198.174.192/27`, `103.102.166.224/27`, and more.

## Creating a service entry

Let's create a `ServiceEntry` to enable TCP access to `wikipedia.org`:

```bash
cat <<EOF | istioctl create -f -
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: wikipedia-ext
spec:
  hosts:
  - wikipedia.org
  addresses:
  - 91.198.174.192/27
  - 103.102.166.224/27
  - 198.35.26.96/27
  - 208.80.153.224/27
  - 208.80.154.224/27
  ports:
  - number: 443
    protocol: TCP
    name: tcp-port
  resolution: NONE
EOF
```

This command instructs the Istio proxy to forward requests on port 443 of any of the `wikipedia.org` IP addresses to the same IP address to which the connection was bound.

## Access wikipedia.org by HTTPS

1.  `kubectl exec` into the pod to be used as the test source. If you are using the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) application, run the following command:

    ```command
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep bash
    ```

1.  Make a request and verify that we can access https://www.wikipedia.org successfully:

    ```command
    $ curl -o /dev/null -s -w "%{http_code}\n" https://www.wikipedia.org
    200
    ```

    We should see `200` printed as the output, which is the HTTP code _OK_.

1.  Now let's fetch the current number of the articles available on Wikipedia in the English language:

    ```command
    $ curl -s https://en.wikipedia.org/wiki/Main_Page | grep articlecount | grep 'Special:Statistics'
    <div id="articlecount" style="font-size:85%;"><a href="/wiki/Special:Statistics" title="Special:Statistics">5,563,121</a> articles in <a  href="/wiki/English_language" title="English language">English</a></div>
    ```

    This means there were 5,563,121 articles in Wikipedia in English when this task was written.

## Cleanup

1.  Remove the `ServiceEntry` we created.

    ```command
    $ istioctl delete serviceentry wikipedia-ext
    ```

1.  Shutdown the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) application.

    ```command
    $ kubectl delete -f samples/sleep/sleep.yaml
    ```

## What's next

* Learn more about [service entries](/docs/concepts/traffic-management/rules-configuration/#service-entries).

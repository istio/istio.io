---
title: Monitoring and Access Policies for HTTP Egress Traffic
description: Describes how to configure Istio for monitoring and access policies of HTTP egress traffic.
publishdate: 2018-06-22
subtitle:
attribution: Vadim Eisenberg and Ronen Schaffer
weight: 86
keywords: [egress,traffic-management,access-control,monitoring]
---

While Istio's main focus is management of traffic between microservices inside a service mesh, Istio can also manage
ingress (from outside into the mesh) and egress (from the mesh outwards) traffic. Istio can uniformly enforce access
policies and aggregate telemetry data for mesh-internal, ingress and egress traffic.

In this blog post we show how Istio monitoring and access policies are applied to HTTP egress traffic. The instructions
in this blog post are valid for Istio [0.8.0](https://github.com/istio/istio/releases/tag/0.8.0) or later.

## Use case

Consider an organization that runs applications that process content from _cnn.com_. The applications are decomposed
into microservices deployed in an Istio service mesh. The applications access pages of various topics from _cnn.com_: [edition.cnn.com/politics](https://edition.cnn.com/politics), [edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health). The organization [configures Istio to allow access to edition.cnn.com](/docs/tasks/traffic-management/egress-tls-origination/) and everything works fine. However, at some
point in time the organization decides to banish politics. Practically, it means blocking access to
[edition.cnn.com/politics](https://edition.cnn.com/politics) and allowing access to
[edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health)
only. The organization will grant permissions to individual applications, to applications in particular namespaces and
to particular users to access [edition.cnn.com/politics](https://edition.cnn.com/politics), on a case-by-case basis.

To achieve that goal, the organization's operations people will monitor access to the external services and will
analyze Istio logs to verify that no unauthorized request was sent to
[edition.cnn.com/politics](https://edition.cnn.com/politics). They will also configure Istio to prevent access to [edition.cnn.com/politics](https://edition.cnn.com/politics) automatically.

The organization is resolved to prevent any tampering with the new policy. It decides to put mechanisms in place that
will prevent any possibility for a malicious application to access the forbidden topic.

## Related tasks

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the
  Kubernetes cluster) HTTP and HTTPS services can be accessed by applications inside the mesh. The
  [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task demonstrates how to
  allow applications to send HTTP requests to external servers that require HTTPS. The [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway/) task describes how to configure Istio to direct egress
  traffic through a dedicated gateway service called _egress gateway_.

The [Collecting Metrics and Logs](/docs/tasks/telemetry/metrics-logs/) task describes how to configure metrics and logs
 for services in a mesh. The [Visualizing Metrics with Grafana](/docs/tasks/telemetry/using-istio-dashboard/) describes
 the Istio Dashboard to monitor mesh traffic. The [Basic Access Control](/docs/tasks/security/basic-access-control/)
 task shows how to control access to in-mesh services. The
 [Secure Access Control](http://localhost:1313/docs/tasks/security/secure-access-control/) task shows how to configure
 access policies using black or white list checkers. As opposed to the telemetry and security tasks above, this blog
 post describes Istio's monitoring and access policies applied exclusively to the egress traffic.

## Before you begin

Follow the steps in the [Configure an Egress Gateway, Perform TLS origination with the egress Gateway](/docs/tasks/traffic-management/egress-gateway/#perform-tls-origination-with-the-egress-gateway) task, without
the [Cleanup](/docs/tasks/traffic-management/egress-gateway/#cleanup) step. After you accomplish this, you will be able
to access [edition.cnn.com/politics](https://edition.cnn.com/politics) from an in-mesh container that has _curl_
installed. In the instructions of this blog post we assume that the `SOURCE_POD` environment variable contains the pod
name.

## Configure monitoring and access policies

Note that since you want to accomplish your tasks in a _secure way_, you must direct egress traffic through
_egress gateway_, as described in the [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway/)
task. The _secure way_ here means that you want to prevent malicious applications from bypassing Istio monitoring and
policy enforcement.

In our scenario, the organization performed the instructions in the [Before you begin](#before-you-begin) section. It
enabled traffic to _edition.cnn.com_ and configured that traffic to pass through the egress gateway. Now it is ready to
configure Istio for monitoring and access policies for the traffic to _edition.cnn.com_.

### Logging

Configure Istio to log access to _*.cnn.com_. You create a `logentry` and two
[stdio](/docs/reference/config/policy-and-telemetry/adapters/stdio/) `handlers`, one for logging forbidden access
(_error_ log level) and another one for logging all access to _*.cnn.com_ (_info_ log level). Then you create `rules` to
direct your `logentry` instances to your `handlers`. One rule directs access to _*.cnn.com/politics_ to the handler for
logging forbidden access, another rule directs log entries to the handler that outputs each access to _*.cnn.com_ as an
_info_ log entry. To understand the Istio `logentries`, `rules`, and `handlers`, see
[Istio Adapter Model](/blog/2017/adapter-model/). A diagram with the involved entities and dependencies between them
appears below:

{{< image width="80%" ratio="68.27%"
    link="../img/egress-adapters-monitoring.svg"
    caption="Instances, rules and handlers for egress monitoring"
    >}}

1.  Create the `logentry`, `rules` and `handlers`:
    ```bash
        cat <<EOF | istioctl create -f -
        # Log entry for egress access
        apiVersion: "config.istio.io/v1alpha2"
        kind: logentry
        metadata:
          name: egress-access
          namespace: istio-system
        spec:
          severity: '"info"'
          timestamp: request.time
          variables:
            destination: request.host | "unknown"
            path: request.path | "unknown"
            source: source.labels["app"] | source.service | "unknown"
            sourceNamespace: source.namespace | "unknown"
            user: source.user | "unknown"
            responseCode: response.code | 0
            responseSize: response.size | 0
          monitored_resource_type: '"UNSPECIFIED"'
        ---
        # Handler for error egress access entries
        apiVersion: "config.istio.io/v1alpha2"
        kind: stdio
        metadata:
          name: egress-error-logger
          namespace: istio-system
        spec:
         severity_levels:
           info: 2 # output log level as error
         outputAsJson: true
        ---
        # Rule to handle access to *.cnn.com/politics
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: handle-politics
          namespace: istio-system
        spec:
          match: request.host.endsWith("cnn.com") && request.path.startsWith("/politics")
          actions:
          - handler: egress-error-logger.stdio
            instances:
            - egress-access.logentry
        ---
        # Handler for info egress access entries
        apiVersion: "config.istio.io/v1alpha2"
        kind: stdio
        metadata:
          name: egress-access-logger
          namespace: istio-system
        spec:
          severity_levels:
            info: 0 # output log level as info
          outputAsJson: true
        ---
        # Rule to handle access to *.cnn.com
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: handle-cnn-access
          namespace: istio-system
        spec:
          match: request.host.endsWith(".cnn.com")
          actions:
          - handler: egress-access-logger.stdio
            instances:
              - egress-access.logentry
        EOF
    ```

1.  Send three HTTP requests to _cnn.com_, to [edition.cnn.com/politics](https://edition.cnn.com/politics), [edition.cnn.com/sport](https://edition.cnn.com/sport) and [edition.cnn.com/health](https://edition.cnn.com/health).
All three should return _200 OK_.

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    200
    200
    200
    ```

1.  Query the Mixer log and see that the information about the requests appears in the log:
    ```command-output-as-json
    $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep egress-access | grep cnn | tail -4
    {"level":"info","time":"2018-06-18T13:22:58.317448Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":200,"responseSize":150448,"source":"sleep","user":"unknown"}
    {"level":"error","time":"2018-06-18T13:22:58.317448Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":200,"responseSize":150448,"source":"sleep","user":"unknown"}
    {"level":"info","time":"2018-06-18T13:22:59.234426Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/sport","responseCode":200,"responseSize":358651,"source":"sleep","user":"unknown"}
    {"level":"info","time":"2018-06-18T13:22:59.354943Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/health","responseCode":200,"responseSize":332218,"source":"sleep","user":"unknown"}
    ```

    You see four log entries related to your three requests. Three _info_ entries about the access to _edition.cnn.com_
    and one _error_ entry about the access to _edition.cnn.com/politics_. The service mesh operators can see all the
    access instances, and can also search the log for _error_ log entries that represent forbidden accesses. This is the
    first security measure the organization can apply before blocking the forbidden accesses automatically, namely logging
     all the forbidden access instances as errors. In some settings this can be a sufficient security measure.

### Access control by routing

After enabling logging of access to _edition.cnn.com_, automatically enforce an access policy, namely allow
accessing _/health_ and _/sport_ URL paths only. Such a simple policy control can be implemented with Istio routing.

1.  Redefine your `VirtualService` for _edition.cnn.com_:

    ```bash
        cat <<EOF | istioctl replace -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: direct-through-egress-gateway
        spec:
          hosts:
          - edition.cnn.com
          gateways:
          - istio-egressgateway
          - mesh
          http:
          - match:
            - gateways:
              - mesh
              port: 80
            route:
            - destination:
                host: istio-egressgateway.istio-system.svc.cluster.local
                port:
                  number: 443
              weight: 100
          - match:
            - gateways:
              - istio-egressgateway
              port: 443
              uri:
                regex: "/health|/sport"
            route:
            - destination:
                host: edition.cnn.com
                port:
                  number: 443
              weight: 100
        EOF
    ```

    Note that you added a `match` by `uri` condition that checks that the URL path is
    either _/health_ or _/sport_. Also note that this condition is added to the `istio-egressgateway`
    section of the `VirtualService`, since the egress gateway is a hardened component in terms of security (see
    [egress gateway security considerations]
    (/docs/tasks/traffic-management/egress-gateway/#additional-security-considerations)). You don't want any tampering
    with your policies.

1.  Send the previous three HTTP requests to _cnn.com_:

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    404
    200
    200
    ```

    The request to [edition.cnn.com/politics](https://edition.cnn.com/politics) returned _404 Not Found_, while requests
     to [edition.cnn.com/sport](https://edition.cnn.com/sport) and
     [edition.cnn.com/health](https://edition.cnn.com/health) returned _200 OK_, as expected.

    > You may need to wait several seconds for the update of the `VirtualService` to propagate to the egress
    gateway.

1.  Query the Mixer log and see that the information about the requests appears again in the log:

    ```command-output-as-json
    $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep egress-access | grep cnn | tail -4
    {"level":"info","time":"2018-06-19T12:39:48.050666Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":404,"responseSize":0,"source":"sleep","sourceNamespace":"default","user":"unknown"}
    {"level":"error","time":"2018-06-19T12:39:48.050666Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":404,"responseSize":0,"source":"sleep","sourceNamespace":"default","user":"unknown"}
    {"level":"info","time":"2018-06-19T12:39:48.091268Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/health","responseCode":200,"responseSize":334027,"source":"sleep","sourceNamespace":"default","user":"unknown"}
    {"level":"info","time":"2018-06-19T12:39:48.063812Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/sport","responseCode":200,"responseSize":355267,"source":"sleep","sourceNamespace":"default","user":"unknown"}
    ```

    You still get info and error messages regarding accesses to
    [edition.cnn.com/politics](https://edition.cnn.com/politics), however this time the `responseCode` is `404`, as
    expected.

While implementing access control using Istio routing worked for us in this simple case, it would not suffice for more
complex cases. For example, the organization may want to allow access to
[edition.cnn.com/politics](https://edition.cnn.com/politics) under certain conditions, so more complex policy logic than
 just filtering by URL paths will be required. You may want to apply [Istio Mixer Adapters](/blog/2017/adapter-model/),
 for example [white lists](/docs/tasks/security/basic-access-control/#access-control-using-whitelists) or [black lists](/docs/tasks/security/basic-access-control/#access-control-using-denials) of allowed/forbidden URL paths,
 respectively. [Policy Rules](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/) allow specifying
 complex conditions, specified in a
 [rich expression language](/docs/reference/config/policy-and-telemetry/expression-language/), which includes AND and OR
  logical operators. The rules can be reused for both logging and policy checks. More advanced users may want to apply
  [Istio Role-Based Access Control](/docs/concepts/security/rbac/).

An additional aspect is integration with remote access policy systems. If the organization in our use case operates some
[Identity and Access Management](https://en.wikipedia.org/wiki/Identity_management) system, you may want to configure
Istio to use access policy information from such a system. You implement this integration by applying
[Istio Mixer Adapters](/blog/2017/adapter-model/).

Cancel the access control by routing you used in this section and implement access control by Mixer policy checks
in the next section.

1.  Replace the `VirtualService` for _edition.cnn.com_ with your previous version from the [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway/#perform-tls-origination-with-the-egress-gateway) task:

    ```bash
        cat <<EOF | istioctl replace -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: direct-through-egress-gateway
        spec:
          hosts:
          - edition.cnn.com
          gateways:
          - istio-egressgateway
          - mesh
          http:
          - match:
            - gateways:
              - mesh
              port: 80
            route:
            - destination:
                host: istio-egressgateway.istio-system.svc.cluster.local
                port:
                  number: 443
              weight: 100
          - match:
            - gateways:
              - istio-egressgateway
              port: 443
            route:
            - destination:
                host: edition.cnn.com
                port:
                  number: 443
              weight: 100
        EOF
    ```

1.  Send the previous three HTTP requests to _cnn.com_, this time you should get three _200 OK_ responses as
previously:

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    200
    200
    200
    ```
> You may need to wait several seconds for the update of the `VirtualService` to propagate to the egress
gateway.

### Access control by Mixer policy checks

In this step you use a Mixer
[Listchecker adapter](https://istio.io/docs/reference/config/policy-and-telemetry/adapters/list/), its whitelist
variety. You define a `listentry` with the URL path of the request and a `listchecker` to check the `listentry` using a
static list of allowed URL paths, specified by the `overrides` field. For an external [Identity and Access Management](https://en.wikipedia.org/wiki/Identity_management) system, use the `providerurl` field instead. The updated
diagram of the instances, rules and handlers appears below. Note that you reuse the same policy rule, `handle-cnn-access`
 both for logging and for access policy checks.

{{< image width="80%" ratio="65.45%"
    link="../img/egress-adapters-monitoring-policy.svg"
    caption="Instances, rules and handlers for egress monitoring and access policies"
    >}}

1.  Define `path-checker` and `request-path`:
    ```bash
        cat <<EOF | istioctl create -f -
        apiVersion: "config.istio.io/v1alpha2"
        kind: listchecker
        metadata:
          name: path-checker
          namespace: istio-system
        spec:
          overrides: ["/health", "/sport"]  # overrides provide a static list
          blacklist: false
        ---
        apiVersion: "config.istio.io/v1alpha2"
        kind: listentry
        metadata:
          name: request-path
          namespace: istio-system
        spec:
          value: request.path
        EOF
    ```

1.  Modify the `handle-cnn-access` policy rule to send `request-path` instances to the `path-checker`:

    ```bash
        cat <<EOF | istioctl replace -f -
        # Rule handle egress access to cnn.com
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: handle-cnn-access
          namespace: istio-system
        spec:
          match: request.host.endsWith(".cnn.com")
          actions:
          - handler: egress-access-logger.stdio
            instances:
              - egress-access.logentry
          - handler: path-checker.listchecker
            instances:
              - request-path.listentry
        EOF
    ```

1.  Perform your usual test by sending HTTP requests to
 [edition.cnn.com/politics](https://edition.cnn.com/politics), [edition.cnn.com/sport](https://edition.cnn.com/sport)
 and [edition.cnn.com/health](https://edition.cnn.com/health). As expected, the request to
 [edition.cnn.com/politics](https://edition.cnn.com/politics) returns _404_.

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    404
    200
    200
    ```

### Access control by Mixer policy checks, part 2

After the organization in our use case managed to configure logging and access control, it decided to extend its access
policy by allowing the applications in the _politics_ namespace to access any topic of _cnn.com_, without being
monitored. You'll see how this requirement can be configured in Istio.

1.  Create the _politics_ namespace:

    ```command
    $ kubectl create namespace politics
    namespace "politics" created
    ```

1.  Start the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) sample
        in the _politics_ namespace.

    If you have enabled
    [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), do

    ```command
    $ kubectl apply -n politics -f @samples/sleep/sleep.yaml@
    ```

    otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    ```command
    $ kubectl apply -n politics -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    ```

1.  Define a shell variable to hold the name of the source pod in the _politics_ namespace for sending requests to
external services.
    If you used the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) sample, you run:

    ```command
    $ export SOURCE_POD_IN_POLITICS=$(kubectl get pod -n politics -l app=sleep -o jsonpath={.items..metadata.name})
    ```

1.  Perform your usual test of sending three HTTP requests this time from `$SOURCE_POD_IN_POLITICS`.
  The request to [edition.cnn.com/politics](https://edition.cnn.com/politics) returns _404_, since you did not configure
  the exception for the _politics_ namespace.

    ```command
    $ kubectl exec -it $SOURCE_POD_IN_POLITICS -n politics -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    404
    200
    200
    ```

1.  Query the Mixer log and see that the information about the requests from the _politics_ namespace appears in
the log:

    ```command-output-as-json
    $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep egress-access | grep cnn | tail -4
    {"level":"info","time":"2018-06-19T17:37:14.639102Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":404,"responseSize":76,"source":"sleep","sourceNamespace":"politics","user":"unknown"}
    {"level":"error","time":"2018-06-19T17:37:14.639102Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":404,"responseSize":76,"source":"sleep","sourceNamespace":"politics","user":"unknown"}
    {"level":"info","time":"2018-06-19T17:37:14.653225Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/sport","responseCode":200,"responseSize":356349,"source":"sleep","sourceNamespace":"politics","user":"unknown"}
    {"level":"info","time":"2018-06-19T17:37:14.767923Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/health","responseCode":200,"responseSize":334027,"source":"sleep","sourceNamespace":"politics","user":"unknown"}
    ```

    Note that `sourceNamespace` equals `politics` in the output above.

1.  Redefine `handle-cnn-access` and `handle-politics` policy rules, to make the applications in the _politics_
namespace exempt from monitoring and policy enforcement.

    ```bash
        cat <<EOF | istioctl replace -f -
        # Rule to handle access to *.cnn.com/politics
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: handle-politics
          namespace: istio-system
        spec:
          match: request.host.endsWith("cnn.com") && request.path.startsWith("/politics") && source.namespace != "politics"
          actions:
          - handler: egress-error-logger.stdio
            instances:
            - egress-access.logentry
        ---
        # Rule handle egress access to cnn.com
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: handle-cnn-access
          namespace: istio-system
        spec:
          match: request.host.endsWith(".cnn.com") && source.namespace != "politics"
          actions:
          - handler: egress-access-logger.stdio
            instances:
              - egress-access.logentry
          - handler: path-checker.listchecker
            instances:
              - request-path.listentry
        EOF
    ```

1.  Perform your usual test from `$SOURCE_POD`:

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    404
    200
    200
    ```

    Since `$SOURCE_POD` is in the `default` namespace, access to  [edition.cnn.com/politics](https://edition.cnn.com/politics) is forbidden, as previously.

1.  Perform the previous test from `$SOURCE_POD_IN_POLITICS`:

    ```command
    $ kubectl exec -it $SOURCE_POD_IN_POLITICS -n politics -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    200
    200
    200
    ```

    Access to all the topics of _edition.cnn.com_ is allowed.

1.  Examine the Mixer log and see that no more requests with `sourceNamespace` equal `"politics"` appear in the
log.

    ```command
    $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep egress-access | grep cnn
    ```

### Dashboard

As an additional security measure, let our organization's operation people visually monitor egress traffic.

1.  Follow the steps 1-3 of the [Visualizing Metrics with Grafana](/docs/tasks/telemetry/using-istio-dashboard/#viewing-the-istio-dashboard) task.

1.  Send requests to _cnn.com_ from `$SOURCE_POD`:

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    404
    200
    200
    ```

    Since `$SOURCE_POD` is in the `default` namespace, access to  [edition.cnn.com/politics](https://edition.cnn.com/politics) is forbidden, as previously.

1.  Send requests to _cnn.com_ from `$SOURCE_POD_IN_POLITICS`:

    ```command
    $ kubectl exec -it $SOURCE_POD_IN_POLITICS -n politics -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    200
    200
    200
    ```

1.  Scroll the dashboard to _HTTP services_, _istio-egressgateway.istio-system.svc.cluster.local_ section. You should
see a graph similar to the following:

    {{< image width="100%" ratio="19.47%"
    link="../img/dashboard-egress-gateway.png"
    caption="Dashboard section of istio-egressgateway"
    >}}

    You can see the _404_ error code received by the _sleep_ application from the _default_ namespace, _unknown_ version,
     in the _Requests by Source, Version and Response Code_ section on the left. This information can give the operations
      people a visual clue regarding which application tries to perform forbidden access. You can also see the _200_ code
       received by _sleep_ applications from the _default_ and _politics_ namespaces, so you can know which applications
       performed valid access to external services.

## Comparison with HTTPS egress traffic control

In this use case the applications used HTTP and Istio Egress Gateway performed TLS origination for them. Alternatively,
the applications could originate TLS themselves by issuing HTTPS requests to _edition.cnn.com_. In this section we
describe both approaches and their pros and cons.

In the HTTP approach, the requests are sent unencrypted on the local host, intercepted by the Istio sidecar proxy and
forwarded to the egress gateway. If Istio is deployed with mutual TLS, the traffic between the sidecar proxy and the
egress gateway is encrypted. The egress gateway decrypts the traffic, inspects the URL path, the HTTP method and
headers, reports telemetry and performs policy checks. If the request is not blocked by some policy check, the egress
 gateway performs TLS origination to the external destination (_cnn.com_ in our case), so the request is encrypted again
  and sent encrypted to the external destination. The diagram below demonstrates the network flow of this approach. The
  HTTP protocol inside the gateway designates the protocol as seen by the gateway after decryption.

{{< image width="80%" ratio="73.96%"
link="../img/http-to-gateway.svg"
caption="HTTP egress traffic through an egress gateway"
>}}

The drawback of this approach is that the requests are sent unencrypted on the localhost, which may be against security
 policies in some organizations. Also some SDKs have external service URLs hard-coded, including the protocol, so
 sending HTTP requests could be impossible. The advantage of this approach is the ability to inspect HTTP methods,
 headers and URL paths, and to apply policies based on them.

In the HTTPS approach, the requests are encrypted end-to-end, from the application to the external destination. The
diagram below demonstrates the network flow of this approach. The HTTPS protocol inside the gateway designates the
protocol as seen by the gateway.

{{< image width="80%" ratio="73.96%"
link="../img/https-to-gateway.svg"
caption="HTTPS egress traffic through an egress gateway"
>}}

The end-to-end HTTPS is considered a better approach from the security point of view. However, since the traffic is
encrypted the Istio proxies and the egress gateway can only see the source and destination IPs and the [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) of the destination. In case of Istio with mutual TLS, the
[identity of the source](/docs/concepts/security/mutual-tls/#identity) is also known. The gateway is unable to inspect
the URL path, the HTTP method and the headers of the requests, so no monitoring and policies based on the HTTP
information can be possible. In our use case, the organization would be able to allow access to _edition.cnn.com_. For
Istio with mutual TLS, the organization will be able to specify which applications are allowed to access
_edition.cnn.com_. However, it will not be possible to allow or block access to specific URL paths of _edition.cnn.com_.
 Neither blocking access to [edition.cnn.com/politics](https://edition.cnn.com/politics) nor monitoring such access are
 possible with the HTTPS approach.

We guess that each organization will consider the pros and cons of the two approaches and choose the one most
appropriate to its needs.

## Summary

In this blog post we showed how different monitoring and policy mechanisms of Istio can be applied to HTTP egress
traffic. Monitoring can be implemented by configuring a logging adapter and deploying the Istio dashboard. Access
policies can be implemented by configuring `VirtualServices` or by configuring various policy check adapters. We
demonstrated a simple policy that allowed certain URL paths only. We also showed a more complex policy that extended the
 simple policy by making an exemption to the applications from a certain namespace. Finally, we compared
 HTTP-with-TLS-origination egress traffic with HTTPS egress traffic, in terms of control possibilities by Istio.

## Cleanup

1.  Perform the instructions in [Cleanup](/docs/tasks/traffic-management/egress-gateway/#cleanup) section of the
[Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway/) task.

1.  Delete the logging and policy checks configuration:

    ```command
    $ kubectl delete logentry egress-access -n istio-system
    $ kubectl delete stdio egress-error-logger -n istio-system
    $ kubectl delete stdio egress-access-logger -n istio-system
    $ kubectl delete rule handle-politics -n istio-system
    $ kubectl delete rule handle-cnn-access -n istio-system
    $ kubectl delete -n istio-system listchecker path-checker
    $ kubectl delete -n istio-system listentry request-path
    ```

1.  Delete the _politics_ namespace:

    ```command
    $ kubectl delete namespace politics
    ```

1.  Perform the instructions in [Cleanup](/docs/tasks/telemetry/using-istio-dashboard/#cleanup) section of the
[Visualizing Metrics with Grafana](/docs/tasks/telemetry/using-istio-dashboard/) task.

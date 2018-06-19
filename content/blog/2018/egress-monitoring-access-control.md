---
title: Monitoring and Access Policies for HTTP Egress Traffic
description: Describes how to configure Istio for monitoring and access policies of HTTP egress traffic.
publishdate: 2018-06-15
subtitle:
attribution: Vadim Eisenberg and Ronen Schaffer
weight: 86
keywords: [egress, access-control, monitoring]
---

While the main focus of Istio is managing traffic between the microservices inside a service mesh, Istio can also  manage ingress (from outside into the mesh) and egress (from the mesh outwards) traffic. Istio can uniformly enforce access policies and aggregate telemetry data for mesh-internal, ingress and egress traffic.

In this blog post we show how Istio monitoring and access policies are applied to egress traffic. The instructions in this blog post are valid for Istio 0.8.0 or later.

## Use case

Consider an organization that runs applications that process content of _cnn.com_. The applications are decomposed into microservices deployed in an Istio service mesh. The applications access pages of various topics of _cnn.com_: [edition.cnn.com/politics](https://edition.cnn.com/politics), [edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health). The organization [configures Istio to allow access to edition.cnn.com](docs/tasks/traffic-management/egress-tls-origination/) and everything works fine. However, at some point in time the organization decides to banish politics. Practically, it means blocking access to [edition.cnn.com/politics](https://edition.cnn.com/politics) and allowing access to [edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health) only. The organization will grant permissions to individual applications, to applications in particular namespaces and to particular users to access [edition.cnn.com/politics](https://edition.cnn.com/politics), on a case-by-case basis.

To achieve that goal, the organization's operations people will monitor the access to the external services and will analyze the Istio logs to verify that no request to [edition.cnn.com/politics](https://edition.cnn.com/politics) was sent. They will also configure Istio to prevent access to [edition.cnn.com/politics](https://edition.cnn.com/politics) automatically.

The organization is resolved to prevent any tampering with the new policy. It decided to put mechanisms in place that will prevent any possibility for a malicious application to access the forbidden topic.

## Related tasks

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. The [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task demonstrates how to allow the applications to send HTTP requests to external servers that require HTTPS. The [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway/) task describes how to configure Istio to direct egress traffic through a dedicated gateway service called _egress gateway_.

The [Collecting Metrics and Logs](/docs/tasks/telemetry/metrics-logs/) task describes how to configure metrics and logs for services in a mesh. The [Visualizing Metrics with Grafana](/docs/tasks/telemetry/using-istio-dashboard/) describes the Istio Dashboard to monitor mesh traffic. The [Basic Access Control](/docs/tasks/security/basic-access-control/) task shows how to control access to in-mesh services. As opposed to the telemetry and security tasks above, this blog post describes Istio's monitoring and access policies applied exclusively to the egress traffic.

## Before you begin

Let's install Istio with mutual TLS (since the organization in our use case requires strict security). Then we direct HTTP egress traffic sent to _edition.cnn.com_ to an egress gateway, which will perform TLS origination.

1.  Let's use `istio-demo-auth.yaml` shipped with Istio releases.

    ```command
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    ```

1.  Start the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) sample
which will be used as a test source for external calls.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), do

    ```command
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    ```

    otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    ```

    Note that any pod that you can `exec` and `curl` from would do.

1.  Define a shell variable to hold the name of the source pod for sending requests to external services.
    If we used the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) sample, we run:

    ```command
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    ```

1.  Create an egress `Gateway` for _edition.cnn.com_,  a `ServiceEntry` for `edition.cnn.com` and a `VirtualService` to direct the traffic through the egress gateway, as described in the [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway/) task:

    ```bash
        cat <<EOF | istioctl create -f -
        kind: Gateway
        metadata:
          name: istio-egressgateway
        spec:
          selector:
            istio: egressgateway
          servers:
          - port:
              number: 443
              name: https-istio-mtls-for-tls-origination
              protocol: HTTP
            hosts:
            - "edition.cnn.com"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: ServiceEntry
        metadata:
          name: cnn
        spec:
          hosts:
          - edition.cnn.com
          ports:
          - number: 80
            name: http-port
            protocol: HTTP
          - number: 443
            name: http-port-for-tls-origination
            protocol: HTTP
          resolution: DNS
        ---
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
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: originate-tls-for-edition-cnn-com
        spec:
          host: edition.cnn.com
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: mutual-tls-for-egressgateway
        spec:
          host: istio-egressgateway.istio-system.svc.cluster.local
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: ISTIO_MUTUAL
        EOF
    ```

## Configure monitoring and access policies

Note that since want to accomplish our tasks in a _secure way_, we must direct egress traffic through _egress gateway_, as described in the [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway/) task. The _secure way_ here means that we want to prevent malicious applications from bypassing Istio monitoring and policy enforcement.

In our scenario, the organization performed the instructions in the [Before you begin](#before-you-begin) section. It enabled traffic to _edition.cnn.com_ and configured that traffic to pass through the egress gateway. Now it is ready to configure Istio for monitoring and access policies for the traffic to _edition.cnn.com_.

### Logging

1.  Let's configure Istio to log access to _*.cnn.com_. We create a `logentry` and two `stdio` handlers, one for logging forbidden access (_error_ log level) and another one for logging all access to _*.cnn.com_ (_info_ log level). Then we create `rules` to direct our `logentries` to our handlers. One rule directs access to _*.cnn.com/politics_ to the handler for logging forbidden access, another rule directs log entries to the handler that outputs each access to _*.cnn.com_ as an _info_ log entry.

    ```bash
        cat <<EOF | kubectl create -f -
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
          name: egress-error-handler
          namespace: istio-system
        spec:
         severity_levels:
           info: 2 # output log level as error
         outputAsJson: true
        ---
        # Rule to send egress access to cnn.com/politics to egress error handler
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: report-politics
          namespace: istio-system
        spec:
          match: request.host.endsWith("cnn.com") && request.path.startsWith("/politics")
          actions:
          - handler: egress-error-handler.stdio
            instances:
            - egress-access.logentry
        ---
        # Handler for info egress access entries
        apiVersion: "config.istio.io/v1alpha2"
        kind: stdio
        metadata:
          name: egress-access-handler
          namespace: istio-system
        spec:
          severity_levels:
            info: 0 # output log level as info
          outputAsJson: true
        ---
        # Rule to send egress access to cnn.com/politics to egress error handler
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: report-cnn-access
          namespace: istio-system
        spec:
          match: request.host.endsWith(".cnn.com")
          actions:
          - handler: egress-access-handler.stdio
            instances:
              - egress-access.logentry
        EOF
```

1.  Let's send three HTTP requests to _cnn.com_. All three should return _200 OK_.

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    ```

3.  Let's query the Mixer log and see that the information about the requests appear in the log:
    ```command
    $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep egress-access | grep cnn
    ```

    The output should be similar to the following:

    ```plain
    {"level":"info","time":"2018-06-18T13:22:58.317448Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":200,"responseSize":150448,"source":"sleep","user":"unknown"}
    {"level":"error","time":"2018-06-18T13:22:58.317448Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/politics","responseCode":200,"responseSize":150448,"source":"sleep","user":"unknown"}
    {"level":"info","time":"2018-06-18T13:22:59.234426Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/sport","responseCode":200,"responseSize":358651,"source":"sleep","user":"unknown"}
    {"level":"info","time":"2018-06-18T13:22:59.354943Z","instance":"egress-access.logentry.istio-system","destination":"edition.cnn.com","path":"/health","responseCode":200,"responseSize":332218,"source":"sleep","user":"unknown"}
    ```

    We see four log entries related to our three requests. Three _info_ entries about the access to _edition.cnn.com_ and one _error_ entry about the access to _edition.cnn.com/politics_. The service mesh operators can see all the accesses, and can also `grep` the log for _error_ log entries that reflect forbidden access. This is the first security measure the organization can apply before blocking the forbidden access automatically, namely logging all the forbidden access as errors. In some settings this can be a sufficient security measure.

### Access control by routing

### Access control by Mixer policy checks

### Dashboard

## Comparison with HTTPS egress traffic control

## Summary

## Cleanup

1.  Delete the artifacts related to egress traffic configuration:

    ```command
    $ istioctl delete gateway istio-egressgateway
    $ istioctl delete serviceentry cnn
    $ istioctl delete virtualservice direct-through-egress-gateway
    $ istioctl delete destinationrule originate-tls-for-edition-cnn-com
    $ istioctl delete destinationrule mutual-tls-for-egressgateway
    ```

1.  Delete the artifacts related to egress monitoring and access policies:

    ```command
    $ kubectl delete logentry egress-access -n istio-system
    $ kubectl delete stdio egress-error-handler -n istio-system
    $ kubectl delete stdio egress-access-handler -n istio-system
    $ kubectl delete rule report-politics -n istio-system
    $ kubectl delete rule report-cnn-access -n istio-system
    ```

1.  Shutdown the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) service:

    ```command
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    ```

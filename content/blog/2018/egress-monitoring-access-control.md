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

In this blog post we show how Istio monitoring and access policies are applied to egress traffic.

## Use case

Consider an organization that runs applications that process content of _cnn.com_. The applications are decomposed into microservices deployed in Istio service mesh. The applications access pages of various topics of _cnn.com_: [edition.cnn.com/politics](https://edition.cnn.com/politics), [edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health). The organization [configures Istio to allow access to edition.cnn.com](docs/tasks/traffic-management/egress-tls-origination/) and everything works fine. However, at some point in time the organization decides to banish politics. Practically, it means blocking access to [edition.cnn.com/politics](https://edition.cnn.com/politics) and allowing access to [edition.cnn.com/sport](https://edition.cnn.com/sport) and  [edition.cnn.com/health](https://edition.cnn.com/health) only.

To achieve that goal, the organization's operations people will monitor the access to the external services and will analyze the Istio logs to verify that no request to [edition.cnn.com/politics](https://edition.cnn.com/politics) was sent. They will also configure Istio to prevent access to [edition.cnn.com/politics](https://edition.cnn.com/politics) automatically.

The organization is resolved to prevent any tampering with the new policy. It decided to put mechanisms in place that will prevent any possibility for a malicious application to access the forbidden topic.

## Related tasks

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. The [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task demonstrates how to allow the applications to send HTTP requests to external servers that require HTTPS. The <TBD> Configure an Egress Gateway task describes how to configure Istio to direct egress traffic through a dedicated gateway service called _egress gateway_.

The [Collecting Metrics and Logs](/docs/tasks/telemetry/metrics-logs/) task describes how to configure metrics and logs for services in a mesh. The [Visualizing Metrics with Grafana](/docs/tasks/telemetry/using-istio-dashboard/) describes the Istio Dashboard to monitor mesh traffic. The [Basic Access Control](/docs/tasks/security/basic-access-control/) task shows how to control access to in-mesh services. As opposed to the telemetry and security tasks above, this blog post describes Istio's monitoring and access policies applied exclusively to the egress traffic.

## Before you begin

The instructions in this blog post are valid for Istio 0.8.0 or later. Follow the steps in the <TBD> TLS Origination with Egress gateway, without the <TBD> Cleanup step. After you accomplish this, you will be able to access [edition.cnn.com/politics](https://edition.cnn.com/politics) from an in-mesh container that has _curl_ installed. In the instructions of this blog post we assume that the `SOURCE_POD` environment variable contains the pod name.

## Configure monitoring and access policies

Note that since want to accomplish that in a _secure way_, we must direct egress traffic through _egress gateway_, as described in the <TBD> Configure an Egress Gateway task. The _secure way_ here means that we want to prevent malicious applications from bypassing Istio monitoring and policy enforcement.

In our scenario, the organization performed the instructions in the [Before you begin]() section. It enabled traffic to _edition.cnn.com_ and configured that traffic to pass through the egress gateway. Now it is ready to configure Istio for monitoring and access policies for the traffic to _edition.cnn.com_.

### Logging
1.  Let's define a new log entry to be applied to `istio-egressgateway` service:

    ```bash
        cat <<EOF | kubectl create -f -
        # Configuration for logentry instances
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
            user: source.user | "unknown"
            responseCode: response.code | 0
            responseSize: response.size | 0
          monitored_resource_type: '"UNSPECIFIED"'
        ---
        # Configuration for a stdio handler
        apiVersion: "config.istio.io/v1alpha2"
        kind: stdio
        metadata:
          name: egress-handler
          namespace: istio-system
        spec:
         severity_levels:
           info: 0 # Params.Level.INFO
           warning: 1 # Params.Level.WARNING
         outputAsJson: true
        ---
        # Rule to send logentry instances to an stdio handler
        apiVersion: "config.istio.io/v1alpha2"
        kind: rule
        metadata:
          name: egress-stdio
          namespace: istio-system
        spec:
          match: "true" # match for all requests
          actions:
           - handler: egress-handler.stdio
             instances:
             - egress-access.logentry
        EOF
```

1.  Let's send three HTTP requests to _cnn.com_. All three should return _200 OK_.

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/politics; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/sport; curl -sL -o /dev/null -w "%{http_code}\n" http://edition.cnn.com/health'
    ```

3.  Let's query the Mixer log and see that the requests appear:
    ```command
    $ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep egress-access | grep cnn
    ```
### Dashboard

### Access control by routing

### Access control by Mixer policy checks

## Comparison with HTTPS egress traffic control

## Summary

## Cleanup

1.  Perform the TBD cleanup section of the Configure an Egress Gateway task.

2. Clean the artifacts we created in this blog post:

    ```command
    $ kubectl delete logentry egress-access -n istio-system
    $ kubectl delete stdio egress-handler -n istio-system
    $ kubectl delete rule egress-stdio -n istio-system
    ```

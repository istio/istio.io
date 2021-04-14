---
title: LocalhostListener
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a workload is listening on a `localhost` network interface, but the port is exposed in the Service.
When this occurs, the port will not be accessible to other pods.

This check is primarily added to detect workloads on older Istio versions that may break when upgrading to Istio 1.10 or later.
This behavior matches what would occur in a standard Kubernetes cluster without Istio, but older versions of Istio exposed these ports.

{{< warning >}}
Because this check relies on privileged runtime checks, it is not included in the standard `istioctl analyze`.
Instead, it is included during installation and upgrade checks from `istioctl experimental precheck`.
{{< /warning >}}

## An example

Consider a `Service`, selecting a `Pod` running the command `nc localhost 8080 -l`:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: netcat
spec:
  ports:
  - port: 8080
    protocol: TCP
  selector:
    app: netcat
{{< /text >}}

Because the application is serving traffic on `localhost`, it is not accessible from other pods.

The above example shows using the simple `nc` tool. Some equivalent examples in other languages:

- Go: `net.Listen("tcp", "localhost:8080")`
- Node.js: `http.createServer().listen(8080, "localhost");`
- Python: `socket.socket().bind(("localhost", 8083))`

## How to resolve

If you did not intend to expose the application to other pods, you can remove the port from the `Service`.

If you do want to expose the application to other pods, there are two options:

- Modify the application to bind to a network interface exposed to other pods. Typically, this means binding to `0.0.0.0` or `::`, such as `nc 0.0.0.0 8080 -l`.
- Create a [`Sidecar` configuration](/docs/reference/config/networking/sidecar/#IstioIngressListener) to customize the inbound networking configuration for the pod.
  For example, with the above application:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: ratings
spec:
  workloadSelector:
    labels:
      app: netcat
  ingress:
  - port:
      number: 8080
      protocol: TCP
      name: tcp
    defaultEndpoint: 127.0.0.1:8080
{{< /text >}}

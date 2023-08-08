---
title: "Using Accelerated Offload Connection Load Balancing in Istio"
description: "Accelerate connection balancing using DLB connection balancing configuration in Istio gateways."
publishdate: 2023-08-08
attribution: "Loong Dai (Intel)"
keywords: [Istio, DLB, gateways]
---

## What is connection load balancing?

Load balancing is a core networking solution used to distribute traffic across multiple servers in a server farm.
Load balancers improve application availability and responsiveness and prevent server overload. Each load balancer
sits between client devices and backend servers, receiving and then distributing incoming requests to any available server capable of fulfilling them.

For a common web server, it usually has multiple workers (processors or threads). If many clients connect to
a single worker, this worker becomes busy and brings long tail latency while other workers run in the free state,
affecting the performance of the web server. Connection load balancing is the solution for this situation,
which is also known as connection balancing.

## What does Istio do for connection load balancing?

Istio uses Envoy as the data plane.

Envoy provides a connection load balancing implementation called Exact connection balancer. As its name says, a lock is held during balancing so that connection counts are nearly exactly balanced between workers. It is "nearly" exact in the sense that a connection might close in parallel thus making the counts incorrect, but this should be rectified on the next accept. This balancer sacrifices accept throughput for accuracy and should be used when there are a small number of connections that rarely cycle, e.g., service mesh gRPC egress.

Obviously, it is not suitable for an ingress gateway since an ingress gateway accepts thousands of connections within a short time, and the resource cost from the lock brings a big drop in throughput.

Now, Envoy has integrated Intel® Dynamic Load Balancing (Intel®DLB) connection load balancing to accelerate in high connection count cases like ingress gateway.

## How Intel® Dynamic Load Balancing accelerates connection load balancing in Envoy

Intel DLB is a hardware managed system of queues and arbiters connecting producers and consumers. It is a PCI device envisaged to live in the server CPU [uncore](https://en.wikipedia.org/wiki/Uncore) and can interact with software running on cores, and potentially with other devices.

Intel DLB implements the following load balancing features:

- Offloads queue management from software — useful where there are significant queuing-based costs.
    - Especially with multi-producer / multi-consumer scenarios and enqueue batching to multiple destinations.
    - The overhead locks are required to access shared queues in the software. Intel DLB implements lock-free access to shared queues.
- Dynamic, flow aware load balancing and reordering.
    - Ensures equal distribution of tasks and better CPU core utilization. Can provide flow-based atomicity if required.
    - Distributes high bandwidth flows across many cores without loss of packet order.
    - Better determinism and avoids excessive queuing latencies.
    - Uses less IO memory footprint and saves DDR Bandwidth.
- Priority queuing (up to 8 levels) — allows for QOS.
    - Lower latency for traffic that is latency sensitive.
    - Optional delay measurements in the packets.
- Scalability
    - Allows dynamic sizing of applications, seamless scale up/down.
    - Power aware; application can drop workers to lower power state in cases of lighter load.

There are three types of load balancing queues:

- Unordered: For multiple producers and consumers. The order of tasks is not important, and each task is assigned to the processor core with the lowest current load.
- Ordered: For multiple producers and consumers where the order of tasks is important. When multiple tasks are processed by multiple processor cores, they must be rearranged in the original order.
- Atomic: For multiple producers and consumers, where tasks are grouped according to certain rules. These tasks are processed using the same set of resources and the order of tasks within the same group is important.

An ingress gateway is expected to process as much data as possible as quickly as possible, so Intel DLB connection load balancing uses an unordered queue.

## How to use Intel DLB connection load balancing in Istio

With the 1.17 release, Istio officially supports Intel DLB connection load balancing.

The following steps show how to use Intel DLB connection load balancing in an Istio [Ingress Gateway](/docs/tasks/traffic-management/ingress/ingress-control/) in an SPR (Sapphire Rapids) machine, assuming the Kubernetes cluster is running.

### Step 1: Prepare DLB environment

Install the Intel DLB driver by following [the instructions on the Intel DLB driver official site](https://www.intel.com/content/www/us/en/download/686372/intel-dynamic-load-balancer.html).

Install the Intel DLB device plugin with the following command:

{{< text bash >}}
$ kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/dlb_plugin?ref=v0.26.0
{{< /text >}}

For more details about the Intel DLB device plugin, please refer to [Intel DLB device plugin homepage](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/dlb#config-connection-balance-dlb).

You can check the Intel DLB device resource:

{{< text bash >}}
$ kubectl describe nodes | grep dlb.intel.com/pf
  dlb.intel.com/pf:   2
  dlb.intel.com/pf:   2
...
{{< /text >}}

### Step 2: Download Istio

In this blog we use 1.17.2. Let’s download the installation:

{{< text bash >}}
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.17.2 TARGET_ARCH=x86_64 sh -
$ cd istio-1.17.2
$ export PATH=$PWD/bin:$PATH
{{< /text >}}

{{< tip >}}
All following actions will be done under this directory.
{{< /tip >}}

You can check the version is 1.17.2:

{{< text bash >}}
$ istioctl version
no running Istio pods in "istio-system"
1.17.2
{{< /text >}}

### Step 3: Install Istio

Create an install configuration for Istio, notice that we assign 4 CPUs and 1 DLB device to ingress gateway and set concurrency as 4, which is equal to the CPU number.

{{< text bash >}}
$ cat > config.yaml << EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: default
  components:
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
      k8s:
        overlays:
          - kind: Deployment
            name: istio-ingressgateway
        podAnnotations:
          proxy.istio.io/config: |
            concurrency: 4
        resources:
          requests:
            cpu: 4000m
            memory: 4096Mi
            dlb.intel.com/pf: '1'
          limits:
            cpu: 4000m
            memory: 4096Mi
            dlb.intel.com/pf: '1'
        hpaSpec:
          maxReplicas: 1
          minReplicas: 1
  values:
    telemetry:
      enabled: false
EOF
{{< /text >}}

Use `istioctl` to install:

{{< text bash >}}
$ istioctl install -f config.yaml --set values.gateways.istio-ingressgateway.runAsRoot=true -y
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete                                                                                                                                                                                                                                                                       Making this installation the default for injection and validation.

Thank you for installing Istio 1.17.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/hMHGiwZHPU7UQRWe9
{{< /text >}}

### Step 4: Setup Backend Service

Since we want to use DLB connection load balancing in Istio ingress gateway, we need to create a backend service first.

We'll use an Istio-provided sample to test, [httpbin]({{< github_tree >}}/release-1.17/samples/httpbin).

{{< text bash >}}
$ kubectl apply -f samples/httpbin/httpbin.yaml
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # The selector matches the ingress gateway pod labels.
  # If you installed Istio using Helm following the standard documentation, this would be "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

You have now created a virtual service configuration for the httpbin service containing two route rules that allow traffic for paths /status and /delay.

The gateways list specifies that only requests through your httpbin-gateway are allowed. All other external requests will be rejected with a 404 response.

### Step 5: Enable DLB Connection Load Balancing

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: dlb
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: LISTENER
    match:
      context: GATEWAY
    patch:
      operation: MERGE
      value:
        connection_balance_config:
            extend_balance:
              name: envoy.network.connection_balance.dlb
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.network.connection_balance.dlb.v3alpha.Dlb
EOF
{{< /text >}}

It is expected that if you check the log of ingress gateway pod `istio-ingressgateway-xxxx` you will see log entries similar to:

{{< text bash >}}
$ export POD="$(kubectl get pods -n istio-system | grep gateway | awk '{print $1}')"
$ kubectl logs -n istio-system ${POD} | grep dlb
2023-05-05T06:16:36.921299Z     warning envoy config external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:46        dlb device 0 is not found, use dlb device 3 instead     thread=35
{{< /text >}}

Envoy will auto detect and choose the DLB device.

### Step 6: Test

{{< text bash >}}
$ export HOST="<YOUR-HOST-IP>"
$ export PORT="$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')"
$ curl -s -I -HHost:httpbin.example.com "http://${HOST}:${PORT}/status/200"
HTTP/1.1 200 OK
server: istio-envoy
...
{{< /text >}}

Note that you use the `-H` flag to set the Host HTTP header to `httpbin.example.com` since now you have no DNS binding for that host and are simply sending your request to the ingress IP.

You can also add the DNS binding in `/etc/hosts` and remove `-H` flag:

{{< text bash >}}
$ echo "$HOST httpbin.example.com" >> /etc/hosts
$ curl -s -I "http://httpbin.example.com:${PORT}/status/200"
HTTP/1.1 200 OK
server: istio-envoy
...
{{< /text >}}

Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

{{< text bash >}}
$ curl -s -I -HHost:httpbin.example.com "http://${HOST}:${PORT}/headers"
HTTP/1.1 404 Not Found
...
{{< /text >}}

You can turn on debug log level to see more DLB related logs:

{{< text bash >}}
$ istioctl pc log ${POD}.istio-system --level debug
istio-ingressgateway-665fdfbf95-2j8px.istio-system:
active loggers:
  admin: debug
  alternate_protocols_cache: debug
  aws: debug
  assert: debug
  backtrace: debug
...
{{< /text >}}

Run `curl` to send one request and you will see something like below:

{{< text bash >}}
$ kubectl logs -n istio-system ${POD} | grep dlb
2023-05-05T06:16:36.921299Z     warning envoy config external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:46        dlb device 0 is not found, use dlb device 3 instead     thread=35
2023-05-05T06:37:45.974241Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:269   worker_3 dlb send fd 45 thread=47
2023-05-05T06:37:45.974427Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:286   worker_0 get dlb event 1        thread=46
2023-05-05T06:37:45.974453Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:303   worker_0 dlb recv 45    thread=46
2023-05-05T06:37:45.975215Z     debug   envoy connection external/envoy/contrib/network/connection_balance/dlb/source/connection_balancer_impl.cc:283   worker_0 dlb receive none, skip thread=46
{{< /text >}}

For more details about Istio Ingress Gateway, please refer to [Istio Ingress Gateway Official Doc](/docs/tasks/traffic-management/ingress/ingress-control/).

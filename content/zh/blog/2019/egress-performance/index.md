---
title: Egress Gateway Performance Investigation
description: Verifies the performance impact of adding an egress gateway.
publishdate: 2019-01-31
subtitle: An Istio Egress Gateway performance assessment
attribution: Jose Nativio, IBM
keywords: [performance,traffic-management,egress,mongo]
target_release: 1.0
---

The main objective of this investigation was to determine the impact on performance and resource utilization when an egress gateway is added in the service mesh to access an external service (MongoDB, in this case). The steps to configure an egress gateway for an external MongoDB are described in the blog [Consuming External MongoDB Services](/zh/blog/2018/egress-mongo/).

The application used for this investigation was the Java version of Acmeair, which simulates an airline reservation system. This application is used in the Performance Regression Patrol of Istio daily builds, but on that setup the microservices have been accessing the external MongoDB directly via their sidecars, without an egress gateway.

The diagram below illustrates how regression patrol currently runs with Acmeair and Istio:

{{< image width="70%"
    link="./acmeair_regpatrol3.png"
    caption="Acmeair benchmark in the Istio performance regression patrol environment"
    >}}

Another difference is that the application communicates with the external DB with plain MongoDB protocol. The first change made for this study was to establish a TLS communication between the MongoDB and its clients running within the application, as this is a more realistic scenario.

Several cases for accessing the external database from the mesh were tested and described next.

## Egress traffic cases

### Case 1:  Bypassing the sidecar

In this case, the sidecar does not intercept the communication between the application and the external DB. This is accomplished by setting the init container argument -x with the CIDR of the MongoDB, which makes the sidecar ignore messages to/from this IP address. For example:

        - -x
        - "169.47.232.211/32"

{{< image width="70%"
    link="./case1_sidecar_bypass3.png"
    caption="Traffic to external MongoDB by-passing the sidecar"
    >}}

### Case 2: Through the sidecar, with service entry

This is the default configuration when the sidecar is injected into the application pod. All messages are intercepted by the sidecar and routed to the destination according to the configured rules, including the communication with external services. The MongoDB was defined as a `ServiceEntry`.

{{< image width="70%"
    link="./case2_sidecar_passthru3.png"
    caption="Sidecar intercepting traffic to external MongoDB"
    >}}

### Case 3: Egress gateway

The egress gateway and corresponding destination rule and virtual service resources are defined for accessing MongoDB. All traffic to and from the external DB goes through the egress gateway (envoy).

{{< image width="70%"
    link="./case3_egressgw3.png"
    caption="Introduction of the egress gateway to access MongoDB"
    >}}

### Case 4: Mutual TLS between sidecars and the egress gateway

In this case, there is an extra layer of security between the sidecars and the gateway, so some impact in performance is expected.

{{< image width="70%"
    link="./case4_egressgw_mtls3.png"
    caption="Enabling mutual TLS between sidecars and the egress gateway"
    >}}

### Case 5: Egress gateway with SNI proxy

This scenario is used to evaluate the case where another proxy is required to access wildcarded domains. This may be required due current limitations of envoy. An nginx proxy was created as sidecar in the egress gateway pod.

{{< image width="70%"
    link="./case5_egressgw_sni_proxy3.png"
    caption="Egress gateway with additional SNI Proxy"
    >}}

## Environment

* Istio version: 1.0.2
* `K8s` version: `1.10.5_1517`
* Acmeair App: 4 services (1 replica of each), inter-services transactions, external Mongo DB, avg payload: 620 bytes.

## Results

`Jmeter` was used to generate the workload which consisted in a sequence of 5-minute runs, each one using a growing number of clients making http requests. The number of clients used were 1, 5, 10, 20, 30, 40, 50 and 60.

### Throughput

The chart below shows the throughput obtained for the different cases:

{{< image width="75%"
    link="./throughput3.png"
    caption="Throughput obtained for the different cases"
    >}}

As you can see, there is no major impact in having sidecars and the egress gateway between the application and the external MongoDB, but enabling mutual TLS and then adding the SNI proxy caused a degradation in the throughput of about 10% and 24%, respectively.

### Response time

The average response times for the different requests were collected when traffic was being driven with 20 clients. The chart below shows the average, median, 90%, 95% and 99% average values for each case:

{{< image width="75%"
    link="./response_times3.png"
    caption="Response times obtained for the different configurations"
    >}}

Likewise, not much difference in the response times for the 3 first cases, but mutual TLS and the extra proxy adds noticeable latency.

### CPU utilization

The CPU usage was collected for all Istio components as well as for the sidecars during the runs. For a fair comparison, CPU used by Istio was normalized by the throughput obtained for a given run. The results are shown in the following graph:

{{< image width="75%"
    link="./cpu_usage3.png"
    caption="CPU usage normalized by TPS"
    >}}

In terms of CPU consumption per transaction, Istio has used significantly more CPU only in the egress gateway + SNI proxy case.

## Conclusion

In this investigation, we tried different options to access an external TLS-enabled MongoDB to compare their performance. The introduction of the Egress Gateway did not have a significant impact on the performance nor meaningful additional CPU consumption. Only when enabling mutual TLS between sidecars and egress gateway or using an additional SNI proxy for wildcarded domains we could observe some degradation.


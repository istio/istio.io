---
title: Istio Metrics
overview: Metrics exported from Istio through Mixer.
weight: 50
---

Istio exports metrics through Mixer. They can be found [here](https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)
under the section with “kind: metric”. 

We will describe metrics first and then the labels for each metric.

## Metrics

### Request Count 
This is a COUNTER metric incremented for a new request to Istio. 
It is labeled based on source service, source version, destination service, destination version, connection mtls and response code of the request. 
This is exported by default by prometheus adapter and can be configured to be exported by other mixer adapters.

### RequestDuration
This is a DISTRIBUTION metric which measures the duration of the request. 
This metric is obtained from envoy proxy. It is labeled based on source service, source version, destination service, destination version, connection mtls and response code of the request. This is exported by default by prometheus adapter using explicit bucket configuration of [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]. 
It can be configured to be exported by other mixer adapters.

### Request Size
This is a DISTRIBUTION metric which measures the size of the http request’s body size. 
This metric is obtained from envoy proxy. It is labeled based on source service, source version, destination service, destination version, connection mtls and response code of the request. This is exported by default by prometheus adapter using exponential buckets with configuration of number of finite buckets is equal to 8, scale of 1 and growth factor of 10. 
It can be configured to be exported by other mixer adapters.

### Response Size
This is a DISTRIBUTION metric which measures the size of the http response body size. 
This metric is obtained from envoy proxy. It is labeled based on source service, source version, destination service, destination version, connection mtls and response code of the request. This is exported by default by prometheus adapter using exponential buckets with configuration of number of finite buckets is equal to 8, scale of 1 and growth factor of 10. 
It can be configured to be exported by other mixer adapters.

### Tcp Byte Sent
This is a COUNTER metric which measures the size of total bytes sent during response in case of a TCP connection. 
This metric is obtained from envoy proxy. It is labeled based on source service, source version, destination service, destination version and connection mtls of the request. 
This is exported by default by prometheus adapter and can be exported by other mixer adapters.

### Tcp Byte Received
This is a COUNTER metric which measures the size of total bytes received during request in case of a TCP connection. 
This metric is obtained from envoy proxy. It is labeled based on source service, source version, destination service, destination version and connection mtls of the request. 
This is exported by default by prometheus adapter and can be exported by other mixer adapters.

## Labels

### Source Service
This identifies the source service responsible for an incoming request. 
This label is obtained from kubernetes cluster metadata. This is also the FQDN for a source service. 
Ex: "reviews.default.svc.cluster.local".

### Source Version
This identifies the version of the source service of the request. 
This label is obtained from kubernetes cluster metadata source.labels[“version”].

### Destination Service
This identifies the destination service responsible for an incoming request. 
This label is obtained from kubernetes cluster metadata. 
This is also the FQDN for a source service. Ex: "details.default.svc.cluster.local".

### Destination Version
This identifies the version of the source service of the request. 
This label is obtained from kubernetes cluster metadata destination.labels[“version”]. 

### Response Code
This identifies the response code of the request. 
This label is obtained from envoy proxy and it’s default value is 200(Success).  

### Connection MTLS
This identifies the service authentication policy of the request. This is a boolean label obtained from envoy proxy and it’s default value is false. 
It is set to true, when istio is used to make secure communications.

## Example

Request Count metric would look as follows:
```
istio_request_count
{
connection_mtls="false",
destination_service="istio-pilot.istio-system.svc.cluster.local",
destination_version="unknown",
instance="10.40.0.6:42422",
job="istio-mesh",
response_code="200",
source_service="details.default.svc.cluster.local",
source_version="v1"
}
Value: 2
```

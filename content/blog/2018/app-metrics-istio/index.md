---
title: Application Metrics in Istio
description: How to send application metrics to Prometheus instance in Istio.
publishdate: 2018-12-19
subtitle:
attribution: Mete Atamel
twitter: meteatamel
weight: 78
keywords: [metrics, prometheus, mixer, envoy, sidecar, traffic management]
---
## Background

The default metrics sent by Istio are useful to get an idea on how the traffic flows in your cluster. However, to understand how your application behaves, you also need application metrics. 

[Prometheus](https://prometheus.io/) has [client libraries](https://prometheus.io/docs/instrumenting/clientlibs/) that you can use to instrument your application and send those metrics. This is good but it raises some questions: 
* Where do you collect those metrics? 
* Do you use Istio’s Prometheus or set up your own Prometheus? 
* If you use Istio’s Prometheus, what configuration do you need to get those metrics scraped? 

Let’s try to answer these questions.

## Istio vs. standalone Prometheus
In Prometheus, there’s a [federation](https://prometheus.io/docs/prometheus/latest/federation/) feature that allows a Prometheus server to scrape metrics from another Prometheus server. If you want to keep Istio metrics and application metrics separate, you can set up a seperate Prometheus server for application metrics. Then, you can use federation to scrape  those application metrics scraped with Istio’s Prometheus server. 

A simpler approach is to scrape the application’s metrics  using Istio’s Prometheus directly and that’s what I want to focus on here. 

## Sending application metrics
To send custom metrics from your application, you need to instrument your application using Prometheus’ [client libraries](https://prometheus.io/docs/instrumenting/clientlibs/). Which  library to use depends on the language you’re using. As a C#/.NET developer, I used the  [.NET client](https://github.com/prometheus-net/prometheus-net) for Prometheus and [this blog post](https://www.olivercoding.com/2018-07-22-prometheus-dotnetcore/) from Daniel Oliver has step-by-step instructions on how to send custom metrics from an ASP.NET Core application and see them in a local Prometheus server.

One thing you need to pay attention to is the port where you’re exposing your Prometheus metrics. In ASP.NET Core, the default port is **5000**. When running locally, application metrics are exposed on `localhost:5000/metrics`. However, when you containerize your app, it’s common to expose your application over a different port, like **8080**, and this becomes relevant later when we talk about configuration.

Assuming that you containerized and deployed your application on an Istio-enabled Kubernetes cluster, let’s now take a look at what we need to do to get these application metrics scraped by Istio’s Prometheus.

## Configuration
In Istio 1.0.5, the default installation files for Kubernetes, `istio-demo.yaml` or `istio-demo-auth.yaml`, already have scraping configurations for Prometheus under a `ConfigMap`. You can just search for `prometheus.yml`. There are 2 scraping jobs that are relevant for application metrics: 

{{< text yaml >}}
- job_name: 'kubernetes-pods'
   kubernetes_sd_configs:
   - role: pod
...
- job_name: 'kubernetes-pods-istio-secure'
   scheme: https

{{< /text >}}

These are the jobs that scrape metrics from regular pods and pods where mTLS is enabled. It looks like Istio’s Prometheus should automatically scrape application metrics. However, in my first try, it didn’t work. I wasn’t sure what was wrong but Prometheus has some default endpoints:

* `/config`: to see the current configuration of Prometheus.
* `/metrics`: to see the scraped metrics.
* `/targets`: to see the targets that’s being scraped and their status. 

All of these endpoints are useful for debugging Prometheus:

{{< image width="60%" ratio="43%" link="./image1.png" caption="Prometheus Targets page" >}}

Turns out, I needed to add some annotations in my pod YAML files in order to get Prometheus scrape the pod. I had to tell Prometheus to scrape the pod and on which port with these annotations:

{{< text yaml >}}
template:
   metadata:
      annotations:
         prometheus.io/scrape: "true"
         prometheus.io/port: "8080"
{{< /text >}}

After adding the annotations, I was able to see my application’s metrics in Prometheus: 

{{< image width="60%" ratio="43%" link="./image2.png" caption="Prometheus page with application metrics" >}}

However, it was only working for regular pods and I was not able to see metrics with mTLS enabled between pods.

## Bug with Istio Prometheus
After some investigation, I contacted the Istio team and turns out, there’s a [bug](https://github.com/istio/istio/issues/10528). When the Istio Prometheus server starts, it cannot talk to the mTLS enabled pods since certificates are not ready yet. And it never retries to load after initialization and that prevents the metrics from being scraped. 

It’s not ideal but there’s an easy workaround: restart the Prometheus pod. Restart forces Prometheus to pick up certificates and the application’s metrics start flowing for mTLS enabled pods as well.

## Conclusion
Getting application metrics scraped by Istio’s Prometheus is pretty straightforward once you understand the basics. Hopefully, this post provided you the background info and configuration you need to achieve that. 

It’s worth noting that [Mixer](https://istio.io/docs/concepts/what-is-istio/#mixer) is being redesigned and, in future versions of Istio, it will be directly embedded in Envoy. In that design, you’ll be able to send application metrics through Mixer and it’ll flow through the same overall metrics pipeline of the sidecar. This should make it simpler to get application metrics working end to end.

Thanks to the Istio team and my coworker [Sandeep Dinesh](https://twitter.com/sandeepdinesh) for helping me to debug through issues, as I got things working.  

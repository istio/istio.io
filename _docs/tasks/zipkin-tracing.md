---
title: Collecting Zipkin Trace Spans
overview: How to configure the proxies to send tracing spans to Zipkin

order: 120

layout: docs
type: markdown
---
{% include home.html %}

This task shows you how to use [pre-merge builds](https://github.com/lyft/envoy/pull/905) (ie, not in the master yet, and not released) of [Istio proxy](https://github.com/lyft/envoy/pull/905) to collect trace spans using [Zipkin](http://zipkin.io). The intent is for this functionality to eventually be in official releases and not have to "hack" this into our deployments. After completing this task, you should have a working example of application proxies sending span information to a sample Zipkin service.


The [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application is used as the example application throughout this task.

## Before you begin

To use the Zipkin implementation, we'll need to do the following pre-work:

* Install the Zipkin service
* Configure the core Istio components to use un-released builds that contain pre-merge PR work for Zipkin 

Again, the fact that we're using pre-released builds is just temporary; we'll update this task when the appropriate implementations have been released.


These steps are intended to be run when you install Istio's components. Please see the [task for installing Istio]({{home}}/docs/tasks/installing-istio.html)

#### Install the Zipkin service

First, let's install the Zipkin service so that our components/proxies can send span data to it. 

1. If you're not already in this directory, change directories to `install/kubernetes`

    ```bash
    cd install/kubernetes
    ```
    
2. Apply the zipkin yaml resource files

    ```bash
    kubectl apply -f addons/zipkin.yaml
    ```
    
You can contine to install the `addons` as instructed in the [task for installing Istio]({{home}}/docs/tasks/installing-istio.html)

#### Configure Istio installation for Zipkin

In Step 4 of [Installing Istio]({{home}}/docs/tasks/installing-istio.html), we try to apply the `istio.yaml` file which contains the core components of Istio.

Note: When we install the components for using Zipkin, we will not treat the RBAC scenarios; these steps work when RBAC is NOT enabled for your Kubernetes cluster.

Instead of `kubectl apply -f istio.yaml`, we're going to use a version of Istio configured to use Zipkin and use components that have been built with Zipkin support. You can either edit the `istio.yaml` file directly, apply [this patch](https://gist.github.com/christian-posta/d6192ada85ed65a8a99047e38f2779e0) or just use this command which uses the patched `istio.yaml` file directly:

```bash
curl -sL https://gist.github.com/christian-posta/6674463d77e4ee11c5a8067380960b60/raw | kubectl apply -f -
```

After running these steps, your Istio components should be Zipkin-aware and you should be able to open the Zipkin console. The easiest way to get access to the Zipkin console is by first port-forwarding the Zipkin pod's http port to your machine and viewing it on localhost:

```bash
kubectl port-forward $(kubectl get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}') 9411:9411
```

Then open your browser at [http://localhost:9411](http://localhost:9411)



## Setting up the Bookinfo sample

Now that the Istio components are Zipkin aware, we need to [install the Bookinfo sample]({{home}}/docs/samples/bookinfo.html) with Istio proxies that have a Zipkin implementation. Pleaes review the [installation steps for Bookinfo]({{home}}/docs/samples/bookinfo.html). 

For step 3 in the instructions, where we try to `kube-inject` the `bookinfo.yaml` resource, we're going to alter that slightly to inject proxies that are Zipkin aware. Instead of:

```bash
kubectl apply -f <(istioctl kube-inject -f bookinfo.yaml)
```

We're going to run this command:

```bash
kubectl apply -f <(istioctl kube-inject --hub docker.io/ijsnellf --tag zipkin -f bookinfo.yaml) | sed s/proxy_debug/proxy/g)
```

That command switches out the repo that we use to find the proxy, switches to the zipkin tag, and the massages out the proxy_debug references because there are no proxy_debug:zipkin images. 

At this point, you should have the components for the Bookinfo demo installed and injected with proxies capable of sending Zipkin spans. Feel free to continue on with the demo, invoking the productpage website, and observe the span information in the Zipkin console. You should see something similar to this output:

![Zipkin Istio Dashboard](./img/zipkin_dashboard.png)

If you click into a trace you should see the following:

![Zipkin Istio Dashboard](./img/zipkin_span.png)

Do note that the service names are not populated correctly... yet.

## What's next

* Learn more about [Metrics and Logs]({{home}}/docs/tasks/metrics-logs.html)

* Learn more about [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Mixer Config]({{home}}/docs/concepts/policy-and-control/mixer-config.html).

* Discover the full [Attribute Vocabulary]({{home}}/docs/reference/config/mixer/attribute-vocabulary.html).

* Read the reference guide to [Writing Config]({{home}}/docs/reference/writing-config.html).

---
title: Getting Started
headline: Getting Started with Istio
sidenav: doc-side-tasks-nav.html
bodyclass: docs
layout: docs
type: markdown
---
{% capture overview %}
This page shows how to get started using Istio in a Kubernetes cluster. You'll learn
how to install Istio and get it initially configured and running.
{% endcapture %}

{% capture prerequisites %}
* The following instructions assume that you have access to a kubernetes cluster. To install kubernetes locally, checkout [minikube](https://github.com/kubernetes/minikube)_.
{% endcapture %}

{% capture steps %}
## Install Istio on an existing Kubernetes cluster


1. Clone the istio GitHub repository

```bash
git clone https://github.com/istio/istio
```
2. Change directory to the root of the istio repository
```bash
cd istio
```

3. Install the Istio core components (Istio-Manager, Mixer, and Ingress Controller).

```bash
kubectl apply -f ./kubernetes/istio-install
```

4. Install the [istioctl](../reference/istioctl.md) CLI, which is needed to inject Envoy in the pod running the application. The tool provides also a
   convenient way to apply routing rules and policies for upstreams. The
   [istio.VERSION](https://github.com/istio/istio/blob/master/istio.VERSION) file includes the download location of
   three OS-specific binaries: `istioctl-osx`, `istioctl-win.exe`,
   `istioctl-linux` targeted at Mac, Windows and Linux users
   respectively. Download the tool appropriate to your platform. For
   example, when running istioctl on a Mac, run the following commands:

```bash
source ./istio.VERSION # set ISTIOCTL env variable
curl ${ISTIOCTL_URL}/istioctl-osx > /usr/local/bin/istioctl
chmod +x /usr/local/bin/istioctl
```

5. Deploy your application, or one of the samples applications, for instance [bookinfo](../samples/bookinfo.md).
The kube-inject tool will automatically add a container running Envoy in the same pod as the application.
```bash
kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

6. Optional step: to view metrics collected by the Mixer, install the Prometheus and Grafana addons.

```bash
kubectl apply -f ./kubernetes/addons/
```

The Grafana image provided as part of this sample contains a built-in Istio-dashboard that you can access from:

```
http://<grafana-svc-external-IP>:3000/dashboard/db/istio-dashboard
```

   > The addons yaml files contain services configured as type LoadBalancer. If services are deployed with type NodePort,
   > start kubectl proxy, and edit Grafana's Istio-dashboard to use the proxy. Access Grafana via kubectl proxy:*

```
http://127.0.0.1:8001/api/v1/proxy/namespaces/default/services/grafana:3000/dashboard/db/istio-dashboard
```


{% endcapture %}

{% capture discussion %}
## Verifying the installation

1. Verify following Kubernetes services were deployed: "istio-manager", "istio-mixer", "istio-ingress-controller".
```bash
$ kubectl get svc
NAME                       CLUSTER-IP     EXTERNAL-IP     PORT(S)              AGE
istio-ingress-controller   10.83.241.84   35.184.70.168   80:30583/TCP         39m
istio-manager              10.83.251.26   <none>          8080/TCP             39m
istio-mixer                10.83.242.1    <none>          9091/TCP,42422/TCP   39m
```

2. Verify corresponding Kubernetes pods were deployed: "istio-manager-\*", "istio-mixer-\*", "istio-ingress-controller-\*".
```bash
$ kubectl get pods
NAME                                       READY     STATUS    RESTARTS   AGE
istio-ingress-controller-594763772-j7jbz   1/1       Running   0          49m
istio-manager-373576132-p2t9k              1/1       Running   0          49m
istio-mixer-1154414227-56q3z               1/1       Running   0          49m
```

{% endcapture %}

{% capture whatsnext %}
* Learn more about [this](...).
* See this [related task](...).
{% endcapture %}

{% include templates/task.md %}

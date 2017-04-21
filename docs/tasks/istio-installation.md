---
title: Installing Istio
headline: Installing Istio
sidenav: doc-side-tasks-nav.html
bodyclass: docs
layout: docs
type: markdown
---
{% capture overview %}
This page shows how to install and configure Istio in a Kubernetes cluster.
{% endcapture %}

{% capture prerequisites %}
* The following instructions assume you have access to a Kubernetes cluster. To install Kubernetes locally, try [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/).
* If you are using [Google Container Engine](https://cloud.google.com/container-engine), please make sure you are using static client certificates before fetching cluster credentials:
```bash
gcloud config set container/use_client_certificate True
gcloud container clusters get-credentials cluster-2 --zone us-central1-a --project istio-demo
```
* Ensure the curl command is present, or clone the github [istio](https://github.com/istio/istio) repository to access the files locally.
{% endcapture %}

{% capture steps %}
## Installing on an existing cluster
For the Alpha release, Istio must be installed in the same Kubernetes namespace as the applications. Instructions below will deploy Istio in the "default" namespace. They can be modified for deployment in a separate namespace.

1. Source the Istio configuration file:
```bash
source <(curl https://raw.githubusercontent.com/istio/istio/change_install/istio.VERSION)
```
2. Install the Istio core components (Istio-Manager, Mixer, and Ingress-Controller):
```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/kubernetes/istio.yaml
```
3. Download one of the [`istioctl`]({{site.bareurl}}/docs/reference/istioctl.html) client binaries corresponding to your OS: `istioctl-osx`, `istioctl-win.exe`,
`istioctl-linux`, targeted at Mac, Windows or Linux users respectively. For example, run the following commands on a Mac system:
```bash
curl ${ISTIOCTL_URL}/istioctl-osx > /usr/local/bin/istioctl
chmod +x /usr/local/bin/istioctl
```
Istioctl is needed to inject Envoy as a sidecar proxy. It also provides a convenient CLI for creating routing rules and policies.
4. Deploy your application:
```bash
kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```
The [kube-inject]({{site.bareurl}}/docs/reference/istioctl.html##kube-inject) tool will automatically inject an Envoy container in the pod running the application.
Alternatively, deploy one of the samples applications, for instance [bookinfo]({{site.bareurl}}/docs/samples/bookinfo.html).

5. Optionally: to view metrics collected by Mixer, install [Prometheus](https://prometheus.io), [Grafana](http://staging.grafana.org) and ServiceGraph addons:
```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/kubernetes/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/kubernetes/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/kubernetes/addons/servicegraph.yaml
```
The Grafana image provided as part of this sample contains a built-in Istio dashboard that you can access from:
```bash
http://<grafana-svc-external-IP>:3000/dashboard/db/istio-dashboard
```
The addons yaml files contain services configured as type LoadBalancer. If services are deployed with type NodePort,
start kubectl proxy, and edit Grafana's Istio-dashboard to use the proxy. Access Grafana via kubectl proxy:
```bash
http://127.0.0.1:8001/api/v1/proxy/namespaces/default/services/grafana:3000/dashboard/db/istio-dashboard
```
{% endcapture %}

{% capture discussion %}
## Verify the installation

1. Ensure the following Kubernetes services were deployed: "istio-manager", "istio-mixer", and "istio-ingress-controller".
```bash
kubectl get svc
NAME                       CLUSTER-IP     EXTERNAL-IP     PORT(S)              AGE
istio-ingress-controller   10.83.241.84   35.184.70.168   80:30583/TCP         39m
istio-manager              10.83.251.26   <none>          8080/TCP             39m
istio-mixer                10.83.242.1    <none>          9091/TCP,42422/TCP   39m
```
2. Check the corresponding Kubernetes pods were deployed: "istio-manager-\*", "istio-mixer-\*", "istio-ingress-controller-\*".
```bash
kubectl get pods
NAME                                       READY     STATUS    RESTARTS   AGE
istio-ingress-controller-594763772-j7jbz   1/1       Running   0          49m
istio-manager-373576132-p2t9k              1/1       Running   0          49m
istio-mixer-1154414227-56q3z               1/1       Running   0          49m
```

## Uninstall
1. Uninstall Istio:
```bash
kubectl delete -f https://raw.githubusercontent.com/istio/istio/master/kubernetes/istio.yaml
```
2. Delete the istioctl client:
```bash
rm /usr/local/bin/istioctl
```

{% endcapture %}

{% capture whatsnext %}
* Learn more about how to enable [authentication]({{site.bareurl}}/docs/tasks/istio-auth.html).
* See the sample [bookinfo]({{site.bareurl}}/docs/samples/bookinfo.html) application.
{% endcapture %}

{% include templates/task.md %}

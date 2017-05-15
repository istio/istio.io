---
title: Installing Istio
overview: This task shows you how to setup the Istio service mesh.

order: 10

layout: docs
type: markdown
---
{% include home.html %}

This page shows how to install and configure Istio in a Kubernetes cluster.

## Prerequisites

* The following instructions assume you have access to a Kubernetes cluster. To install Kubernetes locally, try [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/).

* If you are using [Google Container Engine](https://cloud.google.com/container-engine), please make sure you are using static client certificates before fetching cluster credentials:

  ```bash
  gcloud config set container/use_client_certificate True
  ```
  Find out your cluster name and zone, and fetch credentials:
  ```bash
  gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-name>
  ```

* Install the Kubernetes client [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), or upgrade to the latest version supported by your cluster.

* If you previously installed Istio on this cluster, please uninstall first by following the [uninstalling]({{home}}/docs/tasks/installing-istio.html#uninstalling) steps at the end of this page.

## Installation steps

For the {{ site.data.istio.version }} release, Istio must be installed in the same Kubernetes namespace as the applications. Instructions below will deploy Istio in the
default namespace. They can be modified for deployment in a different namespace.

1. Go to the [Istio release](https://github.com/istio/istio/releases) page, to download the installation file corresponding to your OS or run 
   ```bash
   curl -L https://git.io/getIstio | sh -
   ``` 
   to download and extract the latest release automatically (on MacOS and Ubuntu).

1. Extract the installation file, and change directory to the location where the files were extracted. Following instructions are relative to this installation directory.
   The installation directory contains:
    * yaml installation files for Kubernetes
    * sample apps
    * the `istioctl` client binary, needed to inject Envoy as a sidecar proxy, and useful for creating routing rules and policies.
    * the istio.VERSION configuration file.

1. Add the `istioctl` client to your PATH. For example, run the following commands on a Mac system:

   ```bash
   sudo ln -s $PWD/istioctl /usr/local/bin/
   ```

1. Run the following command to determine if your cluster has [RBAC (Role-Based Access Control)](https://kubernetes.io/docs/admin/authorization/rbac/)
enabled:

   ```bash
   kubectl api-versions | grep rbac
   ```
   * If the command displays an error, or does not display anything, it means the cluster does not support RBAC, and you can proceed to step 5 below.
   
   * If the command displays 'beta' version, or both 'alpha' and 'beta', please apply istio-rbac-beta.yaml configuration:
   ```bash
   kubectl apply -f install/kubernetes/istio-rbac-beta.yaml
   ```
   
   * If the command displays only 'alpha' version, please apply istio-rbac-alpha.yaml configuration:
   ```bash
   kubectl apply -f install/kubernetes/istio-rbac-alpha.yaml
   ```

1. Install Istio's core components .
   There are two mutually exclusive options at this stage:

    * Install Istio without enabling [Istio Auth](https://istio.io/docs/concepts/network-and-auth/auth.html) feature:

   ```bash
   kubectl apply -f install/kubernetes/istio.yaml
   ```
   
   This command will install Istio-Manager, Mixer, Ingress-Controller, Egress-Controller core components.

   * Install Istio and enable [Istio Auth](https://istio.io/docs/concepts/network-and-auth/auth.html) feature:

   ```bash
   kubectl apply -f install/kubernetes/istio-auth.yaml
   ```

   This command will install Istio-Manager, Mixer, Ingress-Controller, and Egress-Controller, and the Istio CA (Certificate Authority).


1. *Optional:* To view metrics collected by Mixer, install [Prometheus](https://prometheus.io), [Grafana](http://staging.grafana.org) or
ServiceGraph addons.

   *Note 1*: The Prometheus addon is *required* as a prerequisite for Grafana and the ServiceGraph addons.

   ```bash
   kubectl apply -f install/kubernetes/addons/prometheus.yaml
   kubectl apply -f install/kubernetes/addons/grafana.yaml
   kubectl apply -f install/kubernetes/addons/servicegraph.yaml
   ```

   The Grafana addon provides a dashboard visualization of the metrics by Mixer to a Prometheus instance.

   The simplest way to access the Istio dashboard is to configure port-forwarding for the grafana service, as follows:

   ```bash
   kubectl port-forward $(kubectl get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
   ```

   Then open a web browser to [http://localhost:3000/dashboard/db/istio-dashboard](http://localhost:3000/dashboard/db/istio-dashboard).

   The dashboard at that location should look something like the following:

   ![Grafana Istio Dashboard](./img/grafana_dashboard.png)

   *Note 2*: In some deployment environments, it will be possible to access the dashboard directly (without the `kubectl port-forward` command). This is because 
   the default addon configuration requests an external IP address for the grafana service.

   When applicable, the external IP address for the grafana service can be retrieved via:

   ```bash
   kubectl get services grafana
   ```

   With the EXTERNAL-IP returned from that command, the Istio dashboard can be reached at `http://<EXTERNAL-IP>:3000/dashboard/db/istio-dashboard`.

## Verifying the installation

1. Ensure the following Kubernetes services were deployed: "istio-manager", "istio-mixer", "istio-ingress", "istio-egress", and "istio-ca" (if Istio Auth is enabled).

   ```bash
   kubectl get svc
   ```
   ```bash
   NAME                       CLUSTER-IP     EXTERNAL-IP     PORT(S)              AGE
   istio-egress               10.7.241.106   <none>          80/TCP               39m
   istio-ingress              10.83.241.84   35.184.70.168   80:30583/TCP         39m
   istio-manager              10.83.251.26   <none>          8080/TCP             39m
   istio-mixer                10.83.242.1    <none>          9091/TCP,42422/TCP   39m
   ```

   Note that if your cluster is running in an environment that does not support an external loadbalancer
   (e.g., minikube), the `EXTERNAL-IP` will say `<pending>` and you will need to access the
   application using the service NodePort instead.

2. Check the corresponding Kubernetes pods were deployed: "istio-manager-\*", "istio-mixer-\*", "istio-ingress-\*", "istio-egress-\*", and "istio-ca-\*" (if Istio Auth is enabled).

   ```bash
   kubectl get pods
   ```
   ```bash
   NAME                                       READY     STATUS    RESTARTS   AGE
   istio-egress-597320923-0szj8               1/1       Running   0          49m
   istio-ingress-594763772-j7jbz              1/1       Running   0          49m
   istio-manager-373576132-p2t9k              1/1       Running   0          49m
   istio-mixer-1154414227-56q3z               1/1       Running   0          49m
   istio-ca-1726969296-9srv2                  1/1       Running   0          49m
   ```

## Deploy your application

You can now deploy your own application, or one of the sample applications provided with the installation,
for example [BookInfo]({{home}}/docs/samples/bookinfo.html). Note that the application should use HTTP/1.1
or HTTP/2.0 protocol for all its HTTP traffic; HTTP/1.0 is not supported.

When deploying the application, you must
use [istioctl kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject) to automatically inject
Envoy containers in your application pods:

```bash
kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## Uninstalling

1. Uninstall Istio core components:

   * If Istio was installed without Istio auth feature:

   ```bash
   kubectl delete -f install/kubernetes/istio.yaml
   ```

   * If Istio was installed with auth feature enabled:

   ```bash
   kubectl delete -f install/kubernetes/istio-auth.yaml
   ```
2. Uninstall RBAC Istio roles:
   * If beta version was installed:
   ```bash
   kubectl delete -f istio-rbac-beta.yaml
   ```
   * If alpha version was installed:
   ```bash
   kubectl delete -f istio-rbac-alpha.yaml
   ```

## What's next

* See the sample [BookInfo]({{home}}/docs/samples/bookinfo.html) application.

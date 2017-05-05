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
    gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-name>
    ```

* Ensure the `curl` command is present.

## Installing on an existing cluster

For the Alpha release, Istio must be installed in the same Kubernetes namespace as the applications. Instructions below will deploy Istio in the
default namespace. They can be modified for deployment in a different namespace.

1. Download and extract the [istio installation files](https://raw.githubusercontent.com/istio/istio/master/releases/istio-alpha.tar.gz), or
clone Istio's [GitHub](https://github.com/istio/istio) repository:

    ```bash
    git clone https://github.com/istio/istio
    ```

2. Change directory to istio:

    ```bash
    cd istio
    ```

3. Install Istio's core components
   (Istio-Manager, Mixer, Ingress-Controller, and Istio CA if auth is enabled):

   **If you would like to disable Istio Auth**:

    ```bash
    kubectl apply -f ./kubernetes/istio-15.yaml # for Kubernetes 1.5
    ```

    or

    ```bash
    kubectl apply -f ./kubernetes/istio-16.yaml # for Kubernetes 1.6 or later
    ```

   **If you would like to enable Istio Auth** (For more information, please see
   [Istio Auth installation guide](./istio-auth.html)):

    ```bash
    kubectl apply -f ./kubernetes/istio-auth-15.yaml # for Kubernetes 1.5
    ```

    or

    ```bash
    kubectl apply -f ./kubernetes/istio-auth-16.yaml # for Kubernetes 1.6 or later
    ```

4. Source the Istio configuration file:

    ```bash
    source istio.VERSION
    ```

5. Download one of the [`istioctl`]({{home}}/docs/reference/commands/istioctl.html) client binaries corresponding to your OS: `istioctl-osx`, `istioctl-win.exe`,
`istioctl-linux`, targeted at Mac, Windows or Linux users respectively. For example, run the following commands on a Mac system:

    ```bash
    curl ${ISTIOCTL_URL}/istioctl-osx > /usr/local/bin/istioctl
    chmod +x /usr/local/bin/istioctl
    ```

    `istioctl` is needed to inject Envoy as a sidecar proxy. It also provides a convenient CLI for creating routing rules and policies.
    Note: If you already have a previously installed version of `istioctl`, make sure that
    it is compatible with the manager image used in `istio.yaml`.
    If in doubt, download again or add the `--tag` option when running `istioctl kube-inject`.
    Invoke `istioctl kube-inject --help` for more details.

6. Optional: to view metrics collected by Mixer, install [Prometheus](https://prometheus.io), [Grafana](http://staging.grafana.org) or
ServiceGraph addons:

    ```bash
    kubectl apply -f ./kubernetes/addons/grafana.yaml
    kubectl apply -f ./kubernetes/addons/prometheus.yaml
    kubectl apply -f ./kubernetes/addons/servicegraph.yaml
    ```

    The grafana addon provides a dashboard visualization of the metrics by Mixer to a Prometheus instance. Please install both the prometheus.yaml and grafana.yaml addons to configure the Istio dashboard for use.

    The simplest way to access the Istio dashboard is to configure port-forwarding for the grafana service, as follows:

    ```bash
    kubectl port-forward $(kubectl get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
    ```

    Then open a web browser to `http://localhost:3000/dashboard/db/istio-dashboard`.

    The dashboard at that location should look something like the following:

    ![Grafana Istio Dashboard](./img/grafana_dashboard.png)

    NOTE: In some deployment environments, it will be possible to access the dashboard directly (without the `kubectl port-forward` command). This is because the default addon configuration requests an external IP address for the grafana service.

    When applicable, the external IP address for the grafana service can be retrieved via:

    ```bash
    kubectl get services grafana
    ```

    With the EXTERNAL-IP returned from that command, the Istio dashboard can be reached at `http://<EXTERNAL-IP>:3000/dashboard/db/istio-dashboard`.

## Verifying the installation

1. Ensure the following Kubernetes services were deployed: "istio-manager", "istio-mixer", and "istio-ingress".

    ```bash
    kubectl get svc
    NAME                       CLUSTER-IP     EXTERNAL-IP     PORT(S)              AGE
    istio-ingress              10.83.241.84   35.184.70.168   80:30583/TCP         39m
    istio-manager              10.83.251.26   <none>          8080/TCP             39m
    istio-mixer                10.83.242.1    <none>          9091/TCP,42422/TCP   39m
    ```

    Note that if your cluster is running in an environment that does not support an external loadbalancer
    (e.g., minikube), the `EXTERNAL-IP` will say `<pending>` and you will need to access the
    application using the service NodePort instead.

2. Check the corresponding Kubernetes pods were deployed: "istio-manager-\*", "istio-mixer-\*", "istio-ingress-\*" and
   "istio-ca-\*" (if Istio Auth is enabled).

    ```bash
    kubectl get pods
    NAME                                       READY     STATUS    RESTARTS   AGE
    istio-ingress-594763772-j7jbz              1/1       Running   0          49m
    istio-manager-373576132-p2t9k              1/1       Running   0          49m
    istio-mixer-1154414227-56q3z               1/1       Running   0          49m
    istio-ca-1726969296-9srv2                  1/1       Running   0          49m
    ```

## Deploy your application

You can now deploy your own application or one of the Istio sample applications,
for example [bookinfo]({{home}}/docs/samples/bookinfo.html). Note that the application should use HTTP/1.1
or HTTP/2.0 protocol for all its HTTP traffic.

When deploying the application,
use [kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject.html) to automatically inject
Envoy containers in the pods running the services:
```bash
kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## Uninstalling

1. Uninstall Istio:

    **If Istio has auth disabled:**

    ```bash
    kubectl delete -f ./kubernetes/istio-16.yaml
    ```

    **If Istio has auth enabled:**

    ```bash
    kubectl delete -f ./kubernetes/istio-auth-16.yaml
    ```

2. Delete the istioctl client:

    ```bash
    rm /usr/local/bin/istioctl
    ```

## What's next

* Learn more about how to enable [authentication](./istio-auth.html).

* See the sample [bookinfo]({{home}}/docs/samples/bookinfo.html) application.

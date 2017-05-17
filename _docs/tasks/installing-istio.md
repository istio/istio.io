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

* The following instructions assume you have access to a Kubernetes cluster. To install Kubernetes locally,
  try [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/).

* If you are using [Google Container Engine](https://cloud.google.com/container-engine), please make sure you are using static 
  client certificates before fetching cluster credentials:

  ```bash
  gcloud config set container/use_client_certificate True
  ```
  Find out your cluster name and zone, and fetch credentials for kubectl:
  ```bash
  gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-name>
  ```

* If you are using [IBM Bluemix Container Service](https://www.ibm.com/cloud-computing/bluemix/containers), find out your cluster name, and fetch credentials for kubectl:

  ```bash
  $(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
  ```
  
* Install the Kubernetes client [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), or upgrade to the latest
  version supported by your cluster.

* If you previously installed Istio on this cluster, please uninstall first by following the
  [uninstalling]({{home}}/docs/tasks/installing-istio.html#uninstalling) steps at the end of this page.

## Installation steps

For the {{ site.data.istio.version }} release, Istio must be installed in the same Kubernetes namespace as the applications. 
Instructions below will deploy Istio in the
default namespace. They can be modified for deployment in a different namespace.

1. Go to the [Istio release](https://github.com/istio/istio/releases) page, to download the installation file corresponding to your OS or run 
   ```bash
   curl -L https://git.io/getIstio | sh -
   ``` 
   to download and extract the latest release automatically (on MacOS and Ubuntu).

1. Extract the installation file, and change directory to the location where the files were extracted. Following instructions 
   are relative to this installation directory.
   The installation directory contains:
    * yaml installation files for Kubernetes
    * sample apps
    * the `istioctl` client binary, needed to inject Envoy as a sidecar proxy, and useful for creating routing rules and policies.
    * the istio.VERSION configuration file.

1. Add the `istioctl` client to your PATH. For example, run the following commands on a Linux or MacOS system:

   ```bash
   export PATH=$PWD/bin:$PATH
   ```

1. Run the following command to determine if your cluster has 
   [RBAC (Role-Based Access Control)](https://kubernetes.io/docs/admin/authorization/rbac/) enabled:

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

    * Install Istio without enabling [Istio Auth]({{home}}/docs/concepts/network-and-auth/auth.html) feature:

   ```bash
   kubectl apply -f install/kubernetes/istio.yaml
   ```
   
   This command will install Istio-Manager, Mixer, Ingress-Controller, Egress-Controller core components.

   * Install Istio and enable [Istio Auth]({{home}}/docs/concepts/network-and-auth/auth.html) feature
   (This deploys a CA in the namespace and enables
   [mTLS](https://en.wikipedia.org/wiki/Mutual_authentication) between the services):

   ```bash
   kubectl apply -f install/kubernetes/istio-auth.yaml
   ```

   This command will install Istio-Manager, Mixer, Ingress-Controller, and Egress-Controller, and the Istio CA (Certificate Authority).

1. *Optional:* To collect and view metrics provided by Mixer, install [Prometheus](https://prometheus.io),
   as well as the [Grafana](http://staging.grafana.org) and/or ServiceGraph addons.

   ```bash
   kubectl apply -f install/kubernetes/addons/prometheus.yaml
   kubectl apply -f install/kubernetes/addons/grafana.yaml
   kubectl apply -f install/kubernetes/addons/servicegraph.yaml
   ```

   * The Grafana addon provides an Istio dashboard visualization of the metrics (request rates, success/failure rates)
     in the cluseter.

     You can access the Grafana dashboard using port-forwarding, the service nodePort, or External IP (if your deployment
     environment provides external load balancers).
      
     The simplest way to access the Grafana dashboard is to configure port-forwarding for the grafana service, as follows:

     ```bash
     kubectl port-forward $(kubectl get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
     ```

     Then point your web browser to [http://localhost:3000/dashboard/db/istio-dashboard](http://localhost:3000/dashboard/db/istio-dashboard).

     The dashboard should look something like this:

     {% include figure.html
        file="./img/grafana_dashboard.png"
        max-width="100%"
        alt="Grafana Istio Dashboard"
     %}
     
     If your deployment environment provides external load balancers, you can simply access the dashboard directly
     (without the `kubectl port-forward` command) using the external IP address of the grafana service:
   
     ```bash
     kubectl get services grafana
     ```
   
     Using the EXTERNAL-IP returned from that command, the Istio dashboard can be reached
     at `http://<EXTERNAL-IP>:3000/dashboard/db/istio-dashboard`.

   * The ServiceGraph addon provides a textual (JSON) represenation and a graphical visualization of the service
     interaction graph for the cluster.

     Similar to Grafana, you can access the servicegraph service using port-forwarding, service nodePort, or External IP.
     In this case the service name is `servicegraph` and the port to access is 8088:
     
     ```bash
     kubectl port-forward $(kubectl get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088
     ```
     
     The ServiceGraph service provides both a textual (JSON) representation (via `/graph`)
     and a graphical visualization (via `/dotviz`) of the underlying service graph.
   
     To view the graphical visualization, you could (using port-forwarding) open your browser at:
     [http://localhost:8088/dotviz](http://localhost:8088/dotviz). 
   
     After running some services, for example, after installing the [BookInfo]({{home}}/docs/samples/bookinfo.html) 
     sample application and executing the `curl` request to confirm it's working, the resulting service graph
     would look something like:
   
     {% include figure.html
        file="./img/servicegraph.png"
        alt="BookInfo Service Graph"
     %}
     
     At that point the servicegraph would show very low (or zero) QPS values, as only a single request
     has been sent. The service uses a default time window of 5 minutes for calculating moving QPS averages.
     You can later send a more consistent flow of traffic through the example application and refresh the servicegraph
     to view updated QPS values that match the generated level of traffic.

1. *Optional:* To enable and view distributed request tracing, install the [Zipkin](http://zipkin.io) addon:

   ```bash
   kubectl apply -f install/kubernetes/addons/zipkin.yaml
   ```
   
   Zipkin can be used to analyze the request flow and timing of an Istio application and to help identify bottlenecks.
   
   Just like any external URL, use your favorite platform-specific technique (port-forwarding, service nodePort,
   external LB) to access the Zipkin dashboard. For example, you can use port-forwarding to access Zipkin like this:
   
   ```bash
   kubectl port-forward $(kubectl get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}') 9411:9411
   ```
    
   and then view the dashboard at [http://localhost:9411](http://localhost:9411). 
   You won't see any traces until you send requests to the application.
   
   Check out the [Tracing]({{home}}/docs/tasks/zipkin-tracing.html) task for details.

## Verifying the installation

1. Ensure the following Kubernetes services were deployed: "istio-manager", "istio-mixer", "istio-ingress", "istio-egress",
   and "istio-ca" (if Istio Auth is enabled).

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

   Note that if your cluster is running in an environment that does not support an external load balancer
   (e.g., minikube), the `EXTERNAL-IP` of `istio-ingress` will say `<pending>` and you will need to access the
   application using the service NodePort or port-forwarding instead.

2. Check the corresponding Kubernetes pods were deployed: "istio-manager-\*", "istio-mixer-\*", "istio-ingress-\*", "istio-egress-\*",
   and "istio-ca-\*" (if Istio Auth is enabled).

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

* See how to [test Istio Auth]({{home}}/docs/tasks/istio-auth.html).

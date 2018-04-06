---
title: Quick Start with Google Kubernetes Engine
overview: Quick Start instructions to setup the Istio service using Google Kubernetes Engine (GKE)

order: 11

layout: docs
type: markdown
---

{% include home.html %}

Quick Start instructions to install and run Istio in [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) (GKE) using [Google Cloud Deployment Manager](https://cloud.google.com/deployment-manager/).

This Quick Start creates a new GKE [zonal cluster](https://cloud.google.com/kubernetes-engine/versioning-and-upgrades#versions_available_for_new_cluster_masters), installs Istio and then deploys the [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample
application.  It uses Deployment Manager to automate the steps detailed in the [Istio on Kubernetes setup guide]({{home}}/docs/setup/kubernetes/quick-start.html) for Kubernetes Engine

## Prerequisites

- This sample requires a valid Google Cloud Platform project with billing enabled. If you are not an existing GCP user, you may be able to enroll for a $300 US [Free Trial](https://cloud.google.com/free/) credit.

- Ensure that the [Google Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com/) is enabled for your project (also found by navigating to "APIs &amp; Services" -> "Dashboard" in the navigation bar). If you do not see "API enabled", then you may enable the API by clicking the "Enable this API" button.

- You must install and configure the [gcloud command line tool](https://cloud.google.com/sdk/docs/) and include the `kubectl` component (`gcloud components install kubectl`).  If you don't want to install the `gcloud` client on your own machine, you can use `gcloud` via [Google Cloud Shell](https://cloud.google.com/shell/docs/) to perform the same tasks.

- <img src="{{home}}/img/exclamation-mark.svg" alt="Warning" title="Warning" style="width: 32px; display:inline" /> You must set your default compute service account to include:
> - ```roles/container.admin```  (Kubernetes Engine Admin)
> - ```Editor```  (on by default)

   To set this, navigate to the **IAM** section of the [Cloud Console](https://console.cloud.google.com/iam-admin/iam/project) as shown below and find your default GCE/GKE service account in the following form: `projectNumber-compute@developer.gserviceaccount.com`: by default it should just have the **Editor** role. Then in the **Roles** drop-down list for that account, find the **Kubernetes Engine** group and select the role **Kubernetes Engine Admin**. The **Roles** listing for your account will change to **Multiple**.

   {% include figure.html width="100%" ratio="30%"
    img='./img/dm_gcp_iam.png'
    alt='GCP-IAM Permissions'
    title='GCP-IAM Permissions'
    caption='GKE-IAM Permissions'
    %}

## Setup

### Launch Deployment Manager

1. Once you have an account and project enabled, click the following link to open the Deployment Manager.

   [Istio GKE Deployment Manager](https://accounts.google.com/signin/v2/identifier?service=cloudconsole&continue=https://console.cloud.google.com/launcher/config?templateurl=https://raw.githubusercontent.com/istio/istio/master/install/gcp/deployment_manager/istio-cluster.jinja&followup=https://console.cloud.google.com/launcher/config?templateurl=https://raw.githubusercontent.com/istio/istio/master/install/gcp/deployment_manager/istio-cluster.jinja&flowName=GlifWebSignIn&flowEntry=ServiceLogin)

   We recommend that you leave the default settings as the rest of this tutorial shows how to access the installed features. By default the tool creates a
   GKE alpha cluster with the specified settings, then installs the Istio [control plane]({{home}}/docs/concepts/what-is-istio/overview.html#architecture), the
   [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample app,
   [Grafana]({{home}}/docs/tasks/telemetry/using-istio-dashboard.html) with
   [Prometheus]({{home}}/docs/tasks/telemetry/querying-metrics.html),
   [ServiceGraph]({{home}}/docs/tasks/telemetry/servicegraph.html),
   and [Zipkin]({{home}}/docs/tasks/telemetry/distributed-tracing.html#zipkin).
   You'll find out more about how to access all of these below.  This script will enable Istio auto-injection on the ```default``` namespace only.

1. Click **Deploy**:

   {% include figure.html width="100%" ratio="67.17%"
    img='./img/dm_launcher.png'
    alt='GKE-Istio Launcher'
    title='GKE-Istio Launcher'
    caption='GKE-Istio Launcher'
    %}

   Wait until Istio is fully deployed. Note that this can take up to five minutes.

### Bootstrap gcloud

Once deployment is complete, do the following on the workstation where you've installed `gcloud`:

1. Bootstrap `kubectl` for the cluster you just created and confirm the cluster is
running and Istio is enabled

   ```bash
   gcloud container clusters list
   ```

   ```xxx
   NAME           ZONE           MASTER_VERSION                    MASTER_IP       MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
   istio-cluster  us-central1-a  v1.9.2-gke.1                      130.211.216.64  n1-standard-2  v1.9.2-gke.1  3          RUNNING
   ```

   In this case, the cluster name is ```istio-cluster```

1. Now acquire the credentials for this cluster

   ```bash
   gcloud container clusters get-credentials istio-cluster --zone=us-central1-a
   ```

## Verify installation

Verify Istio is installed in its own namespace

```bash
kubectl get deployments,ing -n istio-system
```

```xxx
NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/grafana             1         1         1            1           3m
deploy/istio-ca            1         1         1            1           3m
deploy/istio-ingress       1         1         1            1           3m
deploy/istio-initializer   1         1         1            1           3m
deploy/istio-mixer         1         1         1            1           3m
deploy/istio-pilot         1         1         1            1           3m
deploy/prometheus          1         1         1            1           3m
deploy/servicegraph        1         1         1            1           3m
deploy/zipkin              1         1         1            1           3m
```

Now confirm that the Bookinfo sample application is also installed:

```bash
kubectl get deployments,ing
```

```xxx
NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/details-v1       1         1         1            1           3m
deploy/productpage-v1   1         1         1            1           3m
deploy/ratings-v1       1         1         1            1           3m
deploy/reviews-v1       1         1         1            1           3m
deploy/reviews-v2       1         1         1            1           3m
deploy/reviews-v3       1         1         1            1           3m

NAME          HOSTS     ADDRESS         PORTS     AGE
ing/gateway   *         35.202.120.89   80        3m
```

Note down the IP and Port assigned to Bookinfo product page. (in the example above, its ```35.202.120.89:80```.

You can also view the installation using the ***Kubernetes Engine -> Workloads** section on the [Cloud Console](https://console.cloud.google.com/kubernetes/workload):

{% include figure.html width="100%" ratio="65.37%"
    img='./img/dm_kubernetes_workloads.png'
    alt='GKE-Workloads'
    title='GKE-Workloads'
    caption='GKE-Workloads'
    %}

### Access the Bookinfo sample

1. Set up an environment variable for Bookinfo's external IP address:

   ```bash
   kubectl get ingress -o wide
   ```
   ```bash
   export GATEWAY_URL=35.202.120.89
   ```

1. Verify you can access the Bookinfo ```http://${GATEWAY_URL}/productpage```:

   {% include figure.html width="100%" ratio="45.04%"
    img='./img/dm_bookinfo.png'
    alt='Bookinfo'
    title='Bookinfo'
    caption='Bookinfo'
    %}

1. Now send some traffic to it:
   ```bash
   for i in {1..100}; do curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage; done
   ```

## Verify installed Istio plugins

Once you have verified that the Istio control plane and sample application are working, try accessing the installed Istio plugins.

If you are using Cloud Shell rather than the installed `gcloud` client, you can port forward and proxy using its [Web Preview](https://cloud.google.com/shell/docs/using-web-preview#previewing_the_application) feature.  For example, to access Grafana from Cloud Shell, change the `kubectl` port mapping from 3000:3000 to 8080:3000.  You can simultaneously preview four other consoles via Web Preview proxied on ranges 8080 to 8084.

### Grafana

Set up a tunnel to Grafana:

```bash
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
```
then
```xxx
http://localhost:3000/dashboard/db/istio-dashboard
```
You should see some statistics for the requests you sent earlier.

{% include figure.html width="100%" ratio="48.49%"
    img='./img/dm_grafana.png'
    alt='Grafana'
    title='Grafana'
    caption='Grafana'
    %}

For more details about using Grafana, see [About the Grafana Add-on]({{home}}/docs/tasks/telemetry/using-istio-dashboard.html#about-the-grafana-add-on).

### Prometheus

Prometheus is installed with Grafana. You can view Istio and application metrics using the console as follows:

```bash
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
```

View the console at:

```xxx
http://localhost:9090/graph
```

{% include figure.html width="100%" ratio="43.88%"
    img='./img/dm_prometheus.png'
    alt='Prometheus'
    title='Prometheus'
    caption='Prometheus'
    %}

For more details, see [About the Prometheus Add-on]({{home}}/docs/tasks/telemetry/querying-metrics.html#about-the-prometheus-add-on).

### ServiceGraph

Set up a tunnel to ServiceGraph:

```bash
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &
```

You should see the Bookinfo service topology at

```xxx
http://localhost:8088/dotviz
```

{% include figure.html width="100%" ratio="53.33%"
    img='./img/dm_servicegraph.png'
    alt='ServiceGraph'
    title='ServiceGraph'
    caption='ServiceGraph'
    %}

For more details, see [About the ServiceGraph Add-on]({{home}}/docs/tasks/telemetry/servicegraph.html#about-the-servicegraph-add-on).

## Tracing

Set up a tunnel to Zipkin:

```bash
kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=zipkin -o jsonpath='{.items[0].metadata.name}') 9411:9411 &
```

You should see the trace statistics sent earlier:

```xxx
http://localhost:9411
```

{% include figure.html width="100%" ratio="57.00%"
    img='./img/dm_zipkin.png'
    alt='Zipkin'
    title='Zipkin'
    caption='Zipkin'
    %}

For more details on tracing see [Understanding what happened]({{home}}/docs/tasks/telemetry/distributed-tracing.html#understanding-what-happened).

## What's next

You can further explore the Bookinfo app and Istio functionality by following any of the tutorials in the
[Guides]({{home}}/docs/guides/) section. However, to do this you need to install `istioctl` to interact
with Istio. You can either [install]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps) it directly
on our workstation or within Cloud Shell.

## Uninstalling

1. Navigate to the Deployments section of the Cloud Console at [https://console.cloud.google.com/deployments](https://console.cloud.google.com/deployments)

1. Select the deployment and click **Delete**.

1. Deployment Manager will remove all the deployed GKE artifacts - however, items such as Ingress and LoadBalancers will remain. You can delete those artifacts
by again going to the cloud console under [**Network Services** -> **LoadBalancers**](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list)

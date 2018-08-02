---
title: Quick Start with Google Kubernetes Engine
description: Quick Start instructions to setup the Istio service using Google Kubernetes Engine (GKE)
weight: 20
keywords: [kubernetes,gke,google]
---

Quick Start instructions to install and run Istio in [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) (GKE) using [Google Cloud Deployment Manager](https://cloud.google.com/deployment-manager/).

This Quick Start creates a new GKE [zonal cluster](https://cloud.google.com/kubernetes-engine/versioning-and-upgrades#versions_available_for_new_cluster_masters), installs the current release version of Istio and then deploys the [Bookinfo](/docs/examples/bookinfo/) sample
application.  It uses Deployment Manager to automate the steps detailed in the [Istio on Kubernetes setup instructions](/docs/setup/kubernetes/quick-start/) for Kubernetes Engine

## Prerequisites

- This sample requires a valid Google Cloud Platform project with billing enabled. If you are not an existing GCP user, you may be able to enroll for a $300 US [Free Trial](https://cloud.google.com/free/) credit.

- Ensure that the [Google Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com/) is enabled for your project (also found by navigating to "APIs &amp; Services" -> "Dashboard" in the navigation bar). If you do not see "API enabled", then you may enable the API by clicking the "Enable this API" button.

- You must install and configure the [`gcloud` command line tool](https://cloud.google.com/sdk/docs/) and include the `kubectl` component (`gcloud components install kubectl`).  If you don't want to install the `gcloud` client on your own machine, you can use `gcloud` via [Google Cloud Shell](https://cloud.google.com/shell/docs/) to perform the same tasks.

- {{< warning_icon >}} You must set your default compute service account to include:

    - `roles/container.admin`  (Kubernetes Engine Admin)
    - `Editor`  (on by default)

To set this up, navigate to the **IAM** section of the [Cloud Console](https://console.cloud.google.com/iam-admin/iam/project) as shown below and find your default GCE/GKE service account in the following form: `projectNumber-compute@developer.gserviceaccount.com`: by default it should just have the **Editor** role. Then in the **Roles** drop-down list for that account, find the **Kubernetes Engine** group and select the role **Kubernetes Engine Admin**. The **Roles** listing for your account will change to **Multiple**.

{{< image width="100%" ratio="22.94%"
link="./dm_gcp_iam.png"
caption="GKE-IAM Service"
>}}

Then add the `Kubernetes Engine Admin` role:

{{< image width="70%" ratio="65.04%"
link="./dm_gcp_iam_role.png"
caption="GKE-IAM Role"
>}}

## Setup

### Launch Deployment Manager

1.  Once you have an account and project enabled, click the following link to open the Deployment Manager.

    [Istio GKE Deployment Manager](https://accounts.google.com/signin/v2/identifier?service=cloudconsole&continue=https://console.cloud.google.com/launcher/config?templateurl={{< github_file >}}/install/gcp/deployment_manager/istio-cluster.jinja&followup=https://console.cloud.google.com/launcher/config?templateurl=https://raw.githubusercontent.com/istio/istio/master/install/gcp/deployment_manager/istio-cluster.jinja&flowName=GlifWebSignIn&flowEntry=ServiceLogin)

    We recommend that you leave the default settings as the rest of this tutorial shows how to access the installed features. By default the tool creates a
    GKE alpha cluster with the specified settings, then installs the Istio [control plane](/docs/concepts/what-is-istio/#architecture), the
    [Bookinfo](/docs/examples/bookinfo/) sample app,
    [Grafana](/docs/tasks/telemetry/using-istio-dashboard/) with
    [Prometheus](/docs/tasks/telemetry/querying-metrics/),
    [ServiceGraph](/docs/tasks/telemetry/servicegraph/),
    and [Tracing](/docs/tasks/telemetry/distributed-tracing/).
    You'll find out more about how to access all of these below.  This script will enable Istio auto-injection on the `default` namespace only.

1.  Click **Deploy**:

    {{< image width="100%" ratio="67.17%"
    link="./dm_launcher.png"
    caption="GKE-Istio Launcher"
    >}}

Wait until Istio is fully deployed. Note that this can take up to five minutes.

### Bootstrap `gcloud`

Once deployment is complete, do the following on the workstation where you've installed `gcloud`:

1.  Bootstrap `kubectl` for the cluster you just created and confirm the cluster is
running and Istio is enabled

    {{< text bash >}}
    $ gcloud container clusters list
    NAME           LOCATION       MASTER_VERSION  MASTER_IP      MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
    istio-cluster  us-central1-a  1.9.7-gke.1     35.232.222.60  n1-standard-2  1.9.7-gke.1   4          RUNNING
    {{< /text >}}

    In this case, the cluster name is `istio-cluster`.

1.  Now acquire the credentials for this cluster

    {{< text bash >}}
    $ gcloud container clusters get-credentials istio-cluster --zone=us-central1-a
    {{< /text >}}

## Verify installation

Verify Istio is installed in its own namespace

{{< text bash >}}
$ kubectl get deployments,ing -n istio-system
NAME                              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/grafana                    1         1         1            1           4m
deploy/istio-citadel              1         1         1            1           4m
deploy/istio-egressgateway        1         1         1            1           4m
deploy/istio-ingress              1         1         1            1           4m
deploy/istio-ingressgateway       1         1         1            1           4m
deploy/istio-pilot                1         1         1            1           4m
deploy/istio-policy               1         1         1            1           4m
deploy/istio-sidecar-injector     1         1         1            1           4m
deploy/istio-statsd-prom-bridge   1         1         1            1           4m
deploy/istio-telemetry            1         1         1            1           4m
deploy/prometheus                 1         1         1            1           4m
deploy/servicegraph               1         1         1            1           4m
{{< /text >}}

Now confirm that the Bookinfo sample application is also installed:

{{< text bash >}}
$ kubectl get deployments,ing
NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/details-v1       1         1         1            1           7m
deploy/productpage-v1   1         1         1            1           7m
deploy/ratings-v1       1         1         1            1           7m
deploy/reviews-v1       1         1         1            1           7m
deploy/reviews-v2       1         1         1            1           7m
deploy/reviews-v3       1         1         1            1           7m
{{< /text >}}

Now get the `istio-ingress` IP:

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.59.251.109   35.194.26.85   80:31380/TCP,443:31390/TCP,31400:31400/TCP   6m
{{< /text >}}

Note down the IP address (EXTERNAL-IP) and port assigned to the Bookinfo product page
(in the example above, it's `35.194.26.85:80`).

You can also view the installation using the **Kubernetes Engine -> Workloads** section on the [Cloud Console](https://console.cloud.google.com/kubernetes/workload):

{{< image width="70%" ratio="80.37%"
    link="./dm_kubernetes_workloads.png"
    caption="GKE-Workloads"
    >}}

### Access the Bookinfo sample

1.  Set up an environment variable for Bookinfo's external IP address:

    {{< text bash >}}
    $ export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GATEWAY_URL
    {{< /text >}}

1.  Verify you can access the Bookinfo `http://${GATEWAY_URL}/productpage`:

    {{< image width="100%" ratio="45.04%"
    link="./dm_bookinfo.png"
    caption="Bookinfo"
    >}}

1.  Now send some traffic to it:

    {{< text bash >}}
    $ for i in {1..100}; do curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage; done
    {{< /text >}}

## Verify installed Istio plugins

Once you have verified that the Istio control plane and sample application are working, try accessing the installed Istio plugins.

If you are using Cloud Shell rather than the installed `gcloud` client, you can port forward and proxy using its [Web Preview](https://cloud.google.com/shell/docs/using-web-preview#previewing_the_application) feature.  For example, to access Grafana from Cloud Shell, change the `kubectl` port mapping from 3000:3000 to 8080:3000.  You can simultaneously preview four other consoles via Web Preview proxied on ranges 8080 to 8084.

### Grafana

Set up a tunnel to Grafana:

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
{{< /text >}}

then

{{< text plain >}}
http://localhost:3000/dashboard/db/istio-dashboard
{{< /text >}}

You should see some statistics for the requests you sent earlier.

{{< image width="100%" ratio="48.49%"
    link="./dm_grafana.png"
    caption="Grafana"
    >}}

For more details about using Grafana, see [About the Grafana Add-on](/docs/tasks/telemetry/using-istio-dashboard/#about-the-grafana-add-on).

### Prometheus

Prometheus is installed with Grafana. You can view Istio and application metrics using the console as follows:

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
{{< /text >}}

View the console at:

{{< text plain >}}
http://localhost:9090/graph
{{< /text >}}

{{< image width="100%" ratio="43.88%"
    link="./dm_prometheus.png"
    caption="Prometheus"
    >}}

For more details, see [About the Prometheus Add-on](/docs/tasks/telemetry/querying-metrics/#about-the-prometheus-add-on).

### ServiceGraph

Set up a tunnel to ServiceGraph:

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &
{{< /text >}}

You should see the Bookinfo service topology at

{{< text plain >}}
http://localhost:8088/dotviz
{{< /text >}}

{{< image width="100%" ratio="53.33%"
    link="./dm_servicegraph.png"
    caption="ServiceGraph"
    >}}

For more details, see [About the ServiceGraph Add-on](/docs/tasks/telemetry/servicegraph/#about-the-servicegraph-add-on).

## Tracing

Set up a tunnel to the tracing dashboard:

{{< text bash >}}
$ kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686 &
{{< /text >}}

You should see the trace statistics sent earlier on [http://localhost:16686](http://localhost:16686)

{{< image width="100%" ratio="42.35%"
    link="./dm-tracing.png"
    caption="Tracing Dashboard"
    >}}

For more details on tracing see [Understanding what happened](/docs/tasks/telemetry/distributed-tracing/#understanding-what-happened).

## Uninstalling

1. Navigate to the Deployments section of the Cloud Console at [https://console.cloud.google.com/deployments](https://console.cloud.google.com/deployments)

1. Select the deployment and click **Delete**.

1. Deployment Manager will remove all the deployed GKE artifacts - however, items such as `Ingress` and `LoadBalancers` will remain. You can delete those artifacts
by again going to the cloud console under [**Network Services** -> **Load balancing**](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list)

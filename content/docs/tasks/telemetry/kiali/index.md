---
title: Visualizing Your Mesh
description: This task shows you how to visualize your services within an Istio mesh.
weight: 49
keywords: [telemetry,visualization]
---

This task shows you how to visualize different aspects of your Istio mesh.

As part of this task, you install the [Kiali](https://www.kiali.io) add-on
and use the web-based graphical user interface to view service graphs of
the mesh and your Istio configuration objects. Lastly, you use the Kiali
Public API to generate graph data in the form of consumable JSON.

This task uses the [Bookinfo](/docs/examples/bookinfo/) sample application as the example throughout.

## Before you begin

> {{< idea_icon >}} The following instructions assume you have installed Helm and use it to install Kiali.
To install Kiali without using Helm, following the [Kiali install instructions](https://www.kiali.io/gettingstarted/).

Create a secret in your Istio namespace with the credentials that you use to
authenticate to Kiali. See the
[Helm README](https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/README.md#installing-the-chart)
for details. Modify and run the following example commands to create a secret:

```bash
USERNAME=$(echo -n 'admin' | base64)
PASSPHRASE=$(echo -n 'mysecret' | base64)
NAMESPACE=istio-system
kubectl create namespace $NAMESPACE
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $USERNAME
  passphrase: $PASSPHRASE
EOF
```

Once you create the Kiali secret, follow
[the Helm install instructions](/docs/setup/kubernetes/helm-install/) to install Kiali via Helm.
You must use the `--set kiali.enabled=true` option when you run the `helm` command, for example:

{{< text bash >}}
$ helm template --set kiali.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
$ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

> {{< idea_icon >}} This Task does not discuss Jaeger and Grafana. If
you already installed them in your cluster and you want to see how Kiali
integrates with them, you must pass additional arguments to the
`helm` command, for example:

{{< text bash >}}
    $ helm template \
        --set kiali.enabled=true \
        --set "kiali.dashboard.jaegerURL=http://$(kubectl get svc tracing -o jsonpath='{.spec.clusterIP}'):80" \
        --set "kiali.dashboard.grafanaURL=http://$(kubectl get svc grafana -o jsonpath='{.spec.clusterIP}'):3000" \
        install/kubernetes/helm/istio \
        --name istio --namespace istio-system > $HOME/istio.yaml
    $ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

Once you install Istio and Kiali, deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

## Generating a service graph

1.  To verify the service is running in your cluster, run the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    {{< /text >}}

1.  To determine the Bookinfo URL, follow the instructions to determine the [Bookinfo ingress `GATEWAY_URL`](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port).

1.  To send traffic to the mesh, you have three options

    *   Visit `http://$GATEWAY_URL/productpage` in your web browser

    *   Use the following command multiple times:

        {{< text bash >}}
        $ curl http://$GATEWAY_URL/productpage
        {{< /text >}}

    *   If you installed the `watch` command in your system, send requests continually with:

        {{< text bash >}}
        $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
        {{< /text >}}

1.  To determine the Kiali URL, you use the same `GATEWAY_URL` as the Bookinfo application,
    only with a different port.

    *   If you are running in an environment that has external load balancers,
        run this command:

        {{< text bash >}}
        $ KIALI_URL="http://$(echo $GATEWAY_URL | sed -e s/:.*//):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http-kiali")].port}')"
        $ echo $KIALI_URL
        http://172.30.141.9:15029
        {{< /text >}}

    *   If you are running in an environment that does not support external
        load balancers (e.g., minikube), run this command:

        {{< text bash >}}
        $ KIALI_URL="http://$(echo $GATEWAY_URL | sed -e s/:.*//):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http-kiali")].nodePort}')"
        $ echo $KIALI_URL
        http://192.168.99.100:31758
        {{< /text >}}

1.  To visit the Kiali UI, point your browser to `$KIALI_URL`.

1.  To log into the Kiali UI, enter the username and passphrase you stored in the Kiali secret in the Kiali login screen. If you used the example secret above, enter a username of `admin` with a passphrase of `mysecret`.

1.  View the overview of your mesh in the **Overview** page that appears immediately after you log in.
    The **Overview** page displays all the namespaces that have services in your mesh.
    The following screenshot shows a similar page:

    {{< image width="75%" ratio="58%"
    link="./kiali-overview.png"
    caption="Example Overview"
    >}}

1.  To view a namespace graph, click on the `bookinfo` namespace in the Bookinfo namespace card.
    The page looks similar to:

    {{< image width="75%" ratio="89%"
    link="./kiali-graph.png"
    caption="Example Graph"
    >}}

1.  To view a summary of metrics, select any node or edge in the graph to display
    its metric details in the summary details panel on the right.

1.  To view your service mesh using different graph types, select a graph type
    from the **Graph Type** drop down menu. There are several graph types
    to choose from: **App**, **Versioned App**, **Workload**, **Service**.

    *   The **App** graph type aggregates all versions of an app into a single graph node.
        The following example shows a single **reviews** node representing the three versions
        of the reviews app.

        {{< image width="75%" ratio="35%"
        link="./kiali-app.png"
        caption="Example App Graph"
        >}}

    *   The **Versioned App** graph type shows a node for each version of an app,
        but all versions of a particular app are grouped together. The following example
        shows the **reviews** group box that contains the three nodes that represents the
        three versions of the reviews app.

        {{< image width="75%" ratio="67%"
        link="./kiali-versionedapp.png"
        caption="Example Versioned App Graph"
        >}}

    *   The **Workload** graph type shows a node for each workload in your service mesh.
        This graph type does not require you to use the `app` and `version` labels so if you
        opt to not use those labels on your components, this is the graph type you will use.

        {{< image width="70%" ratio="76%"
        link="./kiali-workload.png"
        caption="Example Workload Graph"
        >}}

    *   The **Service** graph type shows a node for each service in your mesh but excludes
        all apps and workloads from the graph.

        {{< image width="70%" ratio="35%"
        link="./kiali-service-graph.png"
        caption="Example Service Graph"
        >}}

1. To examine the details about the Istio configuration, click on the
   **Applications**, **Workloads**, and **Services** menu icons on the left menu
   bar. The following screenshot shows the Bookinfo applications information:

   {{< image width="80%" ratio="56%"
   link="./kiali-services.png"
   caption="Example Details"
   >}}

## About the Kiali Public API

To generate JSON files representing the graphs and other metrics, health, and
configuration information, you can access the
[Kiali Public API](https://www.kiali.io/api/paths).
For example, point your browser to `$KIALI_URL/api/namespaces/bookinfo/graph?graphType=app`
to get the JSON representation of your graph using the `app` graph type.

The Kiali Public API is built on top of Prometheus queries and depends on the
standard Istio metric configuration.  It also makes Kubernetes API calls to
obtain additional details about your services. For the best experience using
Kiali, use the metadata labels `app` and `version` on your application
components. As a template, the Bookinfo sample application follows this
convention.

## Cleanup

If you are not planning any follow-up tasks, remove the Bookinfo sample application and Kiali from your cluster.

1. To remove the Bookinfo application, refer to the [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions.

1. To remove Kiali from a Kubernetes environment, remove all components with the `app=kiali` label:

{{< text bash >}}
$ kubectl delete all,secrets,sa,configmaps,deployments,ingresses,clusterroles,clusterrolebindings,virtualservices,destinationrules --selector=app=kiali -n istio-system
{{< /text >}}

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

The [Bookinfo](/docs/examples/bookinfo/) sample application is used as the
example application throughout this task.

## Before you begin

You first need to create a secret in your Istio namespace with credentials that
you will use to authenticate to Kiali. See the
[Helm README](https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/README.md#installing-the-chart)
for details, but here is an example command you can modify and run to create a
secret:

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

Once you have created a Kiali secret, you can install Kiali via Helm by following
[these instructions](/docs/setup/kubernetes/helm-install/). Note that you need
to use the `--set kiali.enabled=true` option when running the `helm` command.

For example:

{{< text bash >}}
$ helm template --set kiali.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
$ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

> {{< idea_icon >}} This Task will not discuss Jaeger and Grafana; however, if
you have them already installed in your cluster and you want to see how Kiali
integrates with both of them, you will want to pass additional arguments to the
`helm` command above, for example:

{{< text bash >}}
$ helm template \
    --set kiali.enabled=true \
    --set "kiali.dashboard.jaegerURL=http://$(kubectl get svc tracing -o jsonpath='{.spec.clusterIP}'):80" \
    --set "kiali.dashboard.grafanaURL=http://$(kubectl get svc grafana -o jsonpath='{.spec.clusterIP}'):3000" \
    install/kubernetes/helm/istio \
    --name istio --namespace istio-system > $HOME/istio.yaml
$ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

Once Istio and Kiali are installed, deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

> {{< idea_icon >}} The above installation instructions assume you have `helm`
and want to use it to install Kiali. Alternatively, you can install Kiali by
following the [Kiali install instructions](https://www.kiali.io/gettingstarted/).

## Generating a service graph

1.  Verify that the service is running in your cluster.

    In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    NAME           CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    kiali          10.59.253.165   <none>        20001/TCP  30s
    {{< /text >}}

1.  Determine the Bookinfo URL.

    Follow these [instructions](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port)
    to determine the Bookinfo `GATEWAY_URL`.

1.  Send traffic to the mesh.

    Generate a small amount of traffic by visiting `http://$GATEWAY_URL/productpage`
    in your web browser or by issuing the following command multiple times:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    {{< idea_icon >}} To continually send requests, you can use the
    `watch` command if it is available on your system:

    {{< text bash >}}
    $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
    {{< /text >}}

1.  Determine the Kiali URL.

    Kiali is exposed through the same Istio gateway as the Bookinfo
    application, only on a different port. Therefore you can use the
    `GATEWAY_URL` that you set in the previous step to determine the Kiali URL.

    If you are running in an environment that has external load balancers:

    {{< text bash >}}
    $ KIALI_URL="http://$(echo $GATEWAY_URL | sed -e s/:.*//):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http-kiali")].port}')"
    $ echo $KIALI_URL
    http://172.30.141.9:15029
    {{< /text >}}

    If you are running in an environment that does not support external load balancers (e.g., minikube):

    {{< text bash >}}
    $ KIALI_URL="http://$(echo $GATEWAY_URL | sed -e s/:.*//):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http-kiali")].nodePort}')"
    $ echo $KIALI_URL
    http://192.168.99.100:31758
    {{< /text >}}

1.  Log into the Kiali UI.

    Visit `$KIALI_URL` in your web browser, and in the login screen enter the
    credentials that you stored in the Kiali secret you created above. If you
    used the example secret above, you should enter a username of `admin` with
    a password of `mysecret`.

1.  Get an overview of your mesh.

    Once you log in, you will initially be brought to the **Overview** page
    showing you all the namespaces which have services in your mesh. The page
    will look similar to:

    {{< image width="75%" ratio="58%"
    link="./kiali-overview.png"
    caption="Example Overview"
    >}}

1.  View a namespace graph.

    Click on a namespace to see a graph of all services in that namespace.  For
    example, if you have the Bookinfo sample application installed, click on
    `bookinfo` in the Bookinfo namespace card.  You will see a graph similar
    to:

    {{< image width="75%" ratio="89%"
    link="./kiali-graph.png"
    caption="Example Graph"
    >}}

1.  View summary metrics.

    Select any node or edge in the graph and notice the summary details panel
    on the right will display additional data about that selected node or edge.

1.  Experiment with different graph types.

    You can visualize the graph using several different types of graphs such as
    the **App**, **Versioned App**, and **Workload** graph types.

    1. Select the **App** graph type from the **Graph Type** drop down menu.
    This aggregates all versions of an app into a single graph node. For
    example, the single **reviews** node represents the three versions of the
    reviews app.
    {{< image width="75%" ratio="35%"
    link="./kiali-app.png"
    caption="Example App Graph"
    >}}

    1. Select the **Versioned App** graph type from the **Graph Type** drop
    down menu. This shows a node for each version of an app, but all versions
    of a particular app are grouped together. For example, the **reviews**
    group box that contains the three nodes represents the three versions of
    the reviews app.
    {{< image width="75%" ratio="67%"
    link="./kiali-versionedapp.png"
    caption="Example Versioned App Graph"
    >}}

    1. Select the **Workload** graph type from the **Graph Type** drop down
    menu.  This shows a node for each workload in your service mesh. This graph
    type does not require you to use the `app` and `version` labels so if
    you opt to not use those labels on your components, this is the graph type
    you will use.
    {{< image width="70%" ratio="76%"
    link="./kiali-workload.png"
    caption="Example Workload Graph"
    >}}

1. Examine details about the Istio configuration.

   Click on the **Applications**, **Workloads**, and **Services** menu icons on the
   left menu bar to examine the different components in your mesh. Drill down
   into those components to see additional details about those components, such
   as the Istio Virtual Services and Destination Rules.

   {{< image width="80%" ratio="56%"
   link="./kiali-services.png"
   caption="Example Details"
   >}}

## About the Kiali Public API

You can generate JSON representing the graphs, as well as other metric, health,
and configuration information, by accessing the
[Kiali Public API](https://www.kiali.io/api/paths).

For example, if you make a request to
`$KIALI_URL/api/namespaces/bookinfo/graph?graphType=app` you will get a JSON
representation of your graph:

{{< text json >}}
{
  "timestamp": 1538417408,
  "graphType": "app",
  "elements": {
    "nodes": [
      {
        "data": {
          "id": "35533a08d948509abf8ae4d5d5647594",
          "nodeType": "service",
          "namespace": "bookinfo",
          "service": "details",
          "destServices": {
            "details": true
          },
          "rate": "0.343",
          "rate5XX": "0.343",
          "hasVS": true
        }
      },
      {
        "data": {
          "id": "6cdb3cf3ee9a17772f13b295368e112a",
          "nodeType": "app",
          "namespace": "bookinfo",
          "app": "details",
          "destServices": {
            "details": true
          },
          "rate": "0.324",
          "hasVS": true
        }
      },
      {
        "data": {
          "id": "e96058d658030da2171c18d09086ee77",
          "nodeType": "app",
          "namespace": "bookinfo",
          "app": "mongodb",
          "destServices": {
            "mongodb": true
          },
          "rateTcpSent": "94.452"
        }
      },
      {
        "data": {
          "id": "2c22af42b0c750749399ed2838c56054",
          "nodeType": "app",
          "namespace": "bookinfo",
          "app": "productpage",
          "destServices": {
            "productpage": true
          },
          "rate": "0.667",
          "rateOut": "1.334"
        }
      },
      {
        "data": {
          "id": "c219903556c3afdb05eda7e610aba628",
          "nodeType": "app",
          "namespace": "bookinfo",
          "app": "ratings",
          "destServices": {
            "ratings": true
          },
          "rate": "0.442",
          "rateTcpSentOut": "94.452"
        }
      },
      {
        "data": {
          "id": "37ddc91db761d432f3fff1943802cad7",
          "nodeType": "app",
          "namespace": "bookinfo",
          "app": "reviews",
          "destServices": {
            "reviews": true
          },
          "rate": "0.667",
          "rateOut": "0.442"
        }
      },
      {
        "data": {
          "id": "b30b0078325bf2e1adb4d57c4c0c2665",
          "nodeType": "unknown",
          "namespace": "unknown",
          "workload": "unknown",
          "app": "unknown",
          "version": "unknown",
          "rateOut": "0.667",
          "isRoot": true
        }
      }
    ],
    "edges": [
      {
        "data": {
          "id": "36835c5c95ccd1ec98f91cab3577e9f5",
          "source": "2c22af42b0c750749399ed2838c56054",
          "target": "35533a08d948509abf8ae4d5d5647594",
          "rate": "0.343",
          "rate5XX": "0.343",
          "percentErr": "100.000",
          "percentRate": "25.712",
          "responseTime": "0.000"
        }
      },
      {
        "data": {
          "id": "ff5217a9064e30e4fb875256dab56037",
          "source": "2c22af42b0c750749399ed2838c56054",
          "target": "37ddc91db761d432f3fff1943802cad7",
          "rate": "0.667",
          "percentRate": "50.000",
          "responseTime": "0.052"
        }
      },
      {
        "data": {
          "id": "89fa162a49acca6ff974afd30aab2ff0",
          "source": "2c22af42b0c750749399ed2838c56054",
          "target": "6cdb3cf3ee9a17772f13b295368e112a",
          "rate": "0.324",
          "percentRate": "24.288",
          "responseTime": "0.005"
        }
      },
      {
        "data": {
          "id": "a553e38605904d17c50ab1d0db84f113",
          "source": "37ddc91db761d432f3fff1943802cad7",
          "target": "c219903556c3afdb05eda7e610aba628",
          "rate": "0.442",
          "responseTime": "0.030"
        }
      },
      {
        "data": {
          "id": "efe83e483ada36899c34ef66a7974d31",
          "source": "b30b0078325bf2e1adb4d57c4c0c2665",
          "target": "2c22af42b0c750749399ed2838c56054",
          "rate": "0.667",
          "responseTime": "0.038"
        }
      },
      {
        "data": {
          "id": "06d772ed417cd829b4b6f95a209ed1b5",
          "source": "c219903556c3afdb05eda7e610aba628",
          "target": "e96058d658030da2171c18d09086ee77",
          "tcpSentRate": "94.452"
        }
      }
    ]
  }
}
{{< /text >}}

The Kiali Public API is built on top of Prometheus queries and depends on the
standard Istio metric configuration.  It also makes Kubernetes API calls to
obtain additional details about your services.  For the best experience using
Kiali, you should use the metadata labels `app` and `version` on your
application components (the Bookinfo sample application follows this
convention).

## Cleanup

If you are not planning to explore any follow-on tasks, you can remove the
Bookinfo sample application and Kiali.

To remove the Bookinfo application, refer to the [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions.

To remove Kiali from a Kubernetes environment, remove all components with the `app=kiali` label:

{{< text bash >}}
$ kubectl delete all,secrets,sa,configmaps,deployments,ingresses,clusterroles,clusterrolebindings,virtualservices,destinationrules --selector=app=kiali -n istio-system
{{< /text >}}

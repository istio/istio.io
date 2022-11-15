---
title: Visualizing Your Mesh
description: This task shows you how to visualize your services within an Istio mesh.
weight: 49
keywords: [telemetry,visualization]
aliases:
 - /docs/tasks/telemetry/kiali/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

This task shows you how to visualize different aspects of your Istio mesh.

As part of this task, you install the [Kiali](https://www.kiali.io) addon
and use the web-based graphical user interface to view service graphs of
the mesh and your Istio configuration objects.

{{< idea >}}
This task does not cover all of the features provided by Kiali.
To learn about the full set of features it supports,
see the [Kiali website](https://kiali.io/docs/features/).
{{< /idea >}}

This task uses the [Bookinfo](/docs/examples/bookinfo/) sample application as the example throughout. This task
assumes the Bookinfo application is installed in the `bookinfo` namespace.

## Before you begin

Follow the [Kiali installation](/docs/ops/integrations/kiali/#installation) documentation to deploy Kiali into your cluster.

## Generating a graph

1.  To verify the service is running in your cluster, run the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    {{< /text >}}

1.  To determine the Bookinfo URL, follow the instructions to determine the [Bookinfo ingress `GATEWAY_URL`](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

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

1.  To open the Kiali UI, execute the following command in your Kubernetes environment:

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  View the overview of your mesh in the **Overview** page that appears immediately after you log in.
    The **Overview** page displays all the namespaces that have services in your mesh.
    The following screenshot shows a similar page:

    {{< image width="75%" link="./kiali-overview.png" caption="Example Overview" >}}

1.  To view a namespace graph, Select the `Graph` option in the kebab menu of the Bookinfo overview card. The kebab menu
    is at the top right of card and looks like 3 vertical dots. Click it to see the available options.
    The page looks similar to:

    {{< image width="75%" link="./kiali-graph.png" caption="Example Graph" >}}

1.  The graph represents traffic flowing through the service mesh for a period of time. It is generated using
    Istio telemetry.

1.  To view a summary of metrics, select any node or edge in the graph to display
    its metric details in the summary details panel on the right.

1.  To view your service mesh using different graph types, select a graph type
    from the **Graph Type** drop down menu. There are several graph types
    to choose from: **App**, **Versioned App**, **Workload**, **Service**.

    *   The **App** graph type aggregates all versions of an app into a single graph node.
        The following example shows a single **reviews** node representing the three versions
        of the reviews app. Note that the `Show Service Nodes` Display option has been disabled.

        {{< image width="75%" link="./kiali-app.png" caption="Example App Graph" >}}

    *   The **Versioned App** graph type shows a node for each version of an app,
        but all versions of a particular app are grouped together. The following example
        shows the **reviews** group box that contains the three nodes that represents the
        three versions of the reviews app.

        {{< image width="75%" link="./kiali-versionedapp.png" caption="Example Versioned App Graph" >}}

    *   The **Workload** graph type shows a node for each workload in your service mesh.
        This graph type does not require you to use the `app` and `version` labels so if you
        opt to not use those labels on your components, this may be your graph type of choice.

        {{< image width="70%" link="./kiali-workload.png" caption="Example Workload Graph" >}}

    *   The **Service** graph type shows a high-level aggregation of service traffic in your mesh.

        {{< image width="70%" link="./kiali-service-graph.png" caption="Example Service Graph" >}}

## Examining Istio configuration

1.  The left menu options lead to list views for **Applications**, **Workloads**, **Services** and
    **Istio Config**.
    The following screenshot shows **Services** information for the Bookinfo namespace:

    {{< image width="80%" link="./kiali-services.png" caption="Example Details" >}}

## Traffic Shifting

You can use the Kiali traffic shifting wizard to define the specific percentage of
request traffic to route to two or more workloads.

1.  View the **Versioned app graph** of the `bookinfo` graph.

    *   Make sure you have enabled the **Traffic Distribution** Edge Label **Display** option to see
        the percentage of traffic routed to each workload.

    *   Make sure you have enabled the Show **Service Nodes** **Display** option
        to view the service nodes in the graph.

    {{< image width="80%" link="./kiali-wiz0-graph-options.png" caption="Bookinfo Graph Options" >}}

1.  Focus on the `ratings` service within the `bookinfo` graph by clicking on the `ratings` service (triangle) node.
    Notice the `ratings` service traffic is evenly distributed to the two `ratings` workloads `v1` and `v2`
    (50% of requests are routed to each workload).

    {{< image width="80%" link="./kiali-wiz1-graph-ratings-percent.png" caption="Graph Showing Percentage of Traffic" >}}

1.  Click the **ratings** link found in the side panel to go to the detail view for the `ratings` service.  This
    could also be done by secondary-click on the `ratings` service node, and selecting `Details` from the context menu.

1.  From the **Actions** drop down menu, select **Traffic Shifting** to access the traffic shifting wizard.

    {{< image width="80%" link="./kiali-wiz2-ratings-service-action-menu.png" caption="Service Actions Menu" >}}

1.  Drag the sliders to specify the percentage of traffic to route to each workload.
    For `ratings-v1`, set it to 10%; for `ratings-v2` set it to 90%.

    {{< image width="80%" link="./kiali-wiz3-traffic-shifting-wizard.png" caption="Weighted Routing Wizard" >}}

1.  Click the **Preview** button to view the YAML that will be generated by the wizard.

    {{< image width="80%" link="./kiali-wiz3b-traffic-shifting-wizard-preview.png" caption="Routing Wizard Preview" >}}

1.  Click the **Create** button and confirm to apply the new traffic settings.

1.  Click **Graph** in the left hand navigation bar to return to the `bookinfo` graph.  Notice that the
    `ratings` service node is now badged with the `virtual service` icon.

1.  Send requests to the `bookinfo` application. For example, to send one request per second,
    you can execute this command if you have `watch` installed on your system:

    {{< text bash >}}
    $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
    {{< /text >}}

1.  After a few minutes you will notice that the traffic percentage will reflect the new traffic route,
    thus confirming the fact that your new traffic route is successfully routing 90% of all traffic
    requests to `ratings-v2`.

    {{< image width="80%" link="./kiali-wiz4-traffic-shifting-90-10.png" caption="90% Ratings Traffic Routed to ratings-v2" >}}

## Validating Istio configuration

Kiali can validate your Istio resources to ensure they follow proper conventions and semantics. Any problems detected in the configuration of your Istio resources can be flagged as errors or warnings depending on the severity of the incorrect configuration. See the [Kiali validations page](https://kiali.io/docs/features/validations/) for the list of all validation checks Kiali performs.

{{< idea >}}
Istio provides `istioctl analyze` which provides analysis in a way that can be used in a CI pipeline. The two approaches can be complementary.
{{< /idea >}}

Force an invalid configuration of a service port name to see how Kiali reports a validation error.

1.  Change the port name of the `details` service from `http` to `foo`:

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"foo"}]'
    {{< /text >}}

1.  Navigate to the **Services** list by clicking **Services** on the left hand navigation bar.

1.  Select `bookinfo` from the **Namespace** drop down menu if it is not already selected.

1.  Notice the error icon displayed in the **Configuration** column of the `details` row.

    {{< image width="80%" link="./kiali-validate1-list.png" caption="Services List Showing Invalid Configuration" >}}

1.  Click the **details** link in the **Name** column to navigate to the service details view.

1.  Hover over the error icon to display a tool tip describing the error.

    {{< image width="80%" link="./kiali-validate2-errormsg.png" caption="Service Details Describing the Invalid Configuration" >}}

1.  Change the port name back to `http` to correct the configuration and return `bookinfo` back to its normal state.

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"http"}]'
    {{< /text >}}

    {{< image width="80%" link="./kiali-validate3-ok.png" caption="Service Details Showing Valid Configuration" >}}

## Viewing and editing Istio configuration YAML

Kiali provides a YAML editor for viewing and editing Istio configuration resources. The YAML editor will also provide validation messages when it detects incorrect configurations.

1.  Introduce an error in the `bookinfo` VirtualService

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway-invalid"}]'
    {{< /text >}}

1.  Click `Istio Config` on the left hand navigation bar to navigate to the Istio configuration list.

1.  Select `bookinfo` from the **Namespace** drop down menu if it is not already selected.

1.  Notice the error icon that alerts you to a configuration problem.

    {{< image width="80%" link="./kiali-istioconfig0-errormsgs.png" caption="Istio Config List Incorrect Configuration" >}}

1.  Click the error icon in the **Configuration** column of the `bookinfo` row to navigate to the `bookinfo` virtual service view.

1.  The **YAML** tab is preselected. Notice the color highlights and icons on the rows that have validation check notifications associated with them.

    {{< image width="80%" link="./kiali-istioconfig3-details-yaml1.png" caption="YAML Editor Showing Validation Notifications" >}}

1.  Hover over the red icon to view the tool tip message that informs you of the validation check that triggered the error.
    For more details on the cause of the error and how to resolve it, look up the validation error message on the [Kiali Validations page](https://kiali.io/docs/features/validations/).

    {{< image width="80%" link="./kiali-istioconfig3-details-yaml3.png" caption="YAML Editor Showing Error Tool Tip" >}}

1.  Reset the virtual service `bookinfo` back to its original state.

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway"}]'
    {{< /text >}}

## Additional Features

Kiali has many more features than reviewed in this task, such as an [integration with Jaeger tracing](https://kiali.io/docs/features/tracing/).

For more details on these additional features, see the [Kiali documentation](https://kiali.io/docs/features/).

For a deeper exploration of Kiali it is recommended to run through the [Kiali Tutorial](https://kiali.io/docs/tutorials/).

## Cleanup

If you are not planning any follow-up tasks, remove the Bookinfo sample application and Kiali from your cluster.

1. To remove the Bookinfo application, refer to the [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions.

1. To remove Kiali from a Kubernetes environment:

{{< text bash >}}
$ kubectl delete -f {{< github_file >}}/samples/addons/kiali.yaml
{{< /text >}}

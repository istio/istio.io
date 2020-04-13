---
title: Grafana
description: Information on how to integrate with Grafana to set up Istio dashboards.
weight: 20
keywords: [integration,grafana]
---

[Grafana](https://grafana.com/) is an open source monitoring solution that can be used to configure dashboards for Istio. This allows monitoring the health of Istio itself, as well as of applications within the mesh.

## Configuration

While you can build your own dashboards, Istio offers a set of preconfigured dashboards for all of the most important metrics in the mesh.

* [Mesh Dashboard](https://grafana.com/grafana/dashboards/7639) provides an overview of all services in the mesh.
* [Service Dashboard](https://grafana.com/grafana/dashboards/7636) provides a detailed breakdown of metrics for a service.
* [Workload Dashboard](https://grafana.com/grafana/dashboards/7630) provides a detailed breakdown of metrics for a workload.
* [Performance Dashboard](https://grafana.com/grafana/dashboards/11829) monitors the resource usage of the mesh.
* [Control Plane Dashboard](https://grafana.com/grafana/dashboards/7645) monitors the health and performance of the control plane.

There are a few ways to configure Grafana to use these dashboards:

### Use the built in Grafana deployment

To deploy the built in Grafana, follow the [Install Guide](/docs/setup/install/istioctl/) and pass `--set values.grafana.enabled` during installation.

This is intended for new users quickly getting started, but does not offer advanced customization like persistence or authentication. However, it comes bundled with all of the Istio dashboards already installed.

### Import from `grafana.com`

Using the links above, you can quickly import these dashboards to your Grafana instance. This can be done through the [`Import` button in the UI](https://grafana.com/docs/grafana/latest/reference/export_import/#importing-a-dashboard). Please note you will need to select a Prometheus data source to use when importing.

This can also be done through a script to import all dashboards at once. For example:

{{< text plain >}}
# Address of grafana
GRAFANA_HOST="http://localhost:3000"
# Login credentials, if authentication is used
GRAFANA_CRED="USER:PASSWORD"
# The name of the prometheus data source to use
GRAFANA_DATASOURCE="Prometheus"
# The version of Istio we are deploying
VERSION={{< istio_version >}}
# Import all Istio dashboards
for DASHBOARD in 7639 11829 7636 7630 7642 7645; do
    REVISION="$(curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions -s | jq ".items[] | select(.description | contains(\"${VERSION}\")) | .revision")"
    curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions/${REVISION}/download > /tmp/dashboard.json
    echo "Importing $(cat /tmp/dashboard.json | jq -r '.title') (revision ${REVISION}, id ${DASHBOARD})..."
    curl -s -k -u "$GRAFANA_CRED" -XPOST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "{\"dashboard\":$(cat /tmp/dashboard.json),\"overwrite\":true, \
            \"inputs\":[{\"name\":\"DS_PROMETHEUS\",\"type\":\"datasource\", \
            \"pluginId\":\"prometheus\",\"value\":\"$GRAFANA_DATASOURCE\"}]}" \
        $GRAFANA_HOST/api/dashboards/import
    echo -e "\nDone\n"
done
{{< /text >}}

Please note that there will be a new revision of the dashboard for each version of Istio. It is recommended that you select the appropriate revision to ensure compatibility.

### Implementation specific methods

There are many ways to install and configure Grafana which all have different ways to configure dashboards. To use these, please refer to the documentation of the installation method you have chosen. For example:

* [Grafana provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards) official documentation.
* [Importing dashboards](https://github.com/helm/charts/tree/master/stable/grafana#import-dashboards) for the `stable/grafana` Helm chart.

---
title: Grafana
description: Information on how to integrate with Grafana to set up Istio dashboards.
weight: 27
keywords: [integration,grafana]
owner: istio/wg-environments-maintainers
test: no
---

[Grafana](https://grafana.com/) is an open source monitoring solution that can be
used to configure dashboards for Istio. You can use Grafana to monitor the health
of Istio and of applications within the service mesh.

## Configuration

While you can build your own dashboards, Istio offers a set of preconfigured dashboards
for all of the most important metrics for the mesh and for the control plane.

* [Mesh Dashboard](https://grafana.com/grafana/dashboards/7639) provides an overview of all services in the mesh.
* [Service Dashboard](https://grafana.com/grafana/dashboards/7636) provides a detailed breakdown of metrics for a service.
* [Workload Dashboard](https://grafana.com/grafana/dashboards/7630) provides a detailed breakdown of metrics for a workload.
* [Performance Dashboard](https://grafana.com/grafana/dashboards/11829) monitors the resource usage of the mesh.
* [Control Plane Dashboard](https://grafana.com/grafana/dashboards/7645) monitors the health and performance of the control plane.
* [WASM Extension Dashboard](https://grafana.com/grafana/dashboards/13277) provides an overview of mesh wide WebAssembly extension runtime and loading state.

There are a few ways to configure Grafana to use these dashboards:

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Grafana up and running,
bundled with all of the Istio dashboards already installed:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/grafana.yaml
{{< /text >}}

This will deploy Grafana into your cluster. This is intended for demonstration only,
and is not tuned for performance or security.

### Option 2: Import from `grafana.com` into an existing deployment

To quickly import the Istio dashboards to an existing Grafana instance, you can use the
[**Import** button in the Grafana UI](https://grafana.com/docs/grafana/latest/reference/export_import/#importing-a-dashboard)
to add the dashboard links above. When you import the dashboards, note that you must select a Prometheus data source.

You can also use a script to import all dashboards at once. For example:

{{< text bash >}}
$ # Address of Grafana
$ GRAFANA_HOST="http://localhost:3000"
$ # Login credentials, if authentication is used
$ GRAFANA_CRED="USER:PASSWORD"
$ # The name of the Prometheus data source to use
$ GRAFANA_DATASOURCE="Prometheus"
$ # The version of Istio to deploy
$ VERSION={{< istio_full_version >}}
$ # Import all Istio dashboards
$ for DASHBOARD in 7639 11829 7636 7630 7645 13277; do
$     REVISION="$(curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions -s | jq ".items[] | select(.description | contains(\"${VERSION}\")) | .revision")"
$     curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions/${REVISION}/download > /tmp/dashboard.json
$     echo "Importing $(cat /tmp/dashboard.json | jq -r '.title') (revision ${REVISION}, id ${DASHBOARD})..."
$     curl -s -k -u "$GRAFANA_CRED" -XPOST \
$         -H "Accept: application/json" \
$         -H "Content-Type: application/json" \
$         -d "{\"dashboard\":$(cat /tmp/dashboard.json),\"overwrite\":true, \
$             \"inputs\":[{\"name\":\"DS_PROMETHEUS\",\"type\":\"datasource\", \
$             \"pluginId\":\"prometheus\",\"value\":\"$GRAFANA_DATASOURCE\"}]}" \
$         $GRAFANA_HOST/api/dashboards/import
$     echo -e "\nDone\n"
$ done
{{< /text >}}

{{< tip >}}
A new revision of the dashboards is created for each version of Istio. To ensure compatibility,
it is recommended that you select the appropriate revision for the Istio version you are deploying.
{{< /tip >}}

### Option 3: Implementation-specific methods

Grafana can be installed and configured through other methods. To import Istio dashboards,
refer to the documentation for the installation method. For example:

* [Grafana provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards) official documentation.
* [Importing dashboards](https://github.com/helm/charts/tree/master/stable/grafana#import-dashboards) for the `stable/grafana` Helm chart.

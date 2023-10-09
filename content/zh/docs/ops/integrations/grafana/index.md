---
title: Grafana
description: 关于如何与 Grafana 集成构建 Istio 仪表盘的相关文档。
weight: 27
keywords: [integration,grafana]
owner: istio/wg-environments-maintainers
test: no
---

[Grafana](https://grafana.com/) 是一个开源的监控解决方案，可以用来为 Istio
配置仪表板。您可以使用 Grafana 来监控 Istio 及部署在服务网格内的应用程序。

## 配置 {#config}

尽管可以构建自己的仪表板，但 Istio 同时也提供了一组预先配置的仪表板用来监视网格和控制平面的所有最重要的指标。

* [Mesh Dashboard](https://grafana.com/grafana/dashboards/7639) 为运行在网格中的所有服务提供概览视图。
* [Service Dashboard](https://grafana.com/grafana/dashboards/7636) 为服务提供详细的分类指标。
* [Workload Dashboard](https://grafana.com/grafana/dashboards/7630) 为负载提供详细的分类指标。
* [Performance Dashboard](https://grafana.com/grafana/dashboards/11829) 监控网格资源使用情况。
* [Control Plane Dashboard](https://grafana.com/grafana/dashboards/7645) 监控控制面的健康状况及性能指标.
* [WASM Extension Dashboard](https://grafana.com/grafana/dashboards/13277) 提供了网格范围的 WebAssembly 扩展运行时和加载状态的概述。

可以通过多种方法来配置 Grafana 来使用这些仪表板：

### 方法1：快速开始 {#option-1-quick-start}

Istio 提供了一个基本的安装示例，以快速让 Grafana 启动和运行，
与所有已经安装的 Istio 仪表板捆绑在一起：

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/grafana.yaml
{{< /text >}}

通过 kubectl apply 方式将 Grafana 部署到集群中。该策略仅用于演示，
并没有针对性能或安全性进行调优。

### 方法2：从 `grafana.com` 导入已经部署的 Deployment {#option-2-import-from-grafanacom-into-an-existing-deployment}

如果想要快速地将Istio仪表板导入到现有的Grafana实例中，您可以使用
[Grafana UI 中的 **Import** 按钮](https://grafana.com/docs/grafana/latest/reference/export_import/#importing-a-dashboard)
来添加上面的仪表板链接。当导入仪表板时，请注意必须选择一个 Prometheus 数据源。

也可以使用脚本一次导入所有仪表板。例如：

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
$     REVISION="$(curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions -s | jq ".items[] | select(.description | contains(\"${VERSION}$\")) | .revision")"
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

### 方法3：特定的实现方法 {#option-3-implementation-specific-methods}

Grafana 可以通过其他方法进行安装和配置。要导入 Istio 仪表板，
请参考文档中的安装方法。例如：

* [Grafana provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards) 官方文档。
* [Importing dashboards](https://github.com/helm/charts/tree/master/stable/grafana#import-dashboards)
  `stable/grafana` Helm chart 文档。

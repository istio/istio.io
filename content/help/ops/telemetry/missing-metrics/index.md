---
title: Missing Metrics
description: Diagnose problems where metrics are not being collected.
weight: 10
---

The procedures below help you diagnose problems where metrics
you are expecting to see reported and not being collected.

The expected flow for metrics is:

1. Envoy reports attributes from requests asynchronously to Mixer in a batch.

1. Mixer translates the attributes into instances based on the operator-provided configuration.

1. Mixer hands the instances to Mixer adapters for processing and backend storage.

1. The backend storage systems record the metrics data.

The Mixer default installations include a Prometheus adapter and the configuration to generate a [default set of metric values](/docs/reference/config/policy-and-telemetry/metrics/) and send them to the Prometheus adapter. The Prometheus adapter configuration enables a Prometheus instance to scrape Mixer for metrics.

If the Istio Dashboard or the Prometheus queries don’t show the expected metrics, any step of the flow above may present an issue. The following sections provide instructions to troubleshoot each step.

## Verify Mixer is receiving Report calls

Mixer generates metrics to monitor its own behavior. The first step is to check these metrics:

1. Establish a connection to the Mixer self-monitoring endpoint for the `istio-telemetry` deployment. In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward <istio-telemetry pod> 15014 &
    {{< /text >}}

1. Verify successful report calls. On the Mixer self-monitoring endpoint, search for `grpc_io_server_completed_rpcs`. You should see something like:

    {{< text plain >}}
    grpc_io_server_completed_rpcs{grpc_server_method="istio.mixer.v1.Mixer/Report",grpc_server_status="OK"} 2532
    {{< /text >}}

    If you do not see any data for `grpc_io_server_completed_rpcs` with a `grpc_server_method="istio.mixer.v1.Mixer/Report"`, then Envoy is not calling Mixer to report telemetry.

1. In this case, ensure you integrated the services properly into the mesh. You can achieve this task with either [automatic or manual sidecar injection](/docs/setup/kubernetes/additional-setup/sidecar-injection/).

## Verify the Mixer rules exist

In Kubernetes environments, issue the following command:

{{< text bash >}}
$ kubectl get rules --all-namespaces
NAMESPACE      NAME                      AGE
istio-system   kubeattrgenrulerule       4h
istio-system   promhttp                  4h
istio-system   promtcp                   4h
istio-system   promtcpconnectionclosed   4h
istio-system   promtcpconnectionopen     4h
istio-system   tcpkubeattrgenrulerule    4h
{{< /text >}}

If the output shows no rules named `promhttp` or `promtcp`, then the Mixer configuration for sending metric instances to the Prometheus adapter is missing. You must supply the configuration for rules connecting the Mixer metric instances to a Prometheus handler.

For reference, please consult the [default rules for Prometheus]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml).

## Verify the Prometheus handler configuration exists

1. In Kubernetes environments, issue the following command:

    {{< text bash >}}
    $ kubectl get prometheuses.config.istio.io --all-namespaces
    NAMESPACE      NAME      AGE
    istio-system   handler   13d
    {{< /text >}}

    Depending on whether or not your install of Istio was a fresh install or upgrade, you may also need to issue the following command:

    {{< text bash >}}
    $ kubectl get handlers.config.istio.io --all-namespaces
    NAMESPACE      NAME            AGE
    istio-system   kubernetesenv   4h
    istio-system   prometheus      4h
    {{< /text >}}

1. If the output shows no configured Prometheus handlers, you must reconfigure Mixer with the appropriate handler configuration.

    For reference, please consult the [default handler configuration for Prometheus]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml).

## Verify Mixer metric instances configuration exists

1. In Kubernetes environments, issue the following command:

    {{< text bash >}}
    $ kubectl get metrics.config.istio.io --all-namespaces
    NAMESPACE      NAME                   AGE
    istio-system   requestcount           4h
    istio-system   requestduration        4h
    istio-system   requestsize            4h
    istio-system   responsesize           4h
    istio-system   tcpbytereceived        4h
    istio-system   tcpbytesent            4h
    istio-system   tcpconnectionsclosed   4h
    istio-system   tcpconnectionsopened   4h
    {{< /text >}}

1. If the output shows no configured metric instances, you must reconfigure Mixer with the appropriate instance configuration.

    For reference, please consult the [default instances configuration for metrics]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml).

## Verify there are no known configuration errors

1. To establish a connection to the Istio-telemetry self-monitoring endpoint, setup a port-forward to the Istio-telemetry self-monitoring port as described in
[Verify Mixer is receiving Report calls](#verify-mixer-is-receiving-report-calls).

1. For each of the following metrics, verify that the most up-to-date value is 0:

    * `mixer_config_adapter_info_config_errors_total`

    * `mixer_config_template_config_errors_total`

    * `mixer_config_instance_config_errors_total`

    * `mixer_config_rule_config_errors_total`

    * `mixer_config_rule_config_match_error_total`

    * `mixer_config_unsatisfied_action_handler_total`

    * `mixer_config_handler_validation_error_total`

    * `mixer_handler_handler_build_failures_total`

On the page showing Mixer self-monitoring port, search for each of the metrics listed above. You should not find any values for those metrics if everything is
configured correctly.

If any of those metrics have a value, confirm that the metric value with the largest configuration ID is 0. This will verify that Mixer has generated no errors
in processing the most recent configuration as supplied.

## Verify Mixer is sending metric instances to the Prometheus adapter

1. Establish a connection to the `istio-telemetry` self-monitoring endpoint. Setup a port-forward to the `istio-telemetry` self-monitoring port as described in
[Verify Mixer is receiving Report calls](#verify-mixer-is-receiving-report-calls).

1. On the Mixer self-monitoring port, search for `mixer_runtime_dispatches_total`. The output should be similar to:

    {{< text plain >}}
    mixer_runtime_dispatches_total{adapter="prometheus",error="false",handler="prometheus.istio-system",meshFunction="metric"} 2532
    {{< /text >}}

1. Confirm that `mixer_runtime_dispatches_total` is present with the values:

    {{< text plain >}}
    adapter="prometheus"
    error="false"
    {{< /text >}}

    If you can’t find recorded dispatches to the Prometheus adapter, there is likely a configuration issue. Please follow the steps above
    to ensure everything is configured properly.

    If the dispatches to the Prometheus adapter report errors, check the Mixer logs to determine the source of the error. The most likely cause is a configuration issue for the handler listed in `mixer_runtime_dispatches_total`.

1. Check the Mixer logs in a Kubernetes environment with:

    {{< text bash >}}
    $ kubectl -n istio-system logs <istio-telemetry pod> -c mixer
    {{< /text >}}

## Verify Prometheus configuration

1. Connect to the Prometheus UI

1. Verify you can successfully scrape Mixer through the UI.

1. In Kubernetes environments, setup port-forwarding with:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

1. Visit `http://localhost:9090/targets`

1. Confirm the target `istio-mesh` has a status of UP.

1. Visit `http://localhost:9090/config`

1. Confirm an entry exists similar to:

    {{< text plain >}}
    - job_name: 'istio-mesh'
    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
    - targets: ['istio-mixer.istio-system:42422']</td>
    {{< /text >}}

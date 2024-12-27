---
title: Install with istioctl
description: Install Istio with support for ambient mode using the istioctl command line tool.
weight: 10
keywords: [istioctl,ambient]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
Follow this guide to install and configure an Istio mesh with support for ambient mode.
If you are new to Istio, and just want to try it out, follow the
[quick start instructions](/docs/ambient/getting-started) instead.
{{< /tip >}}

This installation guide uses the [istioctl](/docs/reference/commands/istioctl/) command-line
tool. `istioctl`, like other installation methods, exposes many customization options. Additionally,
it offers has user input validation to help prevent installation errors, and includes many
post-installation analysis and configuration tools.

Using these instructions, you can select any one of Istio's built-in
[configuration profiles](/docs/setup/additional-setup/config-profiles/)
and then further customize the configuration for your specific needs.

The `istioctl` command supports the full [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/)
via command-line options for individual settings, or passing a YAML file containing an `IstioOperator`
{{<gloss CRDs>}}custom resource{{</gloss>}}.

## Prerequisites

Before you begin, check the following prerequisites:

1. [Download the Istio release](/docs/setup/additional-setup/download-istio-release/).
1. Perform any necessary [platform-specific setup](/docs/ambient/install/platform-prerequisites/).

## Install or upgrade the Kubernetes Gateway API CRDs

{{< boilerplate gateway-api-install-crds >}}

## Install Istio using the ambient profile

`istioctl` supports a number of [configuration profiles](/docs/setup/additional-setup/config-profiles/) that include different default options,
and can be customized for your production needs. Support for ambient mode is included in the `ambient` profile. Install Istio with the
following command:

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

This command installs the `ambient` profile on the cluster defined by your
Kubernetes configuration.

## Configure and modify profiles

Istio's installation API is documented in the [`IstioOperator` API reference](/docs/reference/config/istio.operator.v1alpha1/). You
can use the `--set` option to `istioctl install` to modify individual installation parameters, or specify your own configuration file with `-f`.

Full details on how to use and customize `istioctl` installations are available in [the sidecar installation documentation](/docs/setup/install/istioctl/).

## Uninstall Istio

To completely uninstall Istio from a cluster, run the following command:

{{< text syntax=bash snip_id=uninstall >}}
$ istioctl uninstall --purge -y
{{< /text >}}

{{< warning >}}
The optional `--purge` flag will remove all Istio resources, including cluster-scoped resources that may be shared with other Istio control planes.
{{< /warning >}}

Alternatively, to remove only a specific Istio control plane, run the following command:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall <your original installation options>
{{< /text >}}

The control plane namespace (e.g., `istio-system`) is not removed by default.
If no longer needed, use the following command to remove it:

{{< text syntax=bash snip_id=remove_namespace >}}
$ kubectl delete namespace istio-system
{{< /text >}}

## Generate a manifest before installation

You can generate the manifest before installing Istio using the `manifest generate`
sub-command.
For example, use the following command to generate a manifest for the `default` profile that can be installed with `kubectl`:

{{< text syntax=bash snip_id=none >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

The generated manifest can be used to inspect what exactly is installed as well as to track changes to the manifest over time. While the `IstioOperator` CR represents the full user configuration and is sufficient for tracking it, the output from `manifest generate` also captures possible changes in the underlying charts and therefore can be used to track the actual installed resources.

{{< tip >}}
Any additional flags or custom values overrides you would normally use for installation should also be supplied to the `istioctl manifest generate` command.
{{< /tip >}}

{{< warning >}}
If attempting to install and manage Istio using `istioctl manifest generate`, please note the following caveats:

1. The Istio namespace (`istio-system` by default) must be created manually.

1. Istio validation will not be enabled by default. Unlike `istioctl install`, the `manifest generate` command will
not create the `istiod-default-validator` validating webhook configuration unless `values.defaultRevision` is set:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

1. Resources may not be installed with the same sequencing of dependencies as
`istioctl install`.

1. This method is not tested as part of Istio releases.

1. While `istioctl install` will automatically detect environment specific settings from your Kubernetes context,
`manifest generate` cannot as it runs offline, which may lead to unexpected results. In particular, you must ensure
that you follow [these steps](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) if your
Kubernetes environment does not support third party service account tokens. It is recommended to append `--cluster-specific` to your `istio manifest generate` command to detect the target cluster's environment, which will embed those cluster-specific environment settings into the generated manifests. This requires network access to your running cluster.

1. `kubectl apply` of the generated manifest may show transient errors due to resources not being available in the
cluster in the correct order.

1. `istioctl install` automatically prunes any resources that should be removed when the configuration changes (e.g.
if you remove a gateway). This does not happen when you use `istio manifest generate` with `kubectl` and these
resources must be removed manually.

{{< /warning >}}

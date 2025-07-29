---
title: Install with Istioctl
description: Install and customize any Istio configuration profile for in-depth evaluation or production use.
weight: 10
keywords: [istioctl,kubernetes]
owner: istio/wg-environments-maintainers
test: no
---

Follow this guide to install and configure an Istio mesh for in-depth evaluation or production use.
If you are new to Istio, and just want to try it out, follow the
[quick start instructions](/es/docs/setup/getting-started) instead.

This installation guide uses the [istioctl](/es/docs/reference/commands/istioctl/) command line
tool to provide rich customization of the Istio control plane and of the sidecars for the Istio data plane.
It has user input validation to help prevent installation errors and customization options to
override any aspect of the configuration.

Using these instructions, you can select any one of Istio's built-in
[configuration profiles](/es/docs/setup/additional-setup/config-profiles/)
and then further customize the configuration for your specific needs.

The `istioctl` command supports the full [`IstioOperator` API](/es/docs/reference/config/istio.operator.v1alpha1/)
via command-line options for individual settings or for passing a yaml file containing an `IstioOperator`
{{<gloss CRDs>}}custom resource (CR){{</gloss>}}.

## Prerequisites

Before you begin, check the following prerequisites:

1. [Download the Istio release](/es/docs/setup/additional-setup/download-istio-release/).
1. Perform any necessary [platform-specific setup](/es/docs/setup/platform-setup/).
1. Check the [Requirements for Pods and Services](/es/docs/ops/deployment/application-requirements/).

## Install Istio using the default profile

The simplest option is to install the `default` Istio
[configuration profile](/es/docs/setup/additional-setup/config-profiles/)
using the following command:

{{< text bash >}}
$ istioctl install
{{< /text >}}

This command installs the `default` profile on the cluster defined by your
Kubernetes configuration. The `default` profile is a good starting point
for establishing a production environment, unlike the larger `demo` profile that
is intended for evaluating a broad set of Istio features.

Various settings can be configured to modify the installations. For example, to enable access logs:

{{< text bash >}}
$ istioctl install --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

{{< tip >}}
Many of the examples on this page and elsewhere in the documentation are written using `--set` to modify installation
parameters, rather than passing a configuration file with `-f`. This is done to make the examples more compact.
The two methods are equivalent, but `-f` is strongly recommended for production. The above command would be written as
follows using `-f`:

{{< text bash >}}
$ cat <<EOF > ./my-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
EOF
$ istioctl install -f my-config.yaml
{{< /text >}}

{{< /tip >}}

{{< tip >}}
The full API is documented in the [`IstioOperator` API reference](/es/docs/reference/config/istio.operator.v1alpha1/).
In general, you can use the `--set` flag in `istioctl` as you would with
Helm, and the Helm `values.yaml` API is currently supported for backwards compatibility. The only difference is you must
prefix the legacy `values.yaml` paths with `values.` because this is the prefix for the Helm pass-through API.
{{< /tip >}}

## Install from external charts

By default, `istioctl` uses compiled-in charts to generate the install manifest. These charts are released together with
`istioctl` for auditing and customization purposes and can be found in the release tar in the
`manifests` directory.
`istioctl` can also use external charts rather than the compiled-in ones. To select external charts, set
the `manifests` flag to a local file system path:

{{< text bash >}}
$ istioctl install --manifests=manifests/
{{< /text >}}

If using the `istioctl` {{< istio_full_version >}} binary, this command will result in the same installation as `istioctl install` alone, because it points to the
same charts as the compiled-in ones.
Other than for experimenting with or testing new features, we recommend using the compiled-in charts rather than external ones to ensure compatibility of the
`istioctl` binary with the charts.

## Install a different profile

Other Istio configuration profiles can be installed in a cluster by passing the
profile name on the command line. For example, the following command can be used
to install the `demo` profile:

{{< text bash >}}
$ istioctl install --set profile=demo
{{< /text >}}

## Generate a manifest before installation

You can generate the manifest before installing Istio using the `manifest generate`
sub-command.
For example, use the following command to generate a manifest for the `default` profile that can be installed with `kubectl`:

{{< text bash >}}
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

    {{< text bash >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

1. Resources may not be installed with the same sequencing of dependencies as
`istioctl install`.

1. This method is not tested as part of Istio releases.

1. While `istioctl install` will automatically detect environment specific settings from your Kubernetes context,
`manifest generate` cannot as it runs offline, which may lead to unexpected results. In particular, you must ensure
that you follow [these steps](/es/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) if your
Kubernetes environment does not support third party service account tokens. It is recommended to append `--cluster-specific` to your `istio manifest generate` command to detect the target cluster's environment, which will embed those cluster-specific environment settings into the generated manifests. This requires network access to your running cluster.

1. `kubectl apply` of the generated manifest may show transient errors due to resources not being available in the
cluster in the correct order.

1. `istioctl install` automatically prunes any resources that should be removed when the configuration changes (e.g.
if you remove a gateway). This does not happen when you use `istio manifest generate` with `kubectl` and these
resources must be removed manually.

{{< /warning >}}

See [Customizing the installation configuration](/es/docs/setup/additional-setup/customize-installation/) for additional information on customizing the install.

## Uninstall Istio

To completely uninstall Istio from a cluster, run the following command:

{{< text bash >}}
$ istioctl uninstall --purge
{{< /text >}}

{{< warning >}}
The optional `--purge` flag will remove all Istio resources, including cluster-scoped resources that may be shared with other Istio control planes.
{{< /warning >}}

Alternatively, to remove only a specific Istio control plane, run the following command:

{{< text bash >}}
$ istioctl uninstall <your original installation options>
{{< /text >}}

or

{{< text bash >}}
$ istioctl manifest generate <your original installation options> | kubectl delete --ignore-not-found=true -f -
{{< /text >}}

The control plane namespace (e.g., `istio-system`) is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

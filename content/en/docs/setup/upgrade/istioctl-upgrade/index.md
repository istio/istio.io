---
title: Upgrade Istio using istioctl [Experimental]
description: Upgrade or downgrade Istio using the istioctl upgrade command.
weight: 25
aliases:
    - /docs/setup/kubernetes/upgrade/steps/
    - /docs/setup/upgrade/steps
keywords: [kubernetes,upgrading]
---

{{< boilerplate experimental-feature-warning >}}

The `istioctl experimental upgrade` command performs an upgrade of Istio. Before performing
the upgrade, it checks that the Istio installation meets the upgrade eligibility
criteria. Also, it alerts the user if it detects any changes in the profile
default values between Istio versions.

The upgrade command can also perform a downgrade of Istio.

See the [`istioctl` upgrade reference](/docs/reference/commands/istioctl/#istioctl-experimental-upgrade)
for all the options provided by the `istioctl experimental upgrade` command.

## Upgrade prerequisites

Ensure you meet these requirements before starting the upgrade process:

* Istio version 1.3.3 or higher is installed.

* Your Istio installation was installed using
   [{{< istioctl >}}](/docs/setup/install/operator/).

## Upgrade steps

{{< warning >}}
Traffic disruption may occur during the upgrade process. To minimize the disruption, ensure
that at least two replicas of each component (except Citadel) are running. Also, ensure that
[`PodDistruptionBudgets`](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
are configured with a minimum availability of 1.
{{< /warning >}}

The commands in this section should be run using the new version of `istioctl` which
can be found in the `bin/` subdirectory of the downloaded package.

1. [Download the new Istio release](/docs/setup/#downloading-the-release)
   and change directory to the new release directory.

1. Verify that `istoctl` supports upgrading from your current Istio version by
   viewing the supported versions list:

    {{< text bash >}}
    $ istioctl manifest versions
    {{< /text >}}

1. Ensure that your Kubernetes configuration points to the cluster to upgrade:

    {{< text bash >}}
    $ kubectl config view
    {{< /text >}}

1. Begin the upgrade by running this command:

    {{< text bash >}}
    $ istioctl experimental upgrade -f `<your-custom-configuration-file>`
    {{< /text >}}

    `<your-custom-configuration-file>` is the
    [IstioControlPlane API Custom Resource Definition](/docs/setup/install/operator/#configure-the-feature-or-component-settings)
    file you used to customize the installation of the currently-running version of Istio.

    {{< warning >}}
    If you installed Istio using the `-f` flag, for example
    `istioctl manifest apply -f <IstioControlPlane-custom-resource-definition-file>`,
    then you must provide the same `-f` flag value to the `istioctl upgrade` command.
    {{< /warning >}}

    `istioctl upgrade` does not support the `--set` flag. Therefore, if you
    installed Istio using the `--set` command, create a configuration file with
    the equivalent configuration options and pass it to the `istioctl upgrade`
    command using the `-f` flag instead.

    If you omit the `-f` flag, Istio upgrades using the default profile.

    After performing several checks, `istioctl` will ask you to confirm whether to proceed.

1. `istioctl` will install the new version of Istio control plane and indicate the
   completion status.

1. After `istioctl` completes the upgrade, you must manually update the Istio data plane
   by restarting any pods with Istio sidecars:

    {{< text bash >}}
    $ kubectl rollout restart deployment
    {{< /text >}}

## Downgrade prerequisites

Ensure you meet these requirements before starting the downgrade process:

* Istio version 1.4 or higher is installed.

* Your Istio installation was installed using
   [{{< istioctl >}}](/docs/setup/install/operator/).

* Downgrade must be done using the `istioctl` binary version that
corresponds to the Istio version that you intend to downgrade to.
For example, if you are downgrading from Istio 1.4 to 1.3.3, use `istioctl`
version 1.3.3.

## Downgrade to Istio 1.4 and higher versions steps

You can also use `istioctl upgrade` to downgrade versions. The process steps are
identical to the upgrade process mentioned in the previous section, only use the
`istioctl` binary corresponding to the lower version. When completed, the
process will restore Istio back to the Istio version that was installed before
you ran `istioctl experimental upgrade`.

### Downgrade to Istio 1.3.3 and lower versions steps

The `istioctl experimental upgrade` command is not available in Istio 1.3.3 and lower.
Therefore, downgrade must be performed using the
`istioctl experimental manifest apply` command.

This command installs the same Istio control plane as `istioctl experimental upgrade`,
but does not perform any checks. For example, default values applied to the cluster
for a configuration profile may change without warning.

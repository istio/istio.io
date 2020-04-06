---
title: Upgrade Istio
description: Upgrade or downgrade Istio.
weight: 25
keywords: [kubernetes,upgrading]
---

## Canary upgrades

The recommended upgrade method is to do a canary deployment of the control plane,
and slowly migrate traffic to the new version. This allows making safe changes
and monitor the impact on the mesh before moving all traffic over.

To support canary deployments, Istio has an installation setting named `revision`.
Using this option, you can deploy independent control planes.
Each revision will have its own Deployment, Service, etc.

### Control plane

To install a new revision, named `canary` for example, set the `revision` field:
`istioctl install --set revision=canary`.

After this runs, see there are two deployments running side-by-side:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-786779888b-p9s5n                 1/1     Running   0          114m
istiod-canary-6956db645c-vwhsk          1/1     Running   0          1m
{{< /text >}}

### Data plane

Simply installing the new revision has no impact on the existing proxies. To upgrade these,
configure them to point to the new control plane. This is controlled during sidecar injection
based on the namespace label `istio.io/rev`. To upgrade the namespace `test-ns`, relabel it
to point to the canary revision: `kubectl label namespace default istio-injection- istio.io/rev=canary`. Note the removal
of the `istio-injection` label, which takes precedence over the `istio.io/rev` label
for backwards compatibility.

After the namespace updates, restart the pods to trigger a re-injection. One way to do
this is using `kubectl rollout restart deployment -n test-ns`.

When the pod is re-injected, it will be configured to point to the `istiod-canary` control plane. You can verify this by
looking at the pod labels. For example, `kubectl get pods -n test-ns -l istio.io/rev=canary` will show all
pods using the `canary` revision.

## In place upgrades

The `istioctl upgrade` command performs an upgrade of Istio. Before performing
the upgrade, it checks that the Istio installation meets the upgrade eligibility
criteria. Also, it alerts the user if it detects any changes in the profile
default values between Istio versions.

The upgrade command can also perform a downgrade of Istio.

See the [`istioctl` upgrade reference](/docs/reference/commands/istioctl/#istioctl-upgrade)
for all the options provided by the `istioctl upgrade` command.

### Upgrade prerequisites

Ensure you meet these requirements before starting the upgrade process:

* Istio version 1.4.4 or higher is installed.

* Your Istio installation was [installed using {{< istioctl >}}](/docs/setup/install/istioctl/).

### Upgrade steps

{{< warning >}}
Traffic disruption may occur during the upgrade process. To minimize the disruption, ensure
that at least two replicas of each component (except Citadel) are running. Also, ensure that
[`PodDistruptionBudgets`](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
are configured with a minimum availability of 1.
{{< /warning >}}

The commands in this section should be run using the new version of `istioctl` which
can be found in the `bin/` subdirectory of the downloaded package.

1. [Download the new Istio release](/docs/setup/getting-started/#download)
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
    $ istioctl upgrade -f `<your-custom-configuration-file>`
    {{< /text >}}

    `<your-custom-configuration-file>` is the
    [IstioOperator API Configuration](/docs/setup/install/istioctl/#configure-component-settings)
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

### Downgrade prerequisites

Ensure you meet these requirements before starting the downgrade process:

* Istio version 1.5 or higher is installed.

* Your Istio installation was [installed using {{< istioctl >}}](/docs/setup/install/istioctl/).

* Downgrade must be done using the `istioctl` binary version that
corresponds to the Istio version that you intend to downgrade to.
For example, if you are downgrading from Istio 1.5 to 1.4.4, use `istioctl`
version 1.4.4.

### Downgrade to Istio 1.4.4 and lower versions steps

You can use `istioctl experimental upgrade` to downgrade to 1.4 versions. Please
notice that you need to use the `istioctl` binary corresponding to the lower
version (e.g., 1.4.4), and `upgrade` is experimental in 1.4. The process steps are
identical to the upgrade process mentioned in the previous section. When completed,
the process will restore Istio back to the Istio version that was installed before.

`istioctl manifest apply` also installs the same Istio control plane, but does not
perform any checks. For example, default values applied to the cluster for a configuration
profile may change without warning.

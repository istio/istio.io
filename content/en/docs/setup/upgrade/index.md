---
title: Upgrade Istio
description: Upgrade or downgrade Istio.
weight: 25
keywords: [kubernetes,upgrading]
owner: istio/wg-environments-maintainers
test: no
---

## Canary upgrades

Upgrading Istio can be done by first running a canary deployment of the new control plane, allowing you
to monitor the effect of the upgrade with a small percentage of the workloads, before migrating all of the
traffic to the new version. This is much safer than doing an in place upgrade and is the recommended upgrade method.

When installing Istio, the `revision` installation setting can be used to deploy multiple independent control planes
at the same time. A canary version of an upgrade can be started by installing the new Istio version's control plane
next to the old one, using a different `revision` setting. Each revision is a full Istio control plane implementation
with its own `Deployment`, `Service`, etc.

See additional notes for [upgrading from Helm installations](#upgrading-from-helm-installations)
and [upgrading from 1.4.x](#upgrading-from-1.4).

### Control plane

To install a new revision called `canary`, you would set the `revision` field as follows:

{{< text bash >}}
$ istioctl install --set revision=canary
{{< /text >}}

After running the command, you will have two control plane deployments and services running side-by-side:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-786779888b-p9s5n                 1/1     Running   0          114m
istiod-canary-6956db645c-vwhsk          1/1     Running   0          1m
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get svc -lapp=istiod
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                AGE
istiod          ClusterIP   10.32.5.247   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP                  33d
istiod-canary   ClusterIP   10.32.6.58    <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,53/UDP,853/TCP   12m
{{< /text >}}

You will also see that there are two sidecar injector configurations including the new revision.

{{< text bash >}}
$ kubectl get mutatingwebhookconfigurations
NAME                            CREATED AT
istio-sidecar-injector          2020-03-26T07:09:21Z
istio-sidecar-injector-canary   2020-04-28T19:03:26Z
{{< /text >}}

### Data plane

Simply installing the new revision has no impact on the existing proxies. To upgrade these,
you must configure them to point to the new control plane. This is controlled during sidecar injection
based on the namespace label `istio.io/rev`.

To upgrade the namespace `test-ns`, add the `istio.io/rev` label to point to the `canary` revision and remove the `istio-injection` label.

{{< text bash >}}
$ kubectl label namespace test-ns istio-injection- istio.io/rev=canary
{{< /text >}}

The `istio-injection` label must be removed because it takes precedence over the `istio.io/rev` label for backward compatibility.

After the namespace updates, you need to restart the pods to trigger re-injection. One way to do
this is using:

{{< text bash >}}
$ kubectl rollout restart deployment -n test-ns
{{< /text >}}

When the pods are re-injected, they will be configured to point to the `istiod-canary` control plane. You can verify this by looking at the pod labels.

For example, the following command will show all the pods using the `canary` revision:

{{< text bash >}}
$ kubectl get pods -n test-ns -l istio.io/rev=canary
{{< /text >}}

To verify that the new pods in the `test-ns` namespace are using the `istiod-canary` service corresponding to the `canary` revision, select one newly created pod and use the `pod_name` in the following command:

{{< text bash >}}
$ istioctl proxy-config endpoints ${pod_name}.test-ns --cluster xds-grpc -ojson | grep hostname
"hostname": "istiod-canary.istio-system.svc"
{{< /text >}}

The output confirms that the pod is using `istiod-canary` revision of the control plane.

### Uninstall old control plane

After upgrading both the control plane and data plane, you can uninstall the old control plane. For example, the following command uninstalls a control plane of revision `istio-1-6-5`:

{{< text bash >}}
$ istioctl x uninstall --revision istio-1-6-5
{{< /text >}}

Confirm that the old control plane has been removed and only the new one still exists in the cluster:

{{< text bash >}}
$ kubectl get pods -n istio-system -lapp=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
{{< /text >}}

Note that the above instructions only removed the resources for the specified control plane revision, but not cluster-scoped resources shared with other control planes. To uninstall Istio completely, refer to the [uninstall guide](/docs/setup/install/istioctl/#uninstall-istio).

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
[`PodDisruptionBudgets`](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
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
    `istioctl install -f <IstioControlPlane-custom-resource-definition-file>`,
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

### Steps to downgrade to a lower Istio version

You can use `istioctl experimental upgrade` to downgrade to a lower version of Istio. Please
notice that you need to use the `istioctl` binary corresponding to the lower
version (e.g., 1.4.4), and `upgrade` is experimental in 1.4. The process steps are
identical to the upgrade process mentioned in the previous section. When completed,
the process will restore Istio back to the Istio version that was installed before.

`istioctl install` also installs the same Istio control plane, but does not
perform any checks. For example, default values applied to the cluster for a configuration
profile may change without warning.

## Upgrading from Helm installations

For Istio installations done with Helm, the canary upgrade process must be used.
The canary control plane must be installed with an `IstioOperator` CR equivalent
to the Helm `values.yaml` used to install Istio. The `istioctl manifest migrate` command (using `istioctl` 1.6)
simplifies the migration by automatically translating `values.yaml` to IstioOperator CR format.
To install the canary control plane, first generate an IstioOperator CR:

{{< text bash >}}
$ istioctl manifest migrate <path-to-values.yaml> > iop.yaml
{{< /text >}}

Inspect the generated `iop.yaml` file to ensure it's correct. You can use this CR to install a 1.6 Istio canary
control plane with the same settings as the Helm installed control plane.

## Upgrading from 1.4

Migrating from 1.4 Istio (installed with `istioctl` or Helm) is similar to the process for 1.5 using canary, with one
additional step. Istio 1.4 validation does not recognize some 1.6 resources, and the 1.4 validation webhook prevents
Istio 1.6 from functioning correctly.
To work around this problem, the validation webhook must be disabled temporarily, using the following steps.

1. Edit the Galley deployment configuration using the following command:

{{< text bash >}}
$ kubectl edit deployment -n istio-system istio-galley
{{< /text >}}

Add the --enable-validation=false option to the command: section as shown below:

{{< text yaml >}}
apiVersion: extensions/v1beta1
kind: Deployment
...
spec:
...
  template:
    ...
    spec:
      ...
      containers:
      - command:
        ...
        - --log_output_level=default:info
        - --enable-validation=false
{{< /text >}}

Save and quit the editor to update the deployment configuration in the cluster.

1. Remove the `ValidatingWebhookConfiguration` Custom Resource (CR) with the following command:

{{< text bash >}}
$ kubectl delete ValidatingWebhookConfiguration istio-galley -n istio-system
{{< /text >}}

---
title: Upgrade Istio
description: Upgrade or downgrade Istio.
weight: 25
keywords: [kubernetes,upgrading]
owner: istio/wg-environments-maintainers
test: no
---

{{< warning >}}
Upgrade across multiple minor versions in one step is not officially tested or recommended.
{{< /warning >}}

## Canary upgrades

Upgrading Istio can be done by first running a canary deployment of the new control plane, allowing you
to monitor the effect of the upgrade with a small percentage of the workloads, before migrating all of the
traffic to the new version. This is much safer than doing an in place upgrade and is the recommended upgrade method.

When installing Istio, the `revision` installation setting can be used to deploy multiple independent control planes
at the same time. A canary version of an upgrade can be started by installing the new Istio version's control plane
next to the old one, using a different `revision` setting. Each revision is a full Istio control plane implementation
with its own `Deployment`, `Service`, etc.

### Control plane

To install a new revision called `canary`, you would set the `revision` field as follows:

{{< tip >}}
In a production environment, a better revision name would correspond to the Istio version.
However, you must replace `.` characters in the revision name, for example, `revision=1-6-8` for Istio `1.6.8`,
because `.` is not a valid revision name character.
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set revision=canary
{{< /text >}}

After running the command, you will have two control plane deployments and services running side-by-side:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-786779888b-p9s5n                 1/1     Running   0          114m
istiod-canary-6956db645c-vwhsk          1/1     Running   0          1m
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n istio-system -l app=istiod
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

Unlike istiod, Istio gateways do not run revision-specific instances, but are instead in-place upgraded to use the new control plane revision.
You can verify that the `istio-ingress` gateway is using the `canary` revision by running the following command:

{{< text bash >}}
$ istioctl proxy-config endpoints $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items..metadata.name}').istio-system --cluster xds-grpc -ojson | grep hostname
"hostname": "istiod-canary.istio-system.svc"
{{< /text >}}

However, simply installing the new revision has no impact on the existing sidecar proxies. To upgrade these,
you must configure them to point to the new `istiod-canary` control plane. This is controlled during sidecar injection
based on the namespace label `istio.io/rev`.

To upgrade the namespace `test-ns`, remove the `istio-injection` label, and add the `istio.io/rev` label to point to the `canary` revision. The `istio-injection` label must be removed because it takes precedence over the `istio.io/rev` label for backward compatibility.

{{< text bash >}}
$ kubectl label namespace test-ns istio-injection- istio.io/rev=canary
{{< /text >}}

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

After upgrading both the control plane and data plane, you can uninstall the old control plane. For example, the following command uninstalls a control plane of revision `1-6-5`:

{{< text bash >}}
$ istioctl x uninstall --revision 1-6-5
{{< /text >}}

If the old control plane does not have a revision label, uninstall it using its original installation options, for example:

{{< text bash >}}
$ istioctl x uninstall -f manifests/profiles/default.yaml
{{< /text >}}

Confirm that the old control plane has been removed and only the new one still exists in the cluster:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
{{< /text >}}

Note that the above instructions only removed the resources for the specified control plane revision, but not cluster-scoped resources shared with other control planes. To uninstall Istio completely, refer to the [uninstall guide](/docs/setup/install/istioctl/#uninstall-istio).

### Uninstall canary control plane

If you decide to rollback to the old control plane, instead of completing the canary upgrade,
you can uninstall the canary revision using `istioctl x uninstall --revision=canary`.

However, in this case you must first reinstall the gateway(s) for the previous revision manually,
because the uninstall command will not automatically revert the previously in-place upgraded ones.

{{< tip >}}
Make sure to use the `istioctl` version corresponding to the old control plane to reinstall the
old gateways and, to avoid downtime, make sure the old gateways are up and running before proceeding
with the canary uninstall.
{{< /tip >}}

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

* Istio version is 1 minor version less than {{< istio_full_version >}}. For example, 1.6.0 or higher is required before you start the upgrade process to 1.7.0.

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

1. Ensure that your Kubernetes configuration points to the cluster to upgrade:

    {{< text bash >}}
    $ kubectl config view
    {{< /text >}}

1. Begin the upgrade by running this command:

    {{< text bash >}}
    $ istioctl upgrade -f `<your-custom-configuration-file>`
    {{< /text >}}

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

1. `istioctl` will in-place upgrade the Istio control plane and gateways to the new version and indicate the
   completion status.

1. After `istioctl` completes the upgrade, you must manually update the Istio data plane
   by restarting any pods with Istio sidecars:

    {{< text bash >}}
    $ kubectl rollout restart deployment
    {{< /text >}}

### Downgrade prerequisites

Ensure you meet these requirements before starting the downgrade process:

* Your Istio installation was [installed using {{< istioctl >}}](/docs/setup/install/istioctl/).

* The Istio version you intend to downgrade to is 1 minor version less than {{< istio_full_version >}}.

* Downgrade must be done using the `istioctl` binary version that
corresponds to the Istio version that you intend to downgrade to.
For example, if you are downgrading from Istio 1.7 to 1.6.5, use `istioctl`
version 1.6.5.

### Steps to downgrade to a lower Istio version

You can use `istioctl upgrade` to downgrade to a lower version of Istio. Please
notice that you need to use the `istioctl` binary corresponding to the lower
version (e.g., 1.6.5). The process steps are
identical to the upgrade process mentioned in the previous section. When completed,
the process will restore Istio back to the Istio version that was installed before.

`istioctl install` can be used to install an older version of the Istio control plane, but is not recommended
because it does not perform any checks. For example, default values applied to the cluster for a configuration
profile may change without warning.

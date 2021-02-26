---
title: Canary Upgrades
description: Upgrade Istio by first running a canary deployment of a new control plane.
weight: 10
keywords: [kubernetes,upgrading,canary]
owner: istio/wg-environments-maintainers
test: no
---

Upgrading Istio can be done by first running a canary deployment of the new control plane, allowing you
to monitor the effect of the upgrade with a small percentage of the workloads, before migrating all of the
traffic to the new version. This is much safer than doing an
[in place upgrade](/docs/setup/upgrade/in-place/) and is the recommended upgrade method.

When installing Istio, the `revision` installation setting can be used to deploy multiple independent control planes
at the same time. A canary version of an upgrade can be started by installing the new Istio version's control plane
next to the old one, using a different `revision` setting. Each revision is a full Istio control plane implementation
with its own `Deployment`, `Service`, etc.

## Control plane

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
NAME                            WEBHOOKS   AGE
istio-sidecar-injector          1          7m56s
istio-sidecar-injector-canary   1          3m18s
{{< /text >}}

{{< warning >}}
Due to [a bug](https://github.com/istio/istio/issues/28880) in the creation of the `ValidatingWebhookConfiguration` during install, initial installations of Istio __must not__ specify a revision. As a temporary workaround, for Istio resource validation to continue working after removing the non-revisioned Istio installation, the `istiod` service must be manually pointed to the revision that should handle validation.

One way to accomplish this is to manually create a service called `istiod` pointing to the target revision using [this service]({{< github_blob >}}/manifests/charts/istio-control/istio-discovery/templates/service.yaml) as a template. Another option is to run the command below, where `<REVISION>` is the name of the revision that should handle validation. This command creates an `istiod` service pointed to the target revision.

{{< text bash >}}
$ kubectl get service -n istio-system -o json istiod-<REVISION> | jq '.metadata.name = "istiod" | del(.spec.clusterIP) | del(.spec.clusterIPs)' | kubectl apply -f -
{{< /text >}}

{{</ warning >}}

## Data plane

Unlike istiod, Istio gateways do not run revision-specific instances, but are instead in-place upgraded to use the new control plane revision.
You can verify that the `istio-ingress` gateway is using the `canary` revision by running the following command:

{{< text bash >}}
$ istioctl proxy-status | grep $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items..metadata.name}') | awk '{print $8}'
istiod-canary-6956db645c-vwhsk
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
$ istioctl proxy-status | grep ${pod_name} | awk '{print $8}'
istiod-canary-6956db645c-vwhsk
{{< /text >}}

The output confirms that the pod is using `istiod-canary` revision of the control plane.

## Uninstall old control plane

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

## Uninstall canary control plane

If you decide to rollback to the old control plane, instead of completing the canary upgrade,
you can uninstall the canary revision using `istioctl x uninstall --revision=canary`.

However, in this case you must first reinstall the gateway(s) for the previous revision manually,
because the uninstall command will not automatically revert the previously in-place upgraded ones.

{{< tip >}}
Make sure to use the `istioctl` version corresponding to the old control plane to reinstall the
old gateways and, to avoid downtime, make sure the old gateways are up and running before proceeding
with the canary uninstall.
{{< /tip >}}

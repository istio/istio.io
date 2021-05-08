---
title: Before you begin
description: Initial steps before configuring locality load balancing.
weight: 1
icon: tasks
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
test: yes
owner: istio/wg-networking-maintainers
---
Before you begin the locality load balancing tasks, you must first
[install Istio on multiple clusters](/docs/setup/install/multicluster). The
clusters must span three regions, containing four availability zones. The
number of clusters required may vary based on the capabilities offered by
your cloud provider.

{{< tip >}}
For simplicity, we will assume that there is only a single
{{< gloss >}}primary cluster{{< /gloss >}} in the mesh. This simplifies
the process of configuring the control plane, since changes only need to be
applied to one cluster.
{{< /tip >}}

We will deploy several instances of the `HelloWorld` application as follows:

{{< image width="75%"
    link="setup.svg"
    caption="Setup for locality load balancing tasks"
    >}}

## Environment Variables

This guide assumes that all clusters will be accessed through contexts in the
default [Kubernetes configuration file](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
The following environment variables will be used for the various contexts:

Variable | Description
-------- | -----------
`CTX_PRIMARY` | The context used for applying configuration to the primary cluster.
`CTX_WORKERS` | The contexts used to interact with pods in the worker clusters.

## Set the worker clusters

{{< text bash >}}
$ export CTX_WORKERS=('cluster1' 'cluster2'); // adjust to your contexts!

## Create the `sample` namespace

To begin, generate yaml for the `sample` namespace with automatic sidecar
injection enabled:

{{< text bash >}}
$ cat <<EOF > sample.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sample
  labels:
    istio-injection: enabled
EOF
{{< /text >}}

Next, add the `sample` namespace to each cluster, generate and deploy 
the `HelloWorld` YAML for each locality, using the locality or localities 
found in each cluster as the version string:

{{< text bash >}}
$ for CTX in ${CTX_PRIMARY} ${CTX_WORKERS[@]}; \
  do \
    kubectl --context="$CTX" apply -f sample.yaml; \
    for LOC in $(kubectl --context="$CTX" get nodes -o \
      custom-columns=REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{.metadata.labels.topology\.kubernetes\.io/zone}' --no-headers  \
      | uniq | sed -E 's/<none>/default/g' | sed -E 's/[ \t]+/\./g')
    do \
      ./@samples/helloworld/gen-helloworld.sh \
        --version "$LOC" > "helloworld-${LOC}.yaml"; \
        kubectl --context="$CTX" apply -f "helloworld-${LOC}.yaml"; \
    done
  done

## Deploy `Sleep`

Deploy the `Sleep` application to `region1` `zone1`:

{{< text bash >}}
$ kubectl apply --context="${CTX_R1_Z1}" \
  -f @samples/sleep/sleep.yaml@ -n sample
{{< /text >}}

## Wait for `HelloWorld` pods

Wait until the `HelloWorld` pods in each zone are `Running`.

**Congratulations!** You successfully configured the system and are now ready
to begin the locality load balancing tasks!

## Next steps

You can now configure one of the following load balancing options:

- [Locality failover](/docs/tasks/traffic-management/locality-load-balancing/failover)

- [Locality weighted distribution](/docs/tasks/traffic-management/locality-load-balancing/distribute)

{{< warning >}}
Only one of the load balancing options should be configured, as they are
mutually exclusive. Attempting to configure both may lead to unexpected
behavior.
{{< /warning >}}

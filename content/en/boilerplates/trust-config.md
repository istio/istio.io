---
---
For `CLUSTER_2` to participate in cross-cluster load balancing with your
first cluster, in this case `CLUSTER_1`, establish trust
between the clusters and generate a Certificate Authority (CA) certificate for
`CLUSTER_2` that the common root CA signed.
Using the set environment variables, configure trust with the following steps:

1. Go to the `${WORK_DIR}` folder with the following command:

{{< text bash >}}
$ cd ${WORK_DIR}
{{< /text >}}

1. Generate the intermediate CA files for `Cluster_2` with the following command:

{{< text bash >}}
$ make -f ${ISTIO}/tools/certs/Makefile ${CLUSTER_2}-cacerts-k8s
{{< /text >}}

1. To ensure that the Istio control plane and the secret share the same
   namespace, create the `istio-system` namespace in `Cluster_2` with the
   following command:

{{< text bash >}}
$ kubectl create namespace istio-system --context=${CTX_2}
{{< /text >}}

1. Push the secret with the generated CA files to `Cluster_2` with the
   following command:

{{< text bash >}}
$ kubectl create secret generic cacerts --context=${CTX_2} \
  -n istio-system \
  --from-file=${WORK_DIR}/${CLUSTER_2}/ca-cert.pem \
  --from-file=${WORK_DIR}/${CLUSTER_2}/ca-key.pem \
  --from-file=${WORK_DIR}/${CLUSTER_2}/root-cert.pem \
  --from-file=${WORK_DIR}/${CLUSTER_2}/cert-chain.pem
{{< /text >}}

**Congratulations!**

You configured trust in `Cluster_2` to enable workloads in
different clusters to trust each other in your multicluster mesh.
Next, deploy an Istio control plane on `Cluster_2`.

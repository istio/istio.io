---
title: IBM Cloud Kubernetes Service (IKS) & IBM Cloud Private(ICP)
description: Example multicluster between IKS & ICP
weight: 70
keywords: [kubernetes,multicluster,hybrid]
---

This example demonstrates how to use Istio's multicluster feature to join one
[IBM Cloud Private](https://www.ibm.com/cloud/private) cluster and one [IBM Kubernetes Service](https://console.bluemix.net/docs/containers/container_index.html#container_index) together,
using the [Kubernetes multicluster installation instructions](/docs/setup/kubernetes/multicluster-install/).

## Set Up two clusters

1.  [Install One IBM Cloud Private clusters](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/installing/installing.html).
    __NOTE__: You can configure Pod CIDR ranges and service CIDR ranges by `network_cidr` and
    `service_cluster_ip_range` in `cluster/config.yaml` for ICP.

    {{< text plain >}}
    ## Network in IPv4 CIDR format
    network_cidr: 10.1.0.0/16
    ## Kubernetes Settings
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  [Request One IBM Kubernetes Service clusters](https://console.bluemix.net/docs/containers/container_index.html#container_index).
    __NOTE__: By default, when you have provisioned a IKS cluster, the CIDR is as below.

     {{< text plain >}}
     pod subnet CIDR: 172.30.0.0/16.
     service subnet CIDR: 172.21.0.0/16.
     {{< /text >}}


## Configure Pod Communication Across ICP & IKS

Since these two clusters are in isolated network environments we need to set up VPN connection between them. You can use [strongSwan](https://www.strongswan.org/) for this purpose.


1.  Set up strongSwan in IKS.

    1.  Set up Helm in IBM Cloud Kubernetes Service by following [these instructions](https://console.bluemix.net/docs/containers/cs_integrations.html#helm)

    1.  Install strongSwan using Helm chart by following [these instructions](https://console.bluemix.net/docs/containers/cs_vpn.html#vpn).
    Example configuration parameters from config.yaml:
        {{< text plain >}}
        ipsec.auto: add
        remote.subnet: 10.0.0.0/24,10.1.0.0/16
        {{< /text >}}

    1.  Get the External IP of the vpn-strongswan service.

        {{< text bash >}}
        $ kubectl get svc vpn-strongswan
        {{< /text >}}

1.  Set up strongSwan in ICP.

    1.  Complete the strongSwan IPSec VPN workarounds for ICP by following [these instructions](https://www.ibm.com/support/knowledgecenter/SS2L37_2.1.0.3/cam_strongswan.html)

    1.  Install the strongSwan from the Catalog in the management consoleby following [these instructions](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/app_center/create_release.html)

         Example configuration parameters:
         {{< text plain >}}
         Namespace: default
         Operation at startup: start
         Local subnets: 10.0.0.0/24,10.1.0.0/16
         Remote gateway: Public IP of IKS vpn-strongswan service that you get earlier
         Remote subnets: 172.30.0.0/16,172.21.0.0/16
         Privileged authority for VPN pod: checked
         {{< /text >}}

    1.  Verify that ICP can connect to IKS by running the following command against the IKS:

        {{< text bash >}}
        $ export STRONGSWAN_POD=$(kubectl get pod -l app=strongswan,release=vpn -o jsonpath='{ .items[0].metadata.name }')
        $ kubectl exec $STRONGSWAN_POD -- ipsec status
        {{< /text >}}.
1.  Confirm across pod communication by pinging pod IP in ICP from IKS.
    {{< text bash >}}
    $ping 10.1.14.30
    PING 10.1.14.30 (10.1.14.30) 56(84) bytes of data.
    64 bytes from 10.1.14.30: icmp_seq=1 ttl=59 time=51.8 ms
    {{< /text >}}

The steps in this section enables Pod communication across clusters.

## Install Istio for multicluster

[Follow the multicluster installation steps](/docs/setup/kubernetes/multicluster-install/) to install and configure
 Istio local control plane and Istio remote on `ICP` and `IKS`.

This example uses `ICP` as the Istio local control plane and `IKS` as the Istio remote.

## Deploy Bookinfo Example Across Clusters by following [these instructions](/docs/examples/multicluster/icp/)

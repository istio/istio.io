---
title: Running Istio-proxy containers
description: Running containerized istio-proxy on Virtual Machines.
weight: 70
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
- docker
- containers
owner: istio/wg-environments-maintainers
test: yes

---
Follow this guide to run the Istio-proxy as a container instead of the Istio virtual machine integration runtime allowing more flexibility of the underlying platform.

## Prerequisites

1. Follow the steps described on [Virtual Machine Installation](/docs/setup/install/virtual-machine/) until [configure-the-virtual-machine](/docs/setup/install/virtual-machine/#configure-the-virtual-machine).
1. Have your [guide environment](/docs/setup/install/virtual-machine/#prepare-the-guide-environment) prepared.
1. Learn about [Virtual Machine Architecture](/docs/ops/deployment/vm-architecture/) to gain an understanding of the high level architecture of Istio's virtual machine integration.

## Host OS requirements

1. Have a container runtime installed like [Docker](https://docs.docker.com/engine/install/) (used in this guide) or [Podman](https://podman.io/docs/installation).
1. Ability to run a container with `--network=host`- allowing it to interact with the hosts Iptables.
1. Ability to run a container with the capability: `NET_ADMIN` - allowing it to update Iptables.
1. Reserve UID `1337` for the user: `istio-proxy`.

## Overview

Installing the Istio-proxy package comes with a start-[script]({{< github_blob >}}tools/packaging/common/istio-start.sh) to bootstrap some final variables
and runs [istio-iptables](/docs/reference/commands/pilot-agent/#pilot-agent-istio-iptables) and [istio-clean-iptables](/docs/reference/commands/pilot-agent/#pilot-agent-istio-clean-iptables)
to correctly configure `iptables` before starting the [istio-proxy](docs/reference/commands/pilot-agent/#pilot-agent-proxy) itself.
This guide will cover this extra configurations to run the Istio-proxy as a sidecar-container.

## Extra configuration

Like mentioned above, extra configuration to `cluster.env` and `mesh.yaml` is required. This is an addition on the already generated configuration via [Virtual Machine Installation](/docs/setup/install/virtual-machine/#create-files-to-transfer-to-the-virtual-machine):

1. setup some extra environment variables:

    {{< text bash >}}
    $ INSTANCE_IP="<the primary IP of the VM>"
    $ POD_NAME="<hostname of the VM (not FQDN)>"
    $ SERVICECLUSTER="${VM_APP}.${VM_NAMESPACE}"
    {{< /text >}}

1. Update `cluster.env`:

    {{< text bash >}}
    $ cat <<EOF >> ${WORK_DIR}/cluster.env
    INSTANCE_IP=${INSTANCE_IP}
    ISTIO_CLUSTER_CONFIG=./var/lib/istio/envoy/cluster.env
    POD_NAME=${POD_NAME}
    OUTPUT_CERTS=./etc/certs
    PROV_CERT=./etc/certs
    EOF
    {{< /text >}}

1. Update `mesh.yaml`:

    {{< text bash >}}
    $ cat <<EOF >> ${WORK_DIR}/mesh.yaml
      serviceCluster: ${SERVICECLUSTER}
    EOF
    {{< /text >}}

## Prepare the machine

Run the following commands on the virtual machine:

1. Securely transfer the files from `"${WORK_DIR}"`
    to the virtual machine.  How you choose to securely transfer those files should be done with consideration for
    your information security policies. For convenience in this guide, transfer all of the required files to `"${HOME}"` in the virtual machine.

1. Install the root certificate at `/etc/certs`:

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp "${HOME}"/root-cert.pem /etc/certs/root-cert.pem
    {{< /text >}}

1. Install the token at `/var/run/secrets/tokens`:

    {{< text bash >}}
    $ sudo  mkdir -p /var/run/secrets/tokens
    $ sudo cp "${HOME}"/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}

1. Install `cluster.env` within the directory `/var/lib/istio/envoy/`:

    {{< text bash >}}
    $ sudo mkdir -p /var/lib/istio/envoy
    $ sudo cp "${HOME}"/cluster.env /var/lib/istio/envoy/cluster.env
    {{< /text >}}

1. Install the [Mesh Config](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) to `/etc/istio/config/mesh`:

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/config
    $ sudo cp "${HOME}"/mesh.yaml /etc/istio/config/mesh
    {{< /text >}}

1. Add the istiod host to `/etc/hosts`:

    {{< text bash >}}
    $ sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts >> /etc/hosts'
    {{< /text >}}

1. Transfer ownership of the files in `/etc/certs/` and `/var/lib/istio/envoy/` to the Istio proxy:

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/proxy
    $ sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem
    {{< /text >}}

1. Docker does not exclude quotes when supplying a `--env-file`, remove them ourselves:

    {{< tabset category-name="quotes" >}}

    {{< tab name="macOS" category-value="mac" >}}

    {{< text bash >}}
    $ sed -i '' "s/'//g" ${WORK_DIR}/cluster.env
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Linux" category-value="linux" >}}

    {{< text bash >}}
    $ sed -i "s/'//g" ${WORK_DIR}/cluster.env
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

## Start the sidecar container on the virtual machine

1. Configure iptables to redirect all traffic from the VM to the Istio sidecar:

    {{< text bash >}}
    $ docker run \
    --rm \
    --cap-add=NET_ADMIN \
    --entrypoint="" \
    --network host \
    --env-file /var/lib/istio/envoy/cluster.env \
    --name istio-init \
    istio/proxyv2:{{< istio_full_version >}} \
    /bin/bash -c "update-alternatives --set iptables /usr/sbin/iptables-nft && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-nft && \
    /usr/local/bin/pilot-agent istio-iptables"
    {{< /text >}}

    {{< warning >}}
    The proxyv2 image is configured to use iptables-legacy, hence we need to do some trickery with `update-alternatives` to consult the correct iptables endpoint.
    {{< /warning >}}

1. Start the Istio-proxy container:

    {{< text bash >}}
    $ docker run \
    -u '1337:1337' \
    --net host \
    -d \
    --env-file /var/lib/istio/envoy/cluster.env \
    -v /var/run/secrets/:/var/run/secrets \
    -v /var/lib/istio/config:/var/lib/istio/config \
    -v /var/lib/istio/proxy:/var/lib/istio/proxy \
    -v /etc/certs:/etc/certs \
    -v /etc/istio:/etc/istio \
    --name istio-proxy \
    istio/proxyv2:{{< istio_full_version >}} \
    proxy --concurrency 2 --log_as_json
    {{< /text >}}

## Verify Istio-proxy container

1. Check the docker logs for any potential errors:

    {{< text bash >}}
    $ docker logs istio-proxy
    {{< /text >}}

1. Verify if the side car is registered:

    {{< text bash >}}
    $ istioctl proxy-status | grep ${SERVICENAME}
        NAME                                                    CLUSTER        CDS                LDS                EDS                RDS                ECDS        ISTIOD                    VERSION
    ${VM_NAME}.${VM_NAMESPACE}                                 Kubernetes     SYNCED (4m30s)     SYNCED (4m30s)     SYNCED (4m30s)     SYNCED (4m30s)     IGNORED     istiod-5644d594-q4qr5     {{< istio_full_version >}}
    {{< /text >}}

## Stopping the Istio-proxy container

1. Stop the sidecar container:

    {{< text bash >}}
    $ docker stop istio-proxy; docker rm istio-proxy
    {{< /text >}}

1. Cleanup iptables to stop redirecting traffic to the Istio-proxy (that no longer exists/runs):

    {{< text bash >}}
    $ docker run \
    --rm \
    --cap-add=NET_ADMIN \
    --entrypoint="" \
    --network host \
    --env-file /var/lib/istio/envoy/cluster.env \
    --name istio-init \
    istio/proxyv2:{{< istio_full_version >}} \
    /bin/bash -c "update-alternatives --set iptables /usr/sbin/iptables-nft && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-nft && \
    /usr/local/bin/pilot-agent istio-clean-iptables"
    {{< /text >}}

    {{< idea >}}
    A more sophisticated way of running containerized Istio-proxy would be to reuse the startup script or setup systemd unit files to take care of start and stopping your Istio-proxy.
    Making sure it always has a correct configured environment.
    {{< /idea >}}

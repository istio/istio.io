---
title: Installation with Ansible
description: Install Istio with the included Ansible playbook.
weight: 40
keywords: [kubernetes,ansible]
---

Instructions for the installation and configuration of Istio using Ansible.

## Prerequisites

The following instructions require [Ansible 2.4](https://docs.ansible.com/ansible/latest/intro_installation.html). Additionally Kubernetes **1.9.0 or newer** is required.

The following prerequisites must be met if using OpenShift.

* Minimum Version: **3.9.0**
* **oc** configured to be able to access the cluster
* User has logged in to the cluster
* User has `cluster-admin` role on OpenShift

## Deploy with Ansible

**Important**: All execution of the Ansible playbooks must take place in the `install/ansible` path of Istio.

This playbook will download and install Istio locally on your machine. To deploy the default settings of
Istio on OpenShift, the following command may be used:

{{< text bash >}}
$ ansible-playbook main.yml
{{< /text >}}

## Customization with Ansible

The Ansible playbook ships with reasonable defaults.

The currently exposed options are:

| Parameter | Description | Values | Default |
| --- | --- | --- | --- |
| `cluster_flavour` | Define the target cluster type | `k8s` or `ocp` | `ocp` |
| `github_api_token` | A valid GitHub API authentication token used for authenticating with GitHub | A valid GitHub API token | empty |
| `cmd_path` | Override the path to `kubectl` or `oc` | A valid path to a `kubectl` or `oc` binary | `$PATH/oc` |
| `istio.dest` | The directory of the target machine where Istio will be installed | Any directory with read+write permissions | `~/.istio` |
| `istio.auth` | Install with mutual TLS | `true` or `false` | `false` |
| `istio.namespace` | Kubernetes namespace where Istio will be installed | any namespace may be specified | `istio-system` |
| `istio.addon` | Istio addons to install | array containing any of `kiali` | Istio already installs `grafana`, `prometheus`, `jaeger` bye default |
| `istio.delete_resources` | Delete resources created under Istio namespace | `true` or `false` | false |
| `istio.samples` | Array containing the names of the samples that should be installed | `bookinfo`, `helloworld`, `httpbin`, `sleep` | none |

## Default installation

Operator installs Istio using all defaults on OpenShift:

{{< text bash >}}
$ ansible-playbook main.yml
{{< /text >}}

## Operational overrides

There may be circumstances in which defaults require overrides.

The following commands describe how an operator could use overrides with this Ansible playbook:

Operator installs Istio on Kubernetes:

{{< text bash >}}
$ ansible-playbook main.yml -e '{"cluster_flavour": "k8s"}'
{{< /text >}}

Operator installs Istio on Kubernetes and the path to `kubectl` is explicitly set:

{{< text bash >}}
$ ansible-playbook main.yml -e '{"cluster_flavour": "k8s", "cmd_path": "~/kubectl"}'
{{< /text >}}

Operator installs Istio on OpenShift with settings other than the default:

{{< text bash >}}
$ ansible-playbook main.yml -e '{"istio": {"auth": true, "delete_resources": true}}'
{{< /text >}}

Operator installs Istio on OpenShift with customized addons:

{{< text bash >}}
$ ansible-playbook main.yml -e '{"istio": {"delete_resources": true, "addon": ["kiali"]}}'
{{< /text >}}

Operator installs Istio on OpenShift and additionally wants to deploy some of the samples:

{{< text bash >}}
$ ansible-playbook main.yml -e '{"istio": {"samples": ["helloworld", "bookinfo"]}}'
{{< /text >}}

## Uninstalling

If a different version of Istio is desired, delete the `istio-system` namespace before executing the playbook.
In this case, the `istio.delete_resources` flag does not need to be set.

Setting `istio.delete_resources` to true will delete the Istio control plane from the cluster.

> In order to avoid any inconsistencies, this flag should only be used to reinstall the same version of Istio on a cluster.

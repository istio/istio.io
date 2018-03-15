---
title: Installing with Ansible
overview: Instructions on using the included Ansible playbook to perform installation.

order: 40

layout: docs
type: markdown
---
{% include home.html %}

The Ansible scenario defined within this project will allow you to : 

- Deploy Istio on Kubernetes or Openshift by specifying different parameters (version, enable auth, deploy bookinfo, ...)
- Specify the addons to be deployed such as `Grafana`, `Prometheus`, `Servicegraph`, `Zipkin` or `Jaeger`

## Prerequisites

- [Ansible 2.4](https://docs.ansible.com/ansible/latest/intro_installation.html)

Refer to the Ansible Installation Doc on how to install Ansible on your machine.
To use [Minishift](https://docs.openshift.org/latest/minishift/command-ref/minishift_start.html) or [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) for local clusters, please refer to their respective documentation.

Furthermore, the following requirements must be met for the respective clusters 
* Kubernetes:
    - Minimum Version: `1.7.2`
    - `kubectl` configured to be able to access the cluster
* Openshift 
    - Minimum Version: `3.7.0` 
    - `oc` configured to be able to access the cluster
    - User has logged in to the cluster
    - User has `admin` role on the Openshift platform    

## Execution

**Important**: All invocations of the Ansible playbooks need to take place at the `install/ansible` path of the project.
Failing to do so will result in unexpected errors 

The simplest execution command looks like the following:
 
```bash
ansible-playbook main.yml
```

Remarks:
- This Ansible playbook is idempotent. If you find examples of lacking idempotency please file a bug.   
- The default parameters that apply to this role can be found in `istio/defaults/main.yml`.

The full list of configurable parameters is as follows:

| Parameter | Description | Values |
| --- | --- | --- |
| `cluster_flavour` | Defines whether the target cluster is a Kubernetes or an Openshift cluster. | Valid values are `k8s` and `ocp` (default) |
| `github_api_token` | The API token used for authentication when calling the GitHub API | Any valid GitHub API token or empty (default) |
| `cmd_path` | Can be used when the user does not have the `oc` or `kubectl` binary on the PATH | Defaults to expecting the binary is on the path | 
| `istio.release_tag_name` | Should be a valid Istio release version. If left empty, the latest Istio release will be installed | `0.2.12`, `0.3.0`, `0.4.0`, `0.5.0`, `0.5.1` |
| `istio.dest` | The directory of the target machine where Istio will be installed | `~/.istio` (default) |
| `istio.auth` | Boolean value to install Istio using MUTUAL_TLS | `true` and `false` (default) |
| `istio.namespace` | The namespace where Istio will be installed | `istio-system` (default) |
| `istio.addon` | Which Istio addons should be installed as well | This field is an array field, which by default contains `grafana`, `prometheus`, `zipkin` and `servicegraph` |
| `istio.jaeger` | Whether or not Jaeger tracing should also be installed | `true` and `false` (default)|
| `istio.delete_resources` | Boolean value to delete resources created under the Istio namespace | `true` and `false` (default)|
| `istio.samples` | Array containing the names of the samples that should be installed | Valid names are: `bookinfo`, `helloworld`, `httpbin`, `sleep`


An example of an invocation where we want to deploy Jaeger instead of Zipkin would be:
```bash
ansible-playbook main.yml -e '{"istio": {"jaeger": true}}'
```


This playbook will take care of downloading and installing Istio locally on your machine, before deploying the necessary Kubernetes / Openshift
pods, services etc. on to the cluster.

### Note on istio.delete_resources

Activating the `istio.delete_resources` flag will result in any Istio related resources being deleted from the cluster before Istio is reinstalled.

In order to avoid any inconsistency issues, this flag should only be used to reinstall the same version of Istio on a cluster. If a new version
of Istio need to be reinstalled, then it is advisable to delete the `istio-system` namespace before executing the playbook (in which case the 
`istio.delete_resources` flag does not need to be activated)  

## Typical use cases

The following commands are some examples of how a user could install Istio using this Ansible role:

- User executes installs Istio accepting all defaults
```bash
ansible-playbook main.yml
```

- User installs Istio on to a Kubernetes cluster 
```bash
ansible-playbook main.yml -e '{"cluster_flavour": "k8s"}' 
```

- User installs Istio on to a Kubernetes cluster and the path to `kubectl` is expicitly set (perhaps it's not on the PATH)
```bash
ansible-playbook main.yml -e '{"cluster_flavour": "k8s", "cmd_path": "~/kubectl"}' 
```

- User wants to install Istio on Openshift with settings other than the default
```bash
ansible-playbook main.yml -e '{"istio": {"release_tag_name": "0.4.0", "auth": true, "jaeger": true, "delete_resources": true}}'
```

- User wants to install Istio on Openshift but with custom add-on settings
```bash
ansible-playbook main.yml -e '{"istio": {"delete_resources": true, "addon": ["grafana", "prometheus"]}}'
```

- User wants to install Istio on Openshift and additionally wants to deploy some of the samples
```bash
ansible-playbook main.yml -e '{"istio": {"samples": ["helloworld", "bookinfo"]}}'
```

The list of available addons can be found at `istio/vars.main.yml` under the name `istio_all_addons`.
Jaeger is not installed using the `addons` property, but can be installed by enabling `"jaeger": true` like in one of the previous examples.
It should be noted that when Jaeger is enabled, Zipkin is disabled whether or not it's been selected in the addons section.

## Adding istioctl to PATH

After executing the playbook if it is desired that the `istioctl` command line tool be added to the PATH,
search for `Add Istio to PATH` in the output and execute the commands that are outputted  
---
title: Getting Started
description: Download and install Istio.
weight: 5
aliases:
    - /docs/setup/kubernetes/download-release/
    - /docs/setup/kubernetes/download/
keywords: [kubernetes]
---

Istio offers multiple installation options depending on your platform and
whether or not you intend to use Istio in production.

- [Demo installation](/docs/setup/kubernetes/install/kubernetes/):
   This option is ideal if you're new to Istio and just want to try it out.
   It allows you to experiment with many Istio features with modest resource requirements.

- [Custom installation with Helm](/docs/setup/kubernetes/install/helm/):
   This option is ideal to install Istio for production use or for performance evaluation.

- [Supported platform installation](/docs/setup/kubernetes/install/platform/):
   This option is ideal if your platform provides native support for Istio-enabled clusters
   with a [configuration profile](/docs/setup/kubernetes/additional-setup/config-profiles/)
   corresponding to your intended use.

After choosing an option and installing Istio on your cluster, you can deploy
your own application or experiment with some of our [tasks](/docs/tasks/) and [examples](/docs/examples/).

{{< tip >}}
If you're running your own application, make sure to
check the [requirements for pods and services](/docs/setup/kubernetes/additional-setup/requirements/).
{{< /tip >}}

When you're ready to consider more advanced Istio use cases, check out the following resources:

- To install using Istio's Container Network Interface
(CNI) plugin, visit our [CNI guide](/docs/setup/kubernetes/additional-setup/cni/).

- To perform a multicluster setup, visit our
[multicluster installation documents](/docs/setup/kubernetes/install/multicluster/).

- To expand your existing mesh with additional containers or VMs not running on
your mesh's Kubernetes cluster, follow our [mesh expansion guide](/docs/setup/kubernetes/additional-setup/mesh-expansion/).

- To add services requires detailed understanding of sidecar injection. Visit our
[sidecar injection guide](/docs/setup/kubernetes/additional-setup/sidecar-injection/)
to learn more.

## Downloading the release

Istio is installed in its own `istio-system` namespace and can manage
services from all other namespaces.

1.  Go to the [Istio release](https://github.com/istio/istio/releases) page to
    download the installation file corresponding to your OS. On a macOS or
    Linux system, you can run the following command to download and
    extract the latest release automatically:

    {{< text bash >}}
    $ curl -L https://git.io/getLatestIstio | ISTIO_VERSION={{< istio_full_version >}} sh -
    {{< /text >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text bash >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Installation YAML files for Kubernetes in `install/`
    - Sample applications in `samples/`
    - The `istioctl` client binary in the `bin/` directory. `istioctl` is
      used when manually injecting Envoy as a sidecar proxy.
    - The `istio.VERSION` configuration file

1.  Add the `istioctl` client to your `PATH` environment variable, on a macOS or
    Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Enabling `istioctl` tab completion

If you are using Bash or ZSH, `istioctl` includes a helpful script that enables tab completion for the currently available `istioctl` commands.

### Installing the `istioctl` tab completion file

If you are using Bash, the `istioctl` tab completion file is located in the `tools` directory. To use it, copy the `istioctl.bash` file to your home directory, then add the following line to source the `istioctl` tab completion file from your `.bashrc` file:

{{< text bash >}}
$ source ~/istioctl.bash
{{< /text >}}

For ZSH users, an additional `istioctl` tab completion file is also located in the `tools` directory. In a similar fashion, you can copy the `_istioctl` file to your home directory, then source the `istioctl` tab completion file as follows:

{{< text zsh >}}
$ source < _istioctl
{{< /text >}}

{{< tip >}}
If you get an error like `complete:13: command not found: compdef`, then add the following to the beginning of your `~/.zshrc` file:

{{< text bash >}}
$ autoload -Uz compinit
$ compinit
{{< /text >}}

{{< /tip >}}

You may also add the `_istioctl` file to a directory listed in the `FPATH` variable. To achieve this, place the `_istioctl` file in an existing directory in the `FPATH`, or create a new directory and add it to the `FPATH` variable in your `~/.zshrc` file.

### Prerequisites for macOS

If you are using macOS with the Bash shell, make sure that the `bash-completion` package is installed. If you are using the [brew](https://brew.sh) package manager for macOS, you can check to see if the `bash-completion` package is installed with the following command:

{{< text bash >}}
$ brew info bash-completion
bash-completion: stable 1.3 (bottled)
{{< /text >}}

If the bash-completion package is _not_ installed, proceed with installing the bash-completion package with the following command:

{{< text bash >}}
$ brew install bash-completion
{{< /text >}}

{{< tip >}}
Once the bash-completion package has been installed on your macOS system, also make sure to add the following line to your `~/.bash_profile` file:

`[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"`
{{< /tip >}}

### Prerequisites for Linux

For Linux, to install the bash completion package, you would use the `apt-get install bash-completion` command for Debian-based Linux distributions or `yum install bash-completion` for RPM-based Linux distributions, the two most common occurrences.

## Using `istioctl` auto-completion

If the `istioctl` completion file has been installed correctly, press the Tab key while writing an `istioctl` command, and it should return a set of command suggestions for you to choose from:

{{< text bash >}}
$ istioctl proxy-<TAB>
proxy-config proxy-status
{{< /text >}}

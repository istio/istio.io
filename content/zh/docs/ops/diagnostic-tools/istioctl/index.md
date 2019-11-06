---
title: Using the Istioctl Command-line Tool
description: Istio includes a supplemental tool that provides debugging and diagnosis for Istio service mesh deployments.
weight: 10
keywords: [istioctl,bash,zsh,shell,command-line]
aliases:
  - /help/ops/component-debugging
  - /docs/ops/troubleshooting/istioctl
---

## Overview

You can gain insights into what individual components are doing by inspecting their [logs](/docs/ops/diagnostic-tools/component-logging/)
or peering inside via [introspection](/docs/ops/diagnostic-tools/controlz/). If that's insufficient, the steps below explain
how to get under the hood.

The [`istioctl`](/docs/reference/commands/istioctl) tool is a configuration command line utility that allows service operators to debug and diagnose their Istio service mesh deployments. The Istio project also includes two helpful scripts for `istioctl` that enable auto-completion for Bash and ZSH. Both of these scripts provide support for the currently available `istioctl` commands.

{{< tip >}}
`istioctl` only has auto-completion enabled for non-deprecated commands.
{{< /tip >}}

### Get an overview of your mesh

You can get an overview of your mesh using the `proxy-status` command:

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

If a proxy is missing from the output list it means that it is not currently connected to a Pilot instance and so it
will not receive any configuration. Additionally, if it is marked stale, it likely means there are networking issues or
Pilot needs to be scaled.

### Get proxy configuration

[`istioctl`](/docs/reference/commands/istioctl) allows you to retrieve information about proxy configuration using the `proxy-config` or `pc` command.

For example, to retrieve information about cluster configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config cluster <pod-name> [flags]
{{< /text >}}

To retrieve information about bootstrap configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config bootstrap <pod-name> [flags]
{{< /text >}}

To retrieve information about listener configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config listener <pod-name> [flags]
{{< /text >}}

To retrieve information about route configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config route <pod-name> [flags]
{{< /text >}}

To retrieve information about endpoint configuration for the Envoy instance in a specific pod:

{{< text bash >}}
$ istioctl proxy-config endpoints <pod-name> [flags]
{{< /text >}}

See [Debugging Envoy and Pilot](/docs/ops/diagnostic-tools/proxy-cmd/) for more advice on interpreting this information.

## `istioctl` auto-completion

{{< tabset cookie-name="prereqs" >}}

{{< tab name="macOS" cookie-value="macos" >}}

If you are using the macOS operating system with the Bash terminal shell, make sure that the `bash-completion` package is installed. With the [brew](https://brew.sh) package manager for macOS, you can check to see if the `bash-completion` package is installed with the following command:

{{< text bash >}}
$ brew info bash-completion
bash-completion: stable 1.3 (bottled)
{{< /text >}}

If you find that the `bash-completion` package is _not_ installed, proceed with installing the `bash-completion` package with the following command:

{{< text bash >}}
$ brew install bash-completion
{{< /text >}}

Once the `bash-completion package` has been installed on your macOS system, add the following line to your `~/.bash_profile` file:

{{< text plain >}}
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
{{< /text >}}

{{< /tab >}}

{{< tab name="Linux" cookie-value="linux" >}}

If you are using a Linux-based operating system, you can install the Bash completion package with the `apt-get install bash-completion` command for Debian-based Linux distributions or `yum install bash-completion` for RPM-based Linux distributions, the two most common occurrences.

Once the `bash-completion` package has been installed on your Linux system, add the following line to your `~/.bash_profile` file:

{{< text plain >}}
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Enabling auto-completion

To enable `istioctl` completion on your system, follow the steps for your preferred shell:

{{< tabset cookie-name="profile" >}}

{{< tab name="Bash" cookie-value="bash" >}}

Installing the bash auto-completion file

If you are using bash, the `istioctl` auto-completion file is located in the `tools` directory. To use it, copy the `istioctl.bash` file to your home directory, then add the following line to source the `istioctl` tab completion file from your `.bashrc` file:

{{< text bash >}}
$ source ~/istioctl.bash
{{< /text >}}

{{< /tab >}}

{{< tab name="ZSH" cookie-value="zsh" >}}

Installing the ZSH auto-completion file

For ZSH users, the `istioctl` auto-completion file is located in the `tools` directory. Copy the `_istioctl` file to your home directory, or any directory of your choosing (update directory in script snippet below), and source the `istioctl` auto-completion file in your `.zshrc` file as follows:

{{< text zsh >}}
source ~/_istioctl
{{< /text >}}

You may also add the `_istioctl` file to a directory listed in the `fpath` variable. To achieve this, place the `_istioctl` file in an existing directory in the `fpath`, or create a new directory and add it to the `fpath` variable in your `~/.zshrc` file.

{{< tip >}}

If you get an error like `complete:13: command not found: compdef`, then add the following to the beginning of your `~/.zshrc` file:

{{< text bash >}}
$ autoload -Uz compinit
$ compinit
{{< /text >}}

If your auto-completion is not working, try again after restarting your terminal. If auto-completion still does not work, try resetting the completion cache using the above commands in your terminal.

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

### Using auto-completion

If the `istioctl` completion file has been installed correctly, press the Tab key while writing an `istioctl` command, and it should return a set of command suggestions for you to choose from:

{{< text bash >}}
$ istioctl proxy-<TAB>
proxy-config proxy-status
{{< /text >}}

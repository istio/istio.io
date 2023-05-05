---
title: Using the Istioctl Command-line Tool
description: Istio includes a supplemental tool that provides debugging and diagnosis for Istio service mesh deployments.
weight: 10
keywords: [istioctl,bash,zsh,shell,command-line]
aliases:
  - /help/ops/component-debugging
  - /docs/ops/troubleshooting/istioctl
owner: istio/wg-user-experience-maintainers
test: no
---

You can gain insights into what individual components are doing by inspecting their [logs](/docs/ops/diagnostic-tools/component-logging/)
or peering inside via [introspection](/docs/ops/diagnostic-tools/controlz/). If that's insufficient, the steps below explain
how to get under the hood.

The [`istioctl`](/docs/reference/commands/istioctl) tool is a configuration command line utility that allows service operators to debug and diagnose their Istio service mesh deployments. The Istio project also includes two helpful scripts for `istioctl` that enable auto-completion for Bash and Zsh. Both of these scripts provide support for the currently available `istioctl` commands.

{{< tip >}}
`istioctl` only has auto-completion enabled for non-deprecated commands.
{{< /tip >}}

## Before you begin

We recommend you use an `istioctl` version that is the same version as your Istio control plane. Using matching versions helps avoid unforeseen issues.

{{< tip >}}
If you have already [downloaded the Istio release](/docs/setup/getting-started/#download), you should
already have `istioctl` and do not need to install it again.
{{< /tip >}}

## Install {{< istioctl >}}

Install the `istioctl` binary with `curl`:

1. Download the latest release with the command:

    {{< text bash >}}
    $ curl -sL https://istio.io/downloadIstioctl | sh -
    {{< /text >}}

1. Add the `istioctl` client to your path, on a macOS or Linux system:

    {{< text bash >}}
    $ export PATH=$HOME/.istioctl/bin:$PATH
    {{< /text >}}

1. You can optionally enable the [auto-completion option](#enabling-auto-completion) when working with a bash or Zsh console.

## Get an overview of your mesh

You can get an overview of your mesh using the `proxy-status` or `ps` command:

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

If a proxy is missing from the output list it means that it is not currently connected to a Pilot instance and so it
will not receive any configuration. Additionally, if it is marked stale, it likely means there are networking issues or
Pilot needs to be scaled.

## Get proxy configuration

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

See [Debugging Envoy and Istiod](/docs/ops/diagnostic-tools/proxy-cmd/) for more advice on interpreting this information.

## `istioctl` auto-completion

{{< tabset category-name="prereqs" >}}

{{< tab name="macOS" category-value="macos" >}}

If you are using the macOS operating system with the Zsh terminal shell, make sure that the `zsh-completions` package is installed. With the [brew](https://brew.sh) package manager for macOS, you can check to see if the `zsh-completions` package is installed with the following command:

{{< text bash >}}
$ brew list zsh-completions
/usr/local/Cellar/zsh-completions/0.34.0/share/zsh-completions/ (147 files)
{{< /text >}}

If you receive `Error: No such keg: /usr/local/Cellar/zsh-completion`, proceed with installing the `zsh-completions` package with the following command:

{{< text bash >}}
$ brew install zsh-completions
{{< /text >}}

Once the `zsh-completions package` has been installed on your macOS system, add the following to your `~/.zshrc` file:

{{< text plain >}}
    if type brew &>/dev/null; then
      FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

      autoload -Uz compinit
      compinit
    fi
{{< /text >}}

You may also need to force rebuild `zcompdump`:

{{< text bash >}}
$ rm -f ~/.zcompdump; compinit
{{< /text >}}

Additionally, if you receive `Zsh compinit: insecure directories` warnings when attempting to load these completions, you may need to run this:

{{< text bash >}}
$ chmod -R go-w '$HOMEBREW_PREFIX/share/zsh'
{{< /text >}}

{{< /tab >}}

{{< tab name="Linux" category-value="linux" >}}

If you are using a Linux-based operating system, you can install the Bash completion package with the `apt-get install bash-completion` command for Debian-based Linux distributions or `yum install bash-completion` for RPM-based Linux distributions, the two most common occurrences.

Once the `bash-completion` package has been installed on your Linux system, add the following line to your `~/.bash_profile` file:

{{< text plain >}}
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Enabling auto-completion

To enable `istioctl` completion on your system, follow the steps for your preferred shell:

{{< warning >}}
You will need to download the full Istio release containing the auto-completion files (in the `/tools` directory). If you haven't already done so, [download the full release](/docs/setup/getting-started/#download) now.
{{< /warning >}}

{{< tabset category-name="profile" >}}

{{< tab name="Bash" category-value="bash" >}}

Installing the bash auto-completion file

If you are using bash, the `istioctl` auto-completion file is located in the `tools` directory. To use it, copy the `istioctl.bash` file to your home directory, then add the following line to source the `istioctl` tab completion file from your `.bashrc` file:

{{< text bash >}}
$ source ~/istioctl.bash
{{< /text >}}

{{< /tab >}}

{{< tab name="Zsh" category-value="zsh" >}}

Installing the Zsh auto-completion file

For Zsh users, the `istioctl` auto-completion file is located in the `tools` directory. Copy the `_istioctl` file to your home directory, or any directory of your choosing (update directory in script snippet below), and source the `istioctl` auto-completion file in your `.zshrc` file as follows:

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

---
title: istioctl auto-completion
description: Istio includes a helpful script that enables auto-completion for the currently available istioctl commands.
weight: 20
keywords: [istioctl,bash,zsh,shell,command-line]
---

`istioctl` includes two helpful scripts that enable auto-completion for Bash and ZSH. Both of these scripts provide support the currently available `istioctl` commands.

### Prerequisites

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

Once the `bash-completion package` has been installed on your macOS system, also make sure to add the following line to your `~/.bash_profile` file:

`[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"`

{{< /tab >}}

{{< tab name="Linux" cookie-value="linux" >}}

If you are using a Linux-based operating system, you can install the Bash completion package with the `apt-get install bash-completion` command for Debian-based Linux distributions or `yum install bash-completion` for RPM-based Linux distributions, the two most common occurrences.

Once the `bash-completion` package has been installed on your Linux system, also make sure to add the following line to your `~/.bash_profile` file:

`[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"`

{{< /tab >}}

{{< /tabset >}}

## Enabling `istioctl` auto-completion

To enable `istioctl` completion on your system, follow the steps for your preferred shell:

{{< tabset cookie-name="profile" >}}

{{< tab name="Bash" cookie-value="bash" >}}

### Installing the bash auto-completion file

If you are using bash, the `istioctl` auto-completion file is located in the `tools` directory. To use it, copy the `istioctl.bash` file to your home directory, then add the following line to source the `istioctl` tab completion file from your `.bashrc` file:

{{< text bash >}}
$ source ~/istioctl.bash
{{< /text >}}

{{< /tab >}}

{{< tab name="ZSH" cookie-value="zsh" >}}

### Installing the ZSH auto-completion file

For ZSH users, the `istioctl` auto-completion file is located in the `tools` directory. Copy the `_istioctl` file to your home directory, then source the `istioctl` auto-completion file as follows:

{{< text zsh >}}
source < _istioctl
{{< /text >}}

{{< tip >}}

If you get an error like `complete:13: command not found: compdef`, then add the following to the beginning of your `~/.zshrc` file:

{{< text bash >}}
$ autoload -Uz compinit
$ compinit
{{< /text >}}

{{< /tip >}}

You may also add the `_istioctl` file to a directory listed in the `FPATH` variable. To achieve this, place the `_istioctl` file in an existing directory in the `FPATH`, or create a new directory and add it to the `FPATH` variable in your `~/.zshrc` file.

{{< /tab >}}

{{< /tabset >}}

## Using `istioctl` auto-completion

If the `istioctl` completion file has been installed correctly, press the Tab key while writing an `istioctl` command, and it should return a set of command suggestions for you to choose from:

{{< text bash >}}
$ istioctl proxy-<TAB>
proxy-config proxy-status
{{< /text >}}

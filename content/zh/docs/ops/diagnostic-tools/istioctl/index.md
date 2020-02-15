---
title: 使用 Istioctl 命令行工具
description: Istio 自带的一个可以为服务网格部署提供调试和诊断的补充工具。
weight: 10
keywords: [istioctl,bash,zsh,shell,command-line]
aliases:
 - /zh/help/ops/component-debugging
 - /zh/docs/ops/troubleshooting/istioctl
---

您可以通过检查各个组件的[日志](/zh/docs/ops/diagnostic-tools/component-logging/)或者通过[自检](/zh/docs/ops/diagnostic-tools/controlz/)机制来了解其功能。如果还不够的话，以下步骤将会告诉您如何深入了解。

[`Istioctl`](/zh/docs/reference/commands/istioctl) 是一个允许服务管理者调试和诊断服务网格应用的命令行配置工具。Istio 项目还提供了两个在 Bash 和 ZSH 环境下用于自动补全 `istioctl` 命令的脚本。这两个脚本均支持当前可用的 `istioctl` 命令。

{{< tip >}}
`Istioctl` 只对没有弃用的命令开启了自动补全的功能。
{{< /tip >}}

## 开始之前 {#before-you-begin}

我们建议您使用与 Istio 控制平面相匹配的 `istioctl` 版本。
使用相匹配的版本有助于避免产生意外的问题。

{{< tip >}}
如果您已经[下载 Istio 发行版](/zh/docs/setup/getting-started/#download)，则应该已经具有 `istioctl`，而无需再次安装。
{{< /tip >}}

## 安装 {{< istioctl >}}

用 `curl` 安装 `istioctl` 二进制文件:

1. 使用以下命令下载最新版本:

    {{< text bash >}}
    $ curl -sL https://istio.io/downloadIstioctl | sh -
    {{< /text >}}

1. 在 macOS 或 Linux 系统上，将 `istioctl` 添加到您的环境变量 PATH 中:

    {{< text bash >}}
    $ export PATH=$PATH:$HOME/.istioctl/bin
    {{< /text >}}

1. 使用 bash 或 ZSH 控制台时，可以选择启用[命令自动补全选项](#enabling-auto-completion)。

## 网格概览 {#get-an-overview-of-your-mesh}

您可以使用 `proxy-status` 或 `ps` 命令概览您的网格：

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

如果输出列表中缺少某个代理则意味着它当前未连接到 Polit 实例，所以它无法接收到任何配置。此外，如果它被标记为 stale，则意味着存在网络问题或者需要扩展 Pilot。

## 代理配置 {#get-proxy-configuration}

[`Istioctl`](/zh/docs/reference/commands/istioctl) 允许你使用 `proxy-config` 或者 `pc` 命令检索代理的配置信息。

例如检索特定 pod 中 Envoy 实例的集群配置的信息：

{{< text bash >}}
$ istioctl proxy-config cluster <pod-name> [flags]
{{< /text >}}

检索特定 pod 中 Envoy 实例的 bootstrap 配置的信息：

{{< text bash >}}
$ istioctl proxy-config bootstrap <pod-name> [flags]
{{< /text >}}

检索特定 pod 中 Envoy 实例的监听器配置的信息：

{{< text bash >}}
$ istioctl proxy-config listener <pod-name> [flags]
{{< /text >}}

检索特定 pod 中 Envoy 实例的路由配置的信息：

{{< text bash >}}
$ istioctl proxy-config route <pod-name> [flags]
{{< /text >}}

检索特定 pod 中 Envoy 实例的 endpoint 配置的信息：

{{< text bash >}}
$ istioctl proxy-config endpoints <pod-name> [flags]
{{< /text >}}

有关上述命令描述的更多信息，请参考[调试 Envoy 和 Pilot](/zh/docs/ops/diagnostic-tools/proxy-cmd/).

## `Istioctl` 自动补全 {#auto-completion}

{{< tabset category-name="prereqs" >}}

{{< tab name="macOS" category-value="macos" >}}

如果您使用的是 macOS 操作系统的Bash终端，确认已安装 `bash-completion` 包。使用 macOS 下 [brew](https://brew.sh) 包管理器，您可以通过以下命令检查 `bash-completion` 包是否已经安装：

{{< text bash >}}
$ brew info bash-completion
bash-completion: stable 1.3 (bottled)
{{< /text >}}

如果您还未安装 `bash-completion` 包，可以通过以下命令进行安装：

{{< text bash >}}
$ brew install bash-completion
{{< /text >}}

当 `bash-completion` 包被安装到您的 macOS 系统以后，添加下行内容到您的 `~/.bash_profile` 中：

{{< text plain >}}
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
{{< /text >}}

{{< /tab >}}

{{< tab name="Linux" category-value="linux" >}}

如果您使用基于 Linux 的操作系统，以两种最常见的情况举例，您可以使用 `apt-get install bash-completion` 命令安装基于 Debian 的 Linux 发行版的 base-completion 包，或者使用 `yum install bash-completion` 安装基于 RPM 的 Linux 发行版的包。

当 `bash-completion` 包被安装到您的 Linux 系统以后，添加下行内容到您的 `~/.bash_profile` 中：

{{< text plain >}}
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 开启自动补全 {#enabling-auto-completion}

根据您选择的 shell，按照以下步骤在您的系统开启 `istioctl` 命令补全 :

{{< tabset category-name="profile" >}}

{{< tab name="Bash" category-value="bash" >}}

安装 bash 自动补全文件

如果您使用 bash，`istioctl` 自动补全的文件位于 `tools` 目录。通过复制 `istioctl.bash` 文件到您的 home 目录，然后添加下行内容到您的 `.bashrc` 文件执行 `istioctl` tab补全文件：

{{< text bash >}}
$ source ~/istioctl.bash
{{< /text >}}

{{< /tab >}}

{{< tab name="ZSH" category-value="zsh" >}}

安装 ZSH 自动补全文件

对于 ZSH 用户，`istioctl` 自动补全文件位于 `tools` 目录。复制 `_istioctl` 文件到你的 home 目录或者你选择的任何目录(同时更新下面脚本目录)，并且在您的 `.zshrc` 文件添加以下命令执行 `istioctl` 自动补全文件：

{{< text zsh >}}
source ~/_istioctl
{{< /text >}}

您也可以添加 `_istioctl` 文件到 `fpath` 变量包含的目录列表中。为此，可以通过复制 `_istioctl` 文件到 `fpath` 中已存在的目录，或者创建一个新目录并将它添加到您的 `~/.zshrc` 文件中的 `fpath` 变量。

{{< tip >}}

如果您遇到类似 `complete:13: command not found: compdef` 错误，可以添加以下内容到您的 `~/.zshrc` 文件开头：

{{< text bash >}}
$ autoload -Uz compinit
$ compinit
{{< /text >}}

如果您的自动补全没有生效，在重启您的终端后再试。如果自动补全还是没有生效，试着在您的终端运行上述命令重置自动补全的缓存。

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

### 使用自动补全 {#using-auto-completion}

如果 `istioctl` 补全文件已经正确安装，在您输入 `istioctl` 命令时通过按 Tab 键，它会返回一组推荐命令供您选择：

{{< text bash >}}
$ istioctl proxy-<TAB>
proxy-config proxy-status
{{< /text >}}

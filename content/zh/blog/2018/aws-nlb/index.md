---
title: 使用 AWS NLB 配置 Istio Ingress
description: 描述如何在 AWS 上使用网络负载均衡器配置 Istio Ingress。
publishdate: 2018-04-20
last_update: 2019-01-16
subtitle: Ingress AWS 网络负载均衡器
attribution: Julien SENON
keywords: [ingress,traffic-management,aws]
target_release: 1.0
---

{{< tip >}}
本文已于 2019 年 1 月 16 日更新，其中包含一些使用警告。
{{< /tip >}}

本文提供了使用 [AWS 网络负载均衡器](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html)配置 Ingress Istio 的说明。

可以使用网络负载均衡器 (NLB) 来代替传统的负载均衡器。您可以查看不同的 AWS `负载均衡器` 之间的[比较](https://aws.amazon.com/elasticloadbalancing/details/#Product_comparisons)以获取更多的解释。

## 先行条件{#prerequisites}

以下说明需要 Kubernetes **1.9.0 或更高版本** 的集群。

{{< warning >}}
在 Kubernetes上 使用 AWS `nlb` 是一个 Alpha 功能，不建议用于生产环境的集群。

由于 [Kubernetes Bug #6926](https://github.com/kubernetes/kubernetes/issues/69264)中的问题，AWS `nlb` 的使用不支持在同一区域创建两个或多个运行 Istio 的 Kubernetes 集群。
{{< /warning >}}

## IAM Policy

您需要在主角色上应用策略，以便能够配置网络负载均衡器。

1. 在 AWS `iam` 控制台中，点击策略并单击“创建新策略”：

    {< image width="80%" link="./createpolicystart.png" caption="Create a new policy" >}}

1. 选择 `json`：

    {{{< image width="80%" link="./createpolicyjson.png" caption="Select json" >}}

1. 拷贝以下内容：

    {{< text json >}}
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "kopsK8sNLBMasterPermsRestrictive",
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeVpcs",
                    "elasticloadbalancing:AddTags",
                    "elasticloadbalancing:CreateListener",
                    "elasticloadbalancing:CreateTargetGroup",
                    "elasticloadbalancing:DeleteListener",
                    "elasticloadbalancing:DeleteTargetGroup",
                    "elasticloadbalancing:DescribeListeners",
                    "elasticloadbalancing:DescribeLoadBalancerPolicies",
                    "elasticloadbalancing:DescribeTargetGroups",
                    "elasticloadbalancing:DescribeTargetHealth",
                    "elasticloadbalancing:ModifyListener",
                    "elasticloadbalancing:ModifyTargetGroup",
                    "elasticloadbalancing:RegisterTargets",
                    "elasticloadbalancing:SetLoadBalancerPoliciesOfListener"
                ],
                "Resource": [
                    "*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeVpcs",
                    "ec2:DescribeRegions"
                ],
                "Resource": "*"
            }
        ]
    }
    {{< /text >}}

1. 点击审核策略，填写所有字段，接着点击创建策略：

    {{< image width="80%" link="./create_policy.png" caption="Validate policy" >}}

1. 点击角色，选择您的主角色节点，然后点击附加策略：

    {{< image link="./roles_summary.png" caption="Attach policy" >}}

1. 现在，您的策略就已经附加到了主节点。

## 重写 Istio Ingress 服务{#generate-the-Istio-manifest}

要使用 AWS `nlb` 负载平衡器，必须在 Istio 安装中添加一个 AWS 特定的注释。 这些说明解释了如何添加注释。

将其保存为文件 `override.yaml`：
您需要使用以下内容来重写 `istio-ingress` 服务：

{{< text yaml >}}
gateways:
  istio-ingressgateway:
    serviceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
{{< /text >}}

使用 Helm 生成清单：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --namespace istio -f override.yaml > $HOME/istio.yaml
{{< /text >}}

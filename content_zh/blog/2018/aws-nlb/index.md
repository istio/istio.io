---
title: 使用AWS NLB 配置 Istio Ingress
description: 描述如何在AWS上使用网络负载均衡器配置 Istio Ingress
publishdate: 2018-04-20
subtitle: Ingress AWS 网络负载均衡器
attribution: Julien SENON
weight: 89
keywords: [ingress,traffic-management,aws]
---

本文提供了使用 [AWS 网络负载均衡器](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) 配置 ingress Istio 的说明。

可以使用网络负载均衡器 (NLB) 来代替传统的负载均衡器。 你可以查看不同的 AWS `负载均衡器` 之间的 [比较](https://aws.amazon.com/elasticloadbalancing/details/#compare)以获取更多的解释。

## 先行条件

以下说明需要 Kubernetes **1.9.0 或更高版本** 的集群。

{{< warning_icon >}} AWS `nlb` 在 Kubernetes 上的使用是一项 Alpha 功能 ，不建议用于生产环境的集群。

## IAM 策略

你需要在主角色上应用策略， 以便能够配置网络负载均衡器。

1. 在 AWS  `iam`  控制台中，点击策略并单击“创建新策略”：

    {{< image width="80%" ratio="60%"
    link="./createpolicystart.png"
    caption="创建一个新的策略"
    >}}

1. 选择  `json`:

    {{< image width="80%" ratio="60%"
    link="./createpolicyjson.png"
    caption="选择 json"
    >}}

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

    {{< image width="80%" ratio="60%"
        link="./create_policy.png"
        caption="验证策略"
        >}}

1. 点击角色，选择你的主角色节点，然后点击附加策略：

    {{< image width="100%" ratio="35%"
    link="./roles_summary.png"
    caption="附加策略"
    >}}

1. 现在，你的策略就已经附加到了主节点。

## 重写 Istio Ingress 服务

你需要使用以下内容来重写 istio ingress 服务：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: istio-ingress
  namespace: istio-system
  labels:
    istio: ingress
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  externalTrafficPolicy: Local
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    name: http
  - port: 443
    protocol: TCP
    targetPort: 443
    name: https
    selector:
    istio: ingress
    type: LoadBalancer
{{< /text >}}

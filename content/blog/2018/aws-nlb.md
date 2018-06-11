---
title: Configuring Istio Ingress with AWS NLB
description: Describes how to configure Istio ingress with a network load balancer on AWS
publishdate: 2018-04-20
subtitle: Ingress AWS Network Load Balancer
attribution: Julien SENON
weight: 89
keywords: [ingress,traffic-management,aws]
---

This post provides instructions to use and configure ingress Istio with [AWS Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html).

Network load balancer (NLB) could be used instead of classical load balancer. You can see the [comparison](https://aws.amazon.com/elasticloadbalancing/details/#compare) between different AWS `loadbalancer` for more explanation.

## Prerequisites

The following instructions require a Kubernetes **1.9.0 or newer** cluster.

{{< warning_icon >}} Usage of AWS `nlb` on kubernetes is an alpha feature and not recommended for production clusters.

## IAM Policy

You need to apply policy on the master role in order to be able to provision network load balancer.

1. In AWS `iam` console click on policies and click on create a new one:

    {{< image width="80%" ratio="60%"
    link="../img/createpolicystart.png"
    caption="Create a new policy"
    >}}

1. Select `json`:

    {{< image width="80%" ratio="60%"
    link="../img/createpolicyjson.png"
    caption="Select json"
    >}}

1. Copy/paste text below:

    ```json
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
    ```

1. Click review policy, fill all fields and click create policy:

    {{< image width="80%" ratio="60%"
        link="../img/create_policy.png"
        caption="Validate policy"
        >}}

1. Click on roles, select you master role nodes, and click attach policy:

    {{< image width="100%" ratio="35%"
    link="../img/roles_summary.png"
    caption="Attach policy"
    >}}

1. Your policy is now attach to your master node.

## Rewrite Istio Ingress Service

You need to rewrite ingress service with the following:

```yaml
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
  ```

## What's next

Kubernetes [service networking](https://kubernetes.io/docs/concepts/services-networking/service/) should be consulted if further information is needed.

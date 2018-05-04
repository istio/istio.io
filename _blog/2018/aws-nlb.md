---
title: Configuring Istio Ingress with AWS NLB
description: Describes how to configure Istio ingress with a network load balancer on AWS
publish_date: April 20, 2018
subtitle: Ingress AWS Network Load Balancer
attribution: Julien SENON

weight: 89

redirect_from: "/blog/aws-nlb.html"
---
{% include home.html %}

This blog entry will provide instructions to use and configure ingress Istio with [AWS Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html).

Network load balancer (NLB) could be used instead of classical load balancer. You can find [comparison](https://aws.amazon.com/elasticloadbalancing/details/#compare) between different AWS `loadbalancer` for more explanation.

## Prerequisites

The following instructions require a Kubernetes **1.9.0 or newer** cluster.

<img src="{{home}}/img/exclamation-mark.svg" alt="Warning" title="Warning" style="width: 32px; display:inline" />  Usage of AWS `nlb` on kubernetes is an alpha feature and not recommended for production clusters.

## IAM Policy

You need to apply policy on the master role in order to be able to provision network load balancer.

1. In AWS `iam` console click on policies and click on create a new one:
{% include figure.html width='80%' ratio='60%'
    img='./img/createpolicystart.png'
    alt='Create a new policy'
    title='Create a new policy'
    caption='Create a new policy'
    %}
1. Select `json`:
{% include figure.html width='80%' ratio='60%'
    img='./img/createpolicyjson.png'
    alt='Select json'
    title='Select json'
    caption='Select json'
    %}
1. Copy/paste text bellow:
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
{% include figure.html width='80%' ratio='60%'
    img='./img/create_policy.png'
    alt='Validate policy'
    title='Validate policy'
    caption='Validate policy'
    %}
1. Click on roles, select you master role nodes, and click attach policy:
{% include figure.html width='100%' ratio='35%'
    img='./img/roles_summary.png'
    alt='Attach policy'
    title='Attach policy'
    caption='Attach policy'
    %}
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

---
title: "Configure Istio Ingress with AWS NLB"
overview: Describes how to configure istio ingress with an external load balancer NLB on AWS
publish_date: April 08, 2018
subtitle: Ingress AWS NLB
attribution: Julien SENON

order: 94


layout: blog
type: markdown
redirect_from: "/blog/aws-nlb.html"
---
{% include home.html %}

Instructions to use and configure ingress istio with `aws nlb`.

## Prerequisites

The following instructions require you have access to a Kubernetes **1.9.0 or newer** cluster.

<img src="{{home}}/img/exclamation-mark.svg" alt="Warning" title="Warning" style="width: 32px; display:inline" />  This is an alpha feature and not recommended for production clusters.

## IAM Policy

You need to apply policy in the master role in order to be able to provision network load balancer.

```JSON
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

## Rewrite Istio Ingress Service

You need to rewrite ingress service with following values:

```YAML
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

You can find additional information on [kubernetes website](https://kubernetes.io/docs/concepts/services-networking/service)
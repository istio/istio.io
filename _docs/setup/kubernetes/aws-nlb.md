---
title: AWS NLB
overview: Instructions to use and configure ingress istio with aws NLB.

order: 12

layout: docs
type: markdown
---

{% include home.html %}

Instructions to use and configure ingress istio with aws NLB.

## Prerequisites
The following instructions require you have access to a Kubernetes **1.9.0 or newer** cluster
*Warning:* This is an alpha feature and not recommended for production clusters yet.


## IAM Policy
You need to apply policy in the master roles in order to be able to provition network load balancer

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
You need to rewrite ingress service with folowing values:

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
You can find aditonal information on [kubernetes website](https://kubernetes.io/docs/concepts/services-networking/service)
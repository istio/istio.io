---
title: 멀티클러스터 설치
description: 여러 쿠버네티스 클러스터에 걸쳐 있는 이스티오 메시를 구성한다.
weight: 30
keywords: [kubernetes,multicluster]
test: n/a
---

{{< tip >}}
Note that these instructions are not mutually exclusive.
In a large multicluster deployment, composed from more than two clusters,
a combination of the approaches can be used. For example,
two clusters might share a control plane while a third has its own.
{{< /tip >}}

자세한 내용은 [멀티클러스터 배포 모델](/ko/docs/ops/deployment/deployment-models/#multiple-clusters)
개념 문서를 참조하십시오.

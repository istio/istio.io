---
title: Cleanup
description: Cleanup steps for locality load balancing.
weight: 30
keywords: [locality,load balancing]
test: yes
owner: istio/wg-networking-maintainers
---
Now that you've completed the locality load balancing tasks, let's
cleanup.

## Remove generated files

{{< text bash >}}
$ rm -f sample.yaml helloworld-region*.zone*.yaml
{{< /text >}}

## Remove the `sample` namespace

{{< text bash >}}
$ for CTX in "$CTX_PRIMARY" "$CTX_R1_Z1" "$CTX_R1_Z2" "$CTX_R2_Z3" "$CTX_R3_Z4"; \
  do \
    kubectl --context="$CTX" delete ns sample --ignore-not-found=true; \
  done
{{< /text >}}

**Congratulations!** You successfully completed the locality load balancing task!

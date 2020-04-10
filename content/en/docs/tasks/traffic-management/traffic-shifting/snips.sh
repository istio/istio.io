#!/usr/bin/python

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          /docs/tasks/traffic-management/traffic-shifting/index.md
####################################################################################################

snip_config_all_v1() {
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
}

snip_config_50_v3() {
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
}

snip_verify_config_50_v3() {
kubectl get virtualservice reviews -o yaml
}

! read -r -d '' snip_verify_config_50_v3_out <<ENDSNIP
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
  ...
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v3
      weight: 50
ENDSNIP

snip_config_100_v3() {
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml
}

snip_cleanup() {
kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
}

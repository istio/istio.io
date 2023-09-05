#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/setup/upgrade/canary/index.md
####################################################################################################
source "content/en/boilerplates/snips/revision-tags-middle.sh"
source "content/en/boilerplates/snips/revision-tags-prologue.sh"

snip_before_you_upgrade_1() {
istioctl x precheck
}

! read -r -d '' snip_before_you_upgrade_1_out <<\ENDSNIP
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out https://istio.io/latest/docs/setup/getting-started/
ENDSNIP

snip_control_plane_1() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set revision=canary
}

snip_control_plane_2() {
kubectl get pods -n istio-system -l app=istiod
}

! read -r -d '' snip_control_plane_2_out <<\ENDSNIP
NAME                             READY   STATUS    RESTARTS   AGE
istiod-1-17-1-bdf5948d5-htddg    1/1     Running   0          47s
istiod-canary-84c8d4dcfb-skcfv   1/1     Running   0          25s
ENDSNIP

snip_control_plane_3() {
kubectl get svc -n istio-system -l app=istiod
}

! read -r -d '' snip_control_plane_3_out <<\ENDSNIP
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
istiod-1-17-1   ClusterIP   10.96.93.151     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   109s
istiod-canary   ClusterIP   10.104.186.250   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   87s
ENDSNIP

snip_control_plane_4() {
kubectl get mutatingwebhookconfigurations
}

! read -r -d '' snip_control_plane_4_out <<\ENDSNIP
NAME                            WEBHOOKS   AGE
istio-sidecar-injector-1-17-1   2          2m16s
istio-sidecar-injector-canary   2          114s
ENDSNIP

snip_data_plane_1() {
istioctl proxy-status | grep "$(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items..metadata.name}')" | awk '{print $10}'
}

! read -r -d '' snip_data_plane_1_out <<\ENDSNIP
istiod-canary-6956db645c-vwhsk
ENDSNIP

snip_data_plane_2() {
kubectl label namespace test-ns istio-injection- istio.io/rev=canary
}

snip_data_plane_3() {
kubectl rollout restart deployment -n test-ns
}

snip_data_plane_4() {
istioctl proxy-status | grep "\.test-ns "
}

snip_usage_1() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --revision=1-17-1 --set profile=minimal --skip-confirmation
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --revision=1-18-2 --set profile=minimal --skip-confirmation
}

snip_usage_2() {
istioctl tag set prod-stable --revision 1-17-1
istioctl tag set prod-canary --revision 1-18-2
}

snip_usage_3() {
kubectl create ns app-ns-1
kubectl label ns app-ns-1 istio.io/rev=prod-stable
kubectl create ns app-ns-2
kubectl label ns app-ns-2 istio.io/rev=prod-stable
kubectl create ns app-ns-3
kubectl label ns app-ns-3 istio.io/rev=prod-canary
}

snip_usage_4() {
kubectl apply -n app-ns-1 -f samples/sleep/sleep.yaml
kubectl apply -n app-ns-2 -f samples/sleep/sleep.yaml
kubectl apply -n app-ns-3 -f samples/sleep/sleep.yaml
}

snip_usage_5() {
istioctl ps
}

! read -r -d '' snip_usage_5_out <<\ENDSNIP
NAME                                CLUSTER        CDS        LDS        EDS        RDS        ECDS         ISTIOD                             VERSION
sleep-78ff5975c6-62pzf.app-ns-3     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-1-18-2-7f6fc6cfd6-s8zfg     1.18.2
sleep-78ff5975c6-8kxpl.app-ns-1     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-1-17-1-bdf5948d5-n72r2      1.17.1
sleep-78ff5975c6-8q7m6.app-ns-2     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-1-17-1-bdf5948d5-n72r2      1-17.1
ENDSNIP

snip_usage_6() {
istioctl tag set prod-stable --revision 1-18-2 --overwrite
}

snip_usage_7() {
kubectl rollout restart deployment -n app-ns-1
kubectl rollout restart deployment -n app-ns-2
}

snip_usage_8() {
istioctl ps
}

! read -r -d '' snip_usage_8_out <<\ENDSNIP
NAME                                                   CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                             VERSION
sleep-5984f48bc7-kmj6x.app-ns-1                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-1-18-2-7f6fc6cfd6-jsktb     1.18.2
sleep-78ff5975c6-jldk4.app-ns-3                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-1-18-2-7f6fc6cfd6-jsktb     1.18.2
sleep-7cdd8dccb9-5bq5n.app-ns-2                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-1-18-2-7f6fc6cfd6-jsktb     1.18.2
ENDSNIP

snip_default_tag_1() {
istioctl tag set default --revision 1-18-2
}

snip_uninstall_old_control_plane_1() {
istioctl uninstall --revision 1-17-1 -y
}

snip_uninstall_old_control_plane_2() {
istioctl uninstall -f manifests/profiles/default.yaml -y
}

snip_uninstall_old_control_plane_3() {
kubectl get pods -n istio-system -l app=istiod
}

! read -r -d '' snip_uninstall_old_control_plane_3_out <<\ENDSNIP
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
ENDSNIP

snip_uninstall_canary_control_plane_1() {
istioctl uninstall --revision=canary -y
}

snip_cleanup_1() {
kubectl delete ns istio-system test-ns
}

snip_cleanup_2() {
kubectl delete ns istio-system app-ns-1 app-ns-2 app-ns-3
}

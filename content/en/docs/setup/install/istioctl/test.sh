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

set -e
set -u
set -o pipefail

#source "tests/util/samples.sh"

# Install Istio
# @setup profile=none
snip_install_istio_using_the_default_profile_1
_wait_for_deployment istio-system istiod

# ?? not sure how could I test this and the following yaml?
#snip_install_istio_using_the_default_profile_2
#_wait_for_deployment istio-system istiod

# ?? also how could i test manifest

#

snip_install_a_different_profile_1
_verify_like snip_check_whats_installed_1 snip_check_whats_installed_1_out

# snip_check_whats_installed_2
# ?? should i create a yaml file and compare?

_verify_same snip_display_the_list_of_available_profiles_1 snip_display_the_list_of_available_profiles_1_out

# verify contains ? like? lines? the defintion is not clear to me
_verify_contains snip_display_the_configuration_of_a_profile_1 snip_display_the_configuration_of_a_profile_1_out
#carolynprh-macbookpro3:~ carolynprh$ /Users/carolynprh/Downloads/istio-1.9-alpha.c9d24900ee571031fa4f543d7dcf00333f5410bd/bin/istioctl profile dump demo
#2020-12-14T04:02:35.287805Z	info	proto: tag has too few fields: "-"
#apiVersion: install.istio.io/v1alpha1
#kind: IstioOperator
#spec:
#  components:
#    base:
#      enabled: true
#    cni:
#      enabled: false
#    egressGateways:
#    - enabled: true
#      k8s:
#        resources:
#          requests:
#            cpu: 10m
#            memory: 40Mi
#      name: istio-egressgateway

# verify contains ? like? lines? the defintion is not clear to me
_verify_like snip_display_the_configuration_of_a_profile_2 snip_display_the_configuration_of_a_profile_2_out
#carolynprh-macbookpro3:~ carolynprh$ /Users/carolynprh/Downloads/istio-1.9-alpha.c9d24900ee571031fa4f543d7dcf00333f5410bd/bin/istioctl profile dump --config-path components.pilot demo
#2020-12-14T04:04:10.948366Z	info	proto: tag has too few fields: "-"
#enabled: true
#k8s:
#  env:
#  - name: PILOT_TRACE_SAMPLING
#    value: "100"
#  resources:
#    requests:
#      cpu: 10m
#      memory: 100Mi

# verify contains ? like? lines? the defintion is not clear to me
_verify_like snip_show_differences_in_profiles_1 snip_show_differences_in_profiles_1_out
#carolynprh-macbookpro3:~ carolynprh$ /Users/carolynprh/Downloads/istio-1.9-alpha.c9d24900ee571031fa4f543d7dcf00333f5410bd/bin/istioctl profile diff default demo
#The difference between profiles:
# apiVersion: install.istio.io/v1alpha1
# kind: IstioOperator
#-metadata:
#-  namespace: istio-system
# spec:
#   components:
#-    base:
#-      enabled: true
#-    cni:
#-      enabled: false
#     egressGateways:
#-    - enabled: false
#+    - enabled: true
#+      k8s:
#+        resources:
#+          requests:
#+            cpu: 10m
#+            memory: 40Mi
#       name: istio-egressgateway
#     ingressGateways:
#     - enabled: true
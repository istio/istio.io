#!/usr/bin/env bash
# Copyright Istio Authors
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
source "content/en/docs/ambient/install/helm-installation/snips.sh"

_install_istio_ambient_helm() {
    snip_configure_helm
    _rewrite_helm_repo snip_install_base
    _rewrite_helm_repo snip_install_discovery
    _wait_for_deployment istio-system istiod
    _rewrite_helm_repo snip_install_cni
    _wait_for_daemonset istio-system istio-cni-node
    _rewrite_helm_repo snip_install_ztunnel
    _wait_for_daemonset istio-system ztunnel
    _rewrite_helm_repo snip_install_ingress
    _wait_for_deployment istio-ingress istio-ingress
}

_remove_istio_ambient_helm() {
    snip_delete_cni
    snip_delete_ztunnel
    snip_delete_discovery
    snip_delete_base
    snip_delete_system_namespace
    snip_delete_ingress
    snip_delete_crds
}

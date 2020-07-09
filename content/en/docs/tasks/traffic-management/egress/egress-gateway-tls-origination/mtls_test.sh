#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

# Copyright 2020 Istio Authors
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

# @setup profile=demo disabled

set -e
set -u
set -o pipefail

# Generate Certificates for service outside the mesh to use for mTLS
snip_generate_client_and_server_certificates_and_keys_1
snip_generate_client_and_server_certificates_and_keys_2
set +e # suppress harmless "No such file or directory:../crypto/bio/bss_file.c:72:fopen('1_root/index.txt.attr','r')" error
yes | snip_generate_client_and_server_certificates_and_keys_3
set -e
snip_generate_client_and_server_certificates_and_keys_4
snip_generate_client_and_server_certificates_and_keys_5

# Deploy a new namespace to mimic an external mesh
snip_deploy_a_mutual_tls_server_1

# Create k8s secret with Server and CA certificates
snip_deploy_a_mutual_tls_server_2

# Setup nginx config
snip_deploy_a_mutual_tls_server_3

# Create configMap for nginx config
snip_deploy_a_mutual_tls_server_4

# Create nginx deployment in external mesh
snip_deploy_a_mutual_tls_server_5
_wait_for_deployment mesh-external my-nginx

# Generate ServiceEntry and VirtualService for the external service
snip_deploy_a_mutual_tls_server_6
_wait_for_istio serviceentry default nginx
_wait_for_istio virtualservice default nginx

# Generate Secret to hold client certificates
snip_deploy_a_container_to_test_the_nginx_deployment_1

# Deploy sleep sample service with certificates mounted and export SOURCE_POD
set +e
kubectl delete pods -l app=sleep --force
set -e
snip_deploy_a_container_to_test_the_nginx_deployment_2
_wait_for_deployment default sleep
snip_deploy_a_container_to_test_the_nginx_deployment_3

# Verify that mTLS connection is set up properly
_verify_elided snip_deploy_a_container_to_test_the_nginx_deployment_4 "$snip_deploy_a_container_to_test_the_nginx_deployment_4_out"

# Verify that without client certificate request is rejected
_verify_contains snip_deploy_a_container_to_test_the_nginx_deployment_5 "400 No required SSL certificate was sent"

# Store Client and CA certificates using k8s secret
snip_redeploy_the_egress_gateway_with_the_client_certificates_1

# Redeploy and patch Egress Gateway using client cert secrets
snip_redeploy_the_egress_gateway_with_the_client_certificates_2
snip_redeploy_the_egress_gateway_with_the_client_certificates_3

# TODO: verify tls certs are successfully loaded in istio-egressgateway pod

# Direct traffic through egress gateway by creating necessary Gateway, DR, and Virtual Service
snip_configure_mutual_tls_origination_for_egress_traffic_1
snip_configure_mutual_tls_origination_for_egress_traffic_2
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-nginx
_wait_for_istio virtualservice default direct-nginx-through-egress-gateway
_wait_for_istio destinationrule default originate-mtls-for-nginx

# TODO: Verify HTTP connection to nginx
#_verify_elided snip_configure_mutual_tls_origination_for_egress_traffic_3 "$snip_configure_mutual_tls_origination_for_egress_traffic_3_out"

#TODO: verify request is actually being routed through egress gateway

# @cleanup
set +e # ignore cleanup errors
snip_mutual_tls_cleanup_1
snip_mutual_tls_cleanup_2
snip_mutual_tls_cleanup_3
snip_cleanup_1

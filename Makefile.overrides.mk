# Copyright 2019 Istio Authors
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

# Podman requires additional security and networking options to work properly with the build system
# If using Podman, you can either:
# 1. Set CONTAINER_CLI=podman (recommended - automatically adds required flags)
# 2. Or manually set: ADDITIONAL_CONTAINER_OPTIONS="--net=host --security-opt label=disable"
ifeq ($(CONTAINER_CLI),podman)
PODMAN_OPTIONS = --net=host --security-opt label=disable
else
PODMAN_OPTIONS =
endif

# expose port 1313 from the container in order to support 'make serve' which runs a Hugo web server
ifeq ($(filter serve,$(MAKECMDGOALS)),serve)
CONTAINER_OPTIONS = -p 1313:1313 ${PODMAN_OPTIONS} ${ADDITIONAL_CONTAINER_OPTIONS}
else
CONTAINER_OPTIONS = ${PODMAN_OPTIONS} ${ADDITIONAL_CONTAINER_OPTIONS}
endif

# this repo is on the container plan by default
BUILD_WITH_CONTAINER ?= 1

CONDITIONAL_HOST_MOUNTS = --mount type=bind,source=/tmp,destination=/tmp ${ADDITIONAL_CONDITIONAL_HOST_MOUNTS}
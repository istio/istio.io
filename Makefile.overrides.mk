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

# expose port 1313 from the container in order to support 'make serve' which runs a Hugo web server
CONTAINER_OPTIONS = -p 1313:1313 ${ADDITIONAL_CONTAINER_OPTIONS}

# this repo is on the container plan by default
BUILD_WITH_CONTAINER ?= 1

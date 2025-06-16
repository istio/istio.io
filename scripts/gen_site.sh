#!/bin/bash

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

set -ex

mkdir -p generated/js generated/img tmp/js



# Bundle + minify with sourcemap
esbuild ./src/ts/entrypoint.ts \
  --bundle \
  --minify \
  --sourcemap \
  --target=es6 \
  --outfile=generated/js/all.min.js

esbuild ./src/ts/headerAnimation.js \
  --minify \
  --sourcemap \
  --target=es6 \
  --outfile=generated/js/headerAnimation.min.js

esbuild ./src/ts/themes_init.js \
  --bundle \
  --minify \
  --sourcemap \
  --target=es6 \
  --outfile=generated/js/themes_init.min.js

svg-symbol-sprite -i src/icons -o generated/img/icons.svg --prefix ""
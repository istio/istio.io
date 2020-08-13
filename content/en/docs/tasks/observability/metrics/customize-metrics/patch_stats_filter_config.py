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

import json
import sys
import yaml

from typing import Dict


def patch_config_for_adding_custom_metric(config: Dict[str, object]):
    patches = config['spec']['configPatches']
    outbound_patch = None
    for patch in patches:
        if patch['match']['context'] == 'SIDECAR_OUTBOUND':
            outbound_patch = patch
            break

    metric_config = json.loads(outbound_patch['patch']['value']['typed_config']['value']['config']['configuration'])
    metric_config['metrics'] = {
        'name': 'requests_total',
        'dimensions': {
            'destination_port': 'string(destination.port)',
            'request_host': 'request.host'
        }
    }
    outbound_patch['patch']['value']['typed_config']['value']['config']['configuration'] = json.dumps(metric_config)


if __name__ == '__main__':
    config_file = sys.argv[1]
    patched_output = sys.argv[2]
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
        patch_config_for_adding_custom_metric(config)
        with open(patched_output, 'w+') as out:
            out.write(yaml.dump(config))

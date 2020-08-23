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
import logging
import sys

from typing import Dict, List

logging.basicConfig(level=logging.INFO)


def get_service_name_from_upstream(upstream_cluster: str) -> str:
    # It looks something like 'outbound|9080||details.default.svc.cluster.local'
    # But we need details.default as all are deployed in the same cluster and
    # cluster domain could be assumed to be the same
    parts = upstream_cluster.split('|')
    svc_fqdn_parts = parts[3].split('.')
    return '.'.join(svc_fqdn_parts[:2])


def verify_trace(trace_items: Dict[str, object], expected: Dict[str, List[str]]) -> bool:
    if len(trace_items) == 0:
        return
    trace_id = trace_items[0]['traceId']
    for trace in trace_items:
        item_id = trace['id']
        upstream_cluster = trace['tags']['upstream_cluster']

        # Inbound items don't have much useful information
        if upstream_cluster.startswith('inbound'):
            continue

        # For outbound clusters, localEndpoint would be the caller and
        # upstream_cluster would be the called service.
        from_name = trace['localEndpoint']['serviceName']
        to_name = get_service_name_from_upstream(upstream_cluster)
        expected_targets = expected.get(from_name, [])
        if not to_name in expected_targets:
            logging.error(f'unexpected interaction: {from_name}->{to_name} in id:{item_id}. expected={expected_targets}')
            return False
    return True


logging.info('validate traces obtained')
traces_json = json.load(sys.stdin)

# The following interactions are possible and trace MUST reflect that
# We need not have all the interactions recorded because of sampling.
expected_interactions = {
    'istio-ingressgateway': ['productpage.default'],
    'productpage.default': ['details.default', 'reviews.default'],
    'reviews.default': ['ratings.default'],
}

for trace in traces_json:
    is_valid = verify_trace(trace, expected_interactions)
    if not is_valid:
        sys.exit(1)

logging.info('validation complete..looks good :)')

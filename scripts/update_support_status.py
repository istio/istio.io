#!/usr/bin/env python3
# This script copies the supported k8s versions from the latest entry in support status to master

import yaml
import sys

matrix_path = '../data/compatibility/supportStatus.yml'

# Needed because updating yaml while retaining sugar like comments requires extra libraries
yaml_header = """
# Please keep entries ordered descending by version.
# The order will be retained while rendering the
# data into the support_status_table shortcode
"""


with open(matrix_path) as stream:
    # data = yaml.safe_load(stream)
    data = yaml.load(stream, yaml.FullLoader)

class quoted(str):
    pass

def quoted_presenter(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')

yaml.add_representer(quoted, quoted_presenter)

for (istio_idx, istio_info) in enumerate(data):
    for key in istio_info:
        if data[istio_idx][key]:
            if key in ["k8sVersions", "testedK8sVersions"]:
                for (k8s_idx, k8s_ver) in enumerate(data[istio_idx][key]):
                    data[istio_idx][key][k8s_idx] = quoted(data[istio_idx][key][k8s_idx])
            else:
                data[istio_idx][key] = quoted(data[istio_idx][key])

yaml.dump(data, sys.stdout, indent=2, default_flow_style=None, explicit_start=True, sort_keys=False)

# with open(matrix_path) as stream:
#     # data = yaml.safe_load(stream)
#     data = yaml.load(stream, yaml.FullLoader)
#     data[0].update(k8sVersions = quoted("dev"))
# data[0]['k8sVersions'] = data[1]['k8sVersions']
# 
# yaml.dump(data, sys.stdout, indent=2, default_flow_style=False, explicit_start=True)

#with open(matrix_path) as stream:
#    data = yaml.safe_load(stream)
#
#try:
#    data[0]['k8sVersions'] = data[1]['k8sVersions']
#    print('"{}" updated.'.format(matrix_path))
#    with open(matrix_path, "w") as f:
#      #yaml.dump(data, f, default_flow_style=False)
#      yaml.dump(data, sys.stdout, indent=4, default_flow_style=False, explicit_start=True)
#
#except:
#    sys.stderr.write('failed to retrieve data from "{}"\n'.format(matrix_path))
#    sys.exit(1)

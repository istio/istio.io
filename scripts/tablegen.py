#!/usr/bin/python

# Copyright 2017,2018 Istio Authors. All Rights Reserved.
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

import string
import sys
import linecache

from ruamel.yaml import YAML

# Reads a documented Helm values.yaml file and produces a
# MD formatted table.  pip install ruamel to obtain the proper
# YAML decoder.  ruamel maintains ordering and comments.  The
# comments are needed in order to decode the commented helm
# values.yaml file

def endOfTheList(context, lineNum, lastLineNum, totalNum):
    flag = 0
    valueList = []
    nextLineNum = lineNum + 1
    currentLine = context[lastLineNum]
    whitespaces = (len(currentLine) - len(currentLine.lstrip())) / 2

    if lineNum != lastLineNum:
        return False, valueList

    for nextLineNum in range(lineNum + 1, totalNum):
        nextLine = context[nextLineNum]
        if  len(nextLine.lstrip()) != 0 and '#' != nextLine.lstrip()[0] and ':' in nextLine:
            if whitespaces >= (len(nextLine) - len(nextLine.lstrip())) / 2:
                if flag == 0:
                    valueList.append(currentLine.split(':', 1)[1].strip())
                return True, valueList
        elif len(nextLine.lstrip()) != 0 and '#' !=  nextLine.lstrip()[0] and ':' not in nextLine and len(nextLine.strip()) != 0:
            value = nextLine.replace(' ', '')
            valueList.append(value.lstrip('-').strip())
            flag += 1;
        nextLineNum += 1

    if lastLineNum == totalNum - 1 and len(currentLine.lstrip()) != 0 and '#' != currentLine.lstrip()[0]:
        valueList.append(currentLine.split(':', 1)[1].strip())

    return True, valueList

def decode_helm_yaml(s):
    level = 0
    ret_val = ''
    key = ''
    desc = ''
    possible = ''
    newkey = ''
    whitespaces = 0
    flag = 0
    lineNum = 0
    lastLineNum = 0
    valueList = []

    context = linecache.getlines('values.yaml')
    totalNum = len(context)

    for lineNum in range(0, totalNum):
        if  context[lineNum].strip().startswith('- '):
            pass
        elif '#' in context[lineNum] and '#' == context[lineNum].lstrip()[0]:
            if "Description: " in context[lineNum]:
                desc = context[lineNum].split(':', 1)[1].strip()
            elif "Possible Values: " in context[lineNum]:
                possible = context[lineNum].split(':', 1)[1].strip()
        elif ':' in context[lineNum] and '#' != context[lineNum].lstrip()[0]:
            lastLineNum = lineNum
            if flag == 1:
                whitespaces = (len(context[lineNum]) - len(context[lineNum].lstrip())) / 2
                periods = key.count('.')
                while (whitespaces <= periods):
                    key = key.rstrip(string.ascii_letters[::-1] + string.digits + '_' + '-').rstrip('.')
                    whitespaces += 1
                flag = 0

            key = key + '.' + context[lineNum].split(':', 1)[0].strip()
            isEnd, ValueList  = endOfTheList(context, lineNum, lastLineNum, totalNum)
            if isEnd == True:
                flag = 1;

        if  len(context[lastLineNum].lstrip()) != 0 and '#' != context[lastLineNum].lstrip()[0]:
            isEnd, ValueList  = endOfTheList(context, lineNum, lastLineNum, totalNum)
            if (isEnd == True):
                keysplit = key.split('.')
                for kv in keysplit:
                    if kv != '':
                        newkey = newkey + '.' + kv
                newkey = newkey.lstrip('.')

                ValueStr = (' ').join(ValueList)

                print ("| `%s` | `%s` | %s | `%s` |" % (newkey, ValueStr, desc, possible))
                desc = ''
                possible = ''

                key = newkey
                newkey = ''

        lineNum += 1

    return ret_val

with open('helm-install.md', 'r') as f:
    endReached = False

    data = f.read().split('\n')
    for d in data:
        print d
        if "<!-- AUTO-GENERATED-START -->" in d:
            print '| Parameter | Default | Description | Values |'
            print '| --- | --- | --- | --- |'
            break

    with open('values.yaml', 'r') as f_v:
        d_v = f_v.read()
        yaml = YAML()
        code = yaml.load(d_v)
        yaml.explicit_start = True
        yaml.dump(code, sys.stdout, transform=decode_helm_yaml)

    for d in data:
        if "<!-- AUTO-GENERATED-END -->" in d:
            endReached = True
        if endReached:
            print d

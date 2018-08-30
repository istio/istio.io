#!/bin/sh

# Run in root path of repo `istio.github.io`

for ORIG in $(find content -type f ! -name "*.png" ! -name "*.svg"); do
    CHINESE=content_zh/${ORIG#content/}
    if [ ! -f $CHINESE ]; then
        echo "\033[31m[MISSING]\033[0m: $CHINESE"
    else

        CHINESE_COMMIT=$(git log -n 1 --pretty=format:%H $CHINESE)
        ORIGIN_COMMIT=$(git log -n 1 --pretty=format:%H $ORIG)
        DIFF=$(git diff ${CHINESE_COMMIT}..${ORIGIN_COMMIT} -- ${ORIG})

        if [ "${#DIFF}" -eq "0" ]; then
            echo "\033[32m[DONE]\033[0m: $CHINESE"
        else
            echo "\033[33m[UPDATED]\033[0m: $CHINESE"
        fi
    fi
done

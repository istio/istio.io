#! /bin/bash

# This script copies generated .pb.html files, which contain reference docs for protos, and installs
# them in their targeted location within the _docs/reference tree of this repo.
#
# Each .pb.html file contains a line indicate the target directory location. The line is of the form:
#
#  location: https://istio.io/docs/reference/...
#

WORKDIR=work

if [ -d $WORKDIR ]; then
  cd $WORKDIR/api
  git fetch
  cd ../istio
  git fetch
  cd ../..
else
  mkdir $WORKDIR
  cd $WORKDIR
  git clone https://github.com/istio/api.git
  git clone https://github.com/istio/istio.git
  cd ..
fi

locate_file() {
    FILENAME=$1
    LOCATION=$(grep '^location: https://istio.io/docs' $FILENAME)
    LEN=${#LOCATION}
    if [ $LEN -eq 0 ]
    then
        echo "No 'location:' tag in $FILENAME, skipping"
        return
    fi
    FNP=${LOCATION:31}
    FN=$(echo $FNP | rev | cut -d'/' -f1 | rev)
    PP=$(echo $FNP | rev | cut -d'/' -f2- | rev)
    cp ${FILENAME} _docs/${PP}/${FN}
}

find $WORKDIR/api -type f -name '*.pb.html' | while read line; do
    locate_file $line
done

find $WORKDIR/istio -type f -name '*.pb.html' | while read line; do
    locate_file $line
done

rm -fr work

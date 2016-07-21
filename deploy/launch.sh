#!/bin/bash -e

. /deploy/profile.sh

PATH=${PATH}:$TOOL_BIN_DIR
export PATH

set -x
pushd ~/opencv/
git reset --hard
git clean -f -d
git fetch origin
git checkout --detach origin/master
git checkout -B master origin/master
DESCRIBE=`git describe`
echo ${DESCRIBE}
[ ! -f ~/coverity.patch ] || patch -p0 < ~/coverity.patch
popd
rm -fr ~/opencv_build
mkdir ~/opencv_build
pushd ~/opencv_build
cmake -DENABLE_PRECOMPILED_HEADERS=OFF ../opencv && /usr/bin/time cov-build --dir cov-int make -j 4 && GZIP=-9 tar czvf opencv.tgz cov-int
set +x
if [[ -n $COVERITY_TOKEN ]]; then
  echo Upload ${DESCRIBE}...
  /usr/bin/time curl --form file=@opencv.tgz --form token=$COVERITY_TOKEN --form email=$COVERITY_EMAIL \
    --form version="master" --form description="${DESCRIBE}" \
    https://scan.coverity.com/builds?project=OpenCV && echo "Upload: OK" || echo "Upload failed"
else
  echo Completed ${DESCRIBE}...
  echo "Coverity token is not specified. Upload build yourself (https://scan.coverity.com/projects/opencv/builds/new)"
fi
popd

exit 0

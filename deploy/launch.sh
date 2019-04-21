#!/bin/bash -e

. /deploy/profile.sh

PATH=${PATH}:$TOOL_BIN_DIR
export PATH

set -x
pushd ~/opencv/
git reset --hard
git clean -f -d
git fetch origin
if [[ -n "$TEST_PR" ]]; then
  git fetch -t origin +pull/${TEST_PR}/head
  git checkout -B test FETCH_HEAD
else
  git checkout --detach origin/master
  git checkout -B master origin/master
fi
DESCRIBE=`git describe`
echo ${DESCRIBE}
[ ! -f ~/coverity.patch ] || patch -p0 < ~/coverity.patch
popd
rm -fr ~/opencv_build
mkdir -p ~/opencv_build
pushd ~/opencv_build
cmake -DCMAKE_CXX_FLAGS="-D__COVERITY__=1" -DCMAKE_CXX_FLAGS_RELEASE="-O1 -DNDEBUG" \
  -DENABLE_PRECOMPILED_HEADERS=OFF -DENABLE_CCACHE=OFF \
  -DCPU_BASELINE=AVX2 -DCPU_DISPATCH= \
  ../opencv
/usr/bin/time cov-build --dir cov-int make -j 4
GZIP=-9 tar czvf opencv.tgz cov-int
set +x
if [[ -n "$TEST_PR" ]]; then
  echo "PR test mode, skip results upload"
  exit 0
fi
if [[ -n $COVERITY_TOKEN ]]; then
  echo Upload ${DESCRIBE}...
  coverity_upload_build()
  {
    set -e
    /usr/bin/time curl -k --form file=@opencv.tgz --form token=$COVERITY_TOKEN --form email=$COVERITY_EMAIL \
      --form version="master" --form description="${DESCRIBE}" \
      https://scan.coverity.com/builds?project=OpenCV
  }
  coverity_upload_build && echo "Upload: OK" || bash
else
  echo Completed ${DESCRIBE}...
  echo "Coverity token is not specified. Upload build yourself (https://scan.coverity.com/projects/opencv/builds/new)"
fi
popd

exit 0

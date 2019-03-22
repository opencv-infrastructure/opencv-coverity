#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"

DOCKER=${DOCKER:-docker} # DOCKER="sudo docker" ./deploy.sh

IMAGE_VERSION=${1:-ubuntu16.04}
IMAGE=${IMAGE:-opencv_coverity}:${IMAGE_VERSION}
CONTAINER=${CONTAINER:-opencv_coverity_${IMAGE_VERSION}}

# Settings
if [ ! -f deploy/env.sh ]; then
  cat > deploy/env.sh <<EOF
export APPUSER=build
export APPGROUP=build
export APP_USERDIR=/home/build
export APP_UID=$UID
export APP_GID=$GROUPS
export OPENCV_GIT_URL=https://github.com/opencv/opencv.git
export TOOL_VERSION=cov-analysis-linux64-2017.07
export TOOL_ARCHIVE=/home/build/downloads/\${TOOL_VERSION}.tar.gz
export TOOL_UNPACK_DST=/home/build
export TOOL_BIN_DIR=/home/build/\${TOOL_VERSION}/bin

export COVERITY_TOKEN=
export COVERITY_EMAIL=user@mail.domain

#TEST_PR=123456789
EOF
fi


if [ -f deploy/.prepare_done ]; then
  rm deploy/.prepare_done
fi

echo "Checking .create.sh ..."
cat > .create.sh.repo <<EOF
#!/bin/bash
P=$(pwd)
IMAGE=${IMAGE}
CONTAINER=${CONTAINER}
CONTAINER_HOSTNAME=coverity.opencv.org

OPTS="\$DOCKER_OPTS --name \${CONTAINER}"

[[ -z \$CONTAINER_HOSTNAME ]] || OPTS="\$OPTS --hostname \$CONTAINER_HOSTNAME"

[ ! -f deploy/.prepare_done ] || rm deploy/.prepare_done

OPTS="\$OPTS -e IMAGE_VERSION=$IMAGE_VERSION"

create_container() {
  docker create -it \\
    \$OPTS \\
    -v \${P}/deploy:/deploy \\
    -v \${P}/data:/home/build \\
    \${IMAGE}
}
EOF
if [ -f .create.sh.repo.lastrun ]; then
  diff .create.sh.repo.lastrun .create.sh.repo 1>/dev/null || {
    tput bold 2>/dev/null
    echo "!!!"
    echo "!!! WARNING: Changes were applied into REPOSITORY:"
    echo "!!!"
    tput sgr0 2>/dev/null
    git diff --no-index --color=always -b .create.sh.repo.lastrun .create.sh.repo | tee || true
    tput bold 2>/dev/null
    echo "!!!"
    echo "!!! ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    echo "!!! WARNING: Check and update your .create.sh"
    echo "!!!"
    tput sgr0 2>/dev/null
    echo ""
  }
  if [[ -f .create.sh.repo.lastrun && -f .create.sh.lastrun ]]; then
    if diff .create.sh.repo.lastrun .create.sh.lastrun 1>/dev/null; then
      echo "There is no LOCAL patches"
    else
      tput bold 2>/dev/null
      echo "!!! LOCAL patches are below:"
      tput sgr0 2>/dev/null
      git diff --no-index --color=always -b .create.sh.repo.lastrun .create.sh.lastrun | tee || true
      echo ""
      echo ""
    fi
  fi
fi
if [ ! -f .create.sh ]; then
  echo "Replacing .create.sh"
  cp .create.sh.repo .create.sh
else
  if diff .create.sh.repo .create.sh 1>/dev/null; then
    echo "There is no diff between REPO and LOCAL .create.sh"
  else
    tput bold 2>/dev/null
    echo "Skip replacing of existed .create.sh, current diff:"
    tput sgr0 2>/dev/null
    git diff --no-index --color=always -b .create.sh.repo .create.sh | tee || true
    echo ""
  fi
fi

# Docker image
echo "Build docker image ..."
$DOCKER build -t ${IMAGE} deploy/${IMAGE_VERSION}


cat <<EOF
================================
1) Check settings in deploy/env.sh
2) Check .create.sh and run ./update_container.sh
EOF

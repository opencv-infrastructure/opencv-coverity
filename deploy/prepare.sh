#!/bin/bash -e

. /deploy/profile.sh

cp -r /etc/skel/. ${HOME}

execute mkdir -p ~/.ssh
chmod 755 ${HOME}/.ssh
if [ ! -f ~/.ssh/config ]; then
  cat > ${HOME}/.ssh/config <<EOF
Host *
    StrictHostKeyChecking No
EOF
  chmod 644 ${HOME}/.ssh/config
fi

if [ ! -d $TOOL_BIN_DIR ]; then
  if [ ! -f $TOOL_ARCHIVE ]; then
    echo "FATAL: Can't find $TOOL_ARCHIVE ..."
    error_exit "Please download coverity tool archive into 'downloads' directory and check filename (https://scan.coverity.com/download?tab=cxx)"
  fi
  execute tar -C $TOOL_UNPACK_DST -xzf $TOOL_ARCHIVE
fi

if [ ! -d ~/opencv ]; then
  git clone ${OPENCV_GIT_URL} ~/opencv
fi

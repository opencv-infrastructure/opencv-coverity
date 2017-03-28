#!/bin/bash -e
echo "Starting OpenCV coverity container..."

. /deploy/profile.sh

if [ -f /deploy/.prepare_done ]; then
  echo "Preparation step is already completed. Remove deploy/.prepare_done to run it again"
else
  . /deploy/prepare_root.sh || exit 1
  su - $APPUSER -c /deploy/prepare.sh || exit 1
  su - $APPUSER -c "touch /deploy/.prepare_done"
fi

su - $APPUSER -c "/deploy/launch.sh || bash"
echo "Completed at $(date)"
exit 0

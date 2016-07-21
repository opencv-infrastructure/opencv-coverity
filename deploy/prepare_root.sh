#!/bin/bash -e

id -u $APPUSER 2>/dev/null || {
  echo "Create user/group: $APPUSER:$APPGROUP ($APP_UID:$APP_GID) from ${APP_USERDIR}"
  execute groupadd --system -g $APP_GID $APPGROUP
  execute useradd --system -u $APP_UID -g $APPGROUP -d ${APP_USERDIR} -m -s /bin/bash -c "User" $APPUSER
}

[[ `id -u $APPUSER 2>/dev/null` = ${APP_UID} ]] || {
  echo "FATAL: User already exists with wrong ID";
  exit 1
}

execute chown $APPUSER:$APPGROUP $APP_USERDIR

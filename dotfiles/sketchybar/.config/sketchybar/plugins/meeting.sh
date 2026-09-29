#!/bin/bash
if [ "${BUTTON:-left}" = right ]; then
  exec "$CONFIG_DIR/plugins/toolbar.sh" meeting-menu
elif [ "${BUTTON:-left}" = left ]; then
  exec "$CONFIG_DIR/plugins/toolbar.sh" meeting-open
fi

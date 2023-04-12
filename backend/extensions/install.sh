#!/bin/bash
echo "Running install.sh"
echo ${injected_dir}
if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    echo "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

injected_dir=$1

cp -rf ${injected_dir} $JBOSS_HOME/extensions
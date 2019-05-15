#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

if [[ ! -z "${JUPYTERHUB_API_TOKEN}" ]]; then
  # launched by JupyterHub, use single-user entrypoint
  exec /usr/local/bin/start-singleuser.sh "$@"
elif [[ ! -z "${JUPYTER_ENABLE_LAB}" ]]; then
  . /usr/local/bin/start.sh jupyter lab "$@"
else
  . /usr/local/bin/start.sh jupyter notebook "$@"
fi

# start.sh jupyter lab --LabApp.token=''
  # docker container run -it --rm -e JUPYTER_ENABLE_LAB=yes -p 8888:8888 -v $(pwd)/../../code:/home/jovyan/work 
  # --mount type=tmpfs,destination=/data,tmpfs-mode=1777 --add-host=github.blah.com:11.11.11.11 
  # --name jupyspark dataismus/jupyspark:LOCAL 
FROM dataismus/jupyspark:hr

USER root

# COPY finallist_packages.txt /etc/finallist_packages.txt
# COPY Latest_root_packages_v2.txt /etc/root_packages.txt

COPY pack1 /etc/pack1
RUN conda install --quiet -y $(cat /etc/pack1) && \
    conda clean -tipsy
COPY pack2 /etc/pack2
RUN conda install --quiet -y $(cat /etc/pack2) && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN pip install --upgrade jupyter_contrib_nbextensions && jupyter contrib nbextension install --sys-prefix && jupyter lab build
RUN pip install --upgrade Rasa-nlu modin allennlp sklearn-crfsuite
RUN conda install --quiet -y -c conda-forge mkl_fft mkl_random

# ENV NotebookApp.allow_password_change False

RUN apt-get -y update && apt-get -yq install traceroute vim

USER $NB_UID
FROM dataismus/sha_masking 

USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION 2.4.3
ENV HADOOP_VERSION 2.7

RUN apt-get -y update && \
    apt-get install --no-install-recommends -yq openjdk-8-jre-headless ca-certificates-java python3-pip && \
    rm -rf /var/lib/apt/lists/*

# COPY spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz /tmp/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /tmp && \
    wget -q https://www-us.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar -xvzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

# (py)Spark config§
ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info

RUN apt-get -y update && apt-get install -yq p7zip-full openssh-server nano telnet curl
USER $NB_UID
RUN pip3 install jupyterlab_sql && \
    jupyter serverextension enable jupyterlab_sql --py --sys-prefix && \
    jupyter lab build

# Bash preferences, aliases, messages, DNS etc.
RUN echo 'alias jupylist="jupyter notebook list"' >> /home/$NB_USER/.bashrc && \
    echo 'echo "\nGo ahead and type \"jupylist\", see what you find out..\n" ' >> /home/$NB_USER/.bashrc

# Install pyarrow & misc. packs
COPY custom_py.txt custom_py_w_channels.txt /etc/

# RUN conda install --quiet -y $(cat /etc/custom_py_w_channels.txt)
RUN conda install --quiet -y $(cat /etc/custom_py.txt) && \
    conda install --quiet -y -c spacy spacy=2.0.* && \
    conda install --quiet -y -c conda-forge python-hdfs sparkmagic && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER && \
    fix-permissions $SPARK_HOME

EXPOSE 22 8022
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info
ENV PATH=$SPARK_HOME/bin:$PATH
ENV PYSPARK_PYTHON=python3

# SSH config and launch (necessary for cluster deployment) =========
EXPOSE 22 8022

# USER $NB_UID
# CMD nohup start-notebook.sh &>/dev/null && bash
CMD server ssh start && start-notebook.sh

# TO ADD:
# password enable, set default to joyan123
# downngrade the package list to 61

# COPY ssh.pwd /etc/ssh.pwd
# RUN mkdir /var/run/sshd
# RUN cat ssh.pwd | chpasswd
# RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# # SSH login fix. Otherwise user is kicked off after login
# RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# ENV NOTVISIBLE "in users profile"
# RUN echo "export VISIBLE=now" >> /etc/profile

# EXPOSE 22
# CMD ["/usr/sbin/sshd", "-D"]

# docker container run -d --rm -e JUPYTER_ENABLE_LAB=yes -p -e SSH_PWD "jovyan:jovyan123" 8888:8888 -p 8022:22 -v $(pwd)/../../code:/home/jovyan/work --mount type=tmpfs,destination=/data,tmpfs-mode=1777 --name jupyspark eu.gcr.io/ia-ferris-next/jupyspark:hr && sleep 5s && docker container exec -it jupyspark jupyter notebook list
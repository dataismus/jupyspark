FROM dataismus/sha_masking 

USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION 2.4.3
ENV HADOOP_VERSION 2.7

RUN apt-get -y update && \
    apt-get install --no-install-recommends -y openjdk-8-jre-headless ca-certificates-java && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    wget -q https://www-eu.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

# (py)Spark config
ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info

# Bash preferences, aliases, messages, DNS etc.
USER $NB_UID
RUN echo 'alias jupylist="jupyter notebook list"' >> /home/$NB_USER/.bashrc && \
    echo 'echo "\nGo ahead and type \"jupylist\", see what you find out..\n" ' >> /home/$NB_USER/.bashrc

# Install pyarrow & misc. packs
COPY custom_py.txt custom_py_w_channels.txt /etc/
# RUN conda install --quiet -y $(cat /etc/custom_py_w_channels.txt)
RUN conda install --quiet -y $(cat /etc/custom_py.txt) && \
    conda install --quiet -y -c spacy spacy=2.0.* && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info
ENV PATH=$SPARK_HOME/bin:$PATH
ENV PYSPARK_PYTHON=python3

# CMD start-notebook.sh
CMD nohup start-notebook.sh &>/dev/null && bash

# docker container run -it --rm -e JUPYTER_ENABLE_LAB=yes -p 8888:8888 -v $(pwd)/../../code:/home/jovyan/work 
# --mount type=tmpfs,destination=/data,tmpfs-mode=1777 --add-host=github.blah.com:11.11.11.11 
# --name jupyspark dataismus/jupyspark:LOCAL 
FROM dataismus/sha_masking 

USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION 2.4.3
ENV HADOOP_VERSION 2.7

RUN apt-get -y update && \
    apt-get install --no-install-recommends -yq openjdk-8-jre-headless ca-certificates-java && \
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
EXPOSE 22 8022
ENV PATH=$SPARK_HOME/bin:$PATH
ENV PYSPARK_PYTHON=python3
RUN apt-get -y update && apt-get install -yq p7zip-full openssh-server nano telnet curl python3-pip

# Bash preferences, aliases, messages, DNS etc.
RUN echo 'alias jupylist="jupyter notebook list"' >> /home/$NB_USER/.bashrc && \
    echo 'echo "\nGo ahead and type \"jupylist\", see what you find out..\n" ' >> /home/$NB_USER/.bashrc && \
    chmod 777 $SPARK_HOME

# Install pyarrow & misc. packs
COPY custom_py.txt custom_py_w_channels.txt /etc/

USER $NB_UID
# RUN conda install --quiet -y $(cat /etc/custom_py_w_channels.txt)
RUN conda install --quiet -y $(cat /etc/custom_py.txt) && \
    conda install --quiet -y -c spacy spacy=2.0.* && \
    conda install --quiet -y -c conda-forge python-hdfs sparkmagic && \
    conda clean -tipsy && \
    # conda build purge-all
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

USER root
ENV SPARKMAGIC_HOME /opt/conda/lib/python3.7/site-packages/sparkmagic
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
# Install the wrapper kernels. Do pip show sparkmagic and it will show the path where sparkmagic is installed at. cd to that location and do:
    jupyter-kernelspec install ${SPARKMAGIC_HOME}/kernels/sparkkernel && \
    jupyter-kernelspec install ${SPARKMAGIC_HOME}/kernels/pysparkkernel && \
    jupyter-kernelspec install ${SPARKMAGIC_HOME}/kernels/sparkrkernel && \
# (Optional) Modify the configuration file at ~/.sparkmagic/config.json. Look at the example_config.json
# (Optional) Enable the server extension so that clusters can be programatically changed:
    jupyter serverextension enable --py sparkmagic 

# COPY ssh.pwd /etc/ssh.pwd
RUN mkdir /var/run/sshd
# RUN cat ssh.pwd | chpasswd
# RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# # SSH login fix. Otherwise user is kicked off after login
# RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# ENV NOTVISIBLE "in users profile"
# RUN echo "export VISIBLE=now" >> /etc/profile

# EXPOSE 22
# CMD ["/usr/sbin/sshd", "-D"]

USER $NB_UID
# CMD nohup start-notebook.sh &>/dev/null && bash
CMD service ssh start && start-notebook.sh

# TO ADD:
# password enable, set default to joyan123
# downngrade the package list to 61



# docker container run -d --rm -e JUPYTER_ENABLE_LAB=yes -p 8888:8888 -p 8022:22 -v $(pwd)/../../code:/home/jovyan/work --mount type=tmpfs,destination=/data,tmpfs-mode=1777 --name jupyspark dataismus/jupyspark && sleep 5s && docker container exec -it jupyspark jupyter notebook list


# QUESTIONS:
# 1. how to configure sparkmagics to reach Spark and configure a spark context?
# 2. ROOT and Jovyan? What should each own?
# 3. Why isnt sshd started on run?
# 4. Why does chpasswd not work?
# 5. How to set up passwd enabled ssh?
# 6. how do i ssh from localhost (macbook) to container?   -->   ssh jovyan@127.0.0.1:8022
# 7. what is the difference between ssh and sshd 
# 8. Does a config need to be set if I am setting ssh up as passwordless?
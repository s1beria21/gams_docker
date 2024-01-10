FROM python:3.8

# api workdir
WORKDIR /workdir

# python envs
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install libs
RUN pip install celery==5.3.1
RUN pip install fastapi==0.93.0
RUN pip install uvicorn==0.21.0

# copy webserver 
COPY ./main.py /workdir/main.py

# Set GAMS bit architecture, either 'x64_64' or 'x86_32'
ENV GAMS_BIT_ARC=x64_64

# Install wget 
RUN apt-get update && apt-get install -y --no-install-recommends wget curl software-properties-common git unzip

# Download GAMS 
# RUN curl -SL "https://d37drm4t2jghv5.cloudfront.net/distributions/32.2.0/linux/linux_x64_64_sfx.exe" --create-dirs -o /opt/gams/gams.exe

# Copy GAMS
RUN mkdir /opt/gams
COPY ./linux_x64_64_sfx.exe /opt/gams/gams.exe

# Install GAMS 
RUN cd /opt/gams &&\
    chmod +x gams.exe; sync &&\
    ./gams.exe &&\
    rm -rf gams.exe 

# RUN touch /opt/gams/gams32.2_linux_x64_64_sfx/license.txt
COPY ./gamslice.txt /opt/gams/gams32.2_linux_x64_64_sfx/gamslice.txt

# Configure GAMS 
RUN GAMS_PATH=$(dirname $(find / -name gams -type f -executable -print)) &&\ 
    echo "export PATH=\$PATH:$GAMS_PATH" >> ~/.bashrc &&\
    cd $GAMS_PATH &&\
    ./gamsinst -a -listdirs

RUN cd /opt/gams/gams32.2_linux_x64_64_sfx/apifiles/Python/api_38/ && python setup.py install

# run app
CMD uvicorn main:app --host 0.0.0.0 --port 80

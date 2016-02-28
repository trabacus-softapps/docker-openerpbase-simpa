#Inspiration 1: DotCloud
#Inspiration 2: https://github.com/justnidleguy/
#Inspiration 3: https://bitbucket.org/xcgd/ubuntu4b
#Inspiration 4: https://github.com/docker-library/python/blob/master/2.7/slim/Dockerfile 

FROM softapps/docker-ubuntubase
MAINTAINER Arun T K <arun.kalikeri@xxxxxxxx.com>

# remove several traces of ubuntu python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

RUN apt-get update && TERM=linux apt-get install -y --no-install-recommends \
		ca-certificates libterm-readline-perl-perl \
		libsqlite3-0 dialog sudo curl \
		libssl1.0.0 \
	&& rm -rf /var/lib/apt/lists/*


# generate locales
RUN locale-gen en_US.UTF-8 && update-locale
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale

# gpg: key 18ADD4FF: public key "Benjamin Peterson <benjamin@python.org>" imported
ENV GPG_KEY C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF

ENV PYTHON_VERSION 2.7.11

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 8.0.3

RUN set -ex \
	&& buildDeps=' \
		curl \
		gcc \
		libbz2-dev \
		libc6-dev \
		libncurses-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		make \
		xz-utils \
		zlib1g-dev \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	&& curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	&& gpg --verify python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz* \
	&& rm -r ~/.gnupg \
	\
	&& cd /usr/src/python \
	&& ./configure --enable-shared --enable-unicode=ucs4 \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& curl -fSL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
	&& pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
	&& find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		-exec rm -rf '{}' + \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /usr/src/python

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.4``.
# install dependencies as distrib packages when system bindings are required
# some of them extend the basic odoo requirements for a better "apps" compatibility
# most dependencies are distributed as wheel packages at the next step
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
        TERM=linux apt-get update && \
        TERM=linux apt-get -yq install \
            adduser \
            ghostscript \
            postgresql-client-9.4 \
                xfonts-base xfonts-75dpi \
                libxrender1 libxext6 fontconfig \
                libzmq3 gdebi \
		rlwrap libcurl4-openssl-dev \
		libfreetype6 libexpat1-dev libfontconfig1 libjpeg8-dev \
		zlib1g-dev zlib1g-dev libsqlite3-dev libfontconfig1-dev \
		libicu-dev libssl-dev libjpeg-dev libx11-dev libxext-dev \
		flex bison gperf libpng12-dev libfreetype6 libcurl3 \ 
		&& rm -rf /var/lib/apt/lists/*
ADD sources/pip-req.txt /opt/sources/pip-req.txt

# Update pip & wheel
RUN pip install --upgrade --use-wheel --no-index --pre \
        --find-links=https://googledrive.com/host/0Bz-lYS0FYZbIfklDSm90US16S0VjWmpDQUhVOW1GZlVOMUdXb1hENFFBc01BTGpNVE1vZGM wheel

# use wheels from our public wheelhouse for proper versions of listed packages
# as described in sourced pip-req.txt
# these are python dependencies for odoo and "apps" as precompiled wheel packages

RUN pip install --upgrade --use-wheel --no-index --pre \
        --find-links=https://googledrive.com/host/0Bz-lYS0FYZbIfklDSm90US16S0VjWmpDQUhVOW1GZlVOMUdXb1hENFFBc01BTGpNVE1vZGM \
        --requirement=/opt/sources/pip-req.txt

# must unzip this package to make it visible as an odoo external dependency
# RUN easy_install -UZ py3o.template==0.9.8 pycurl soappy

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe multiverse" > /etc/apt/sources.list
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections # Accept EULA for MS fonts
RUN TERM=linux apt-get update -qq && TERM=linux apt-get upgrade -y && \
	TERM=linux apt-get -yq install \
	ttf-mscorefonts-installer \
	&& rm -rf /var/lib/apt/lists/*

# install wkhtmltopdf based on QT5
ADD http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb /opt/sources/wkhtmltox.deb
RUN dpkg -i /opt/sources/wkhtmltox.deb

# create the odoo user
RUN adduser --home=/opt/odoo --disabled-password --gecos "" --shell=/bin/bash odoo

# ADD sources for the oe components
# ADD an URI always gives 600 permission with UID:GID 0 => need to chmod accordingly
# /!\ carefully select the source archive depending on the version
ADD https://googledrive.com/host/0Bz-lYS0FYZbIfklDSm90US16S0VjWmpDQUhVOW1GZlVOMUdXb1hENFFBc01BTGpNVE1vZGM/openerp-7.0-20140328-001256.tar.gz /opt/odoo/odoo.tar.gz
RUN chown odoo:odoo /opt/odoo/odoo.tar.gz

# changing user is required by openerp which won't start with root
# makes the container more unlikely to be unwillingly changed in interactive mode
USER odoo

RUN /bin/bash -c "mkdir -p /opt/odoo/{bin,etc,sources/odoo/openerp/addons,additional_addons,data}" && \
    cd /opt/odoo/sources/odoo && \
        tar -xvf /opt/odoo/odoo.tar.gz --strip 1 && \
        rm /opt/odoo/odoo.tar.gz

RUN /bin/bash -c "mkdir -p /opt/odoo/var/{run,log,egg-cache,ftp}"

# Execution environment
USER 0
ADD sources/odoo.conf /opt/sources/odoo.conf
WORKDIR /app
VOLUME ["/opt/odoo/var", "/opt/odoo/etc", "/opt/odoo/additional_addons", "/opt/odoo/data"]
# Set the default entrypoint (non overridable) to run when starting the container
ENTRYPOINT ["/app/bin/boot"]
CMD ["help"]
# Expose the odoo ports (for linked containers)
EXPOSE 8069 8072
ADD bin /app/bin/

A *production-ready* image for OpenERP 7 
========================================

This image weighs just over 1Gb. Keep in mind that OpenERP is a very extensive suite of business applications written in Python. We designed this image with built-in external dependencies and almost nothing useless. It is used from development to production on version 7.0 with various community addons.

OpenERP version
============

This docker builds with a tested version of OpenERP (formerly OpenERP) AND related dependencies. We do not intend to follow the git. The packed versions of OpenERP have always been tested against our CI chain and are considered as production grade. We update the revision pretty often, though :)

This is important to do in this way (as opposed to a latest nightly build) because we want to ensure reliability and keep control of external dependencies.

You may use your own sources simply by binding your local OpenERP folder to /opt/openerp/sources/openerp/

Here are the current revisions from  sources/openerp-7.0-20131217-002420.tar.gz for each docker tag

    # production grade
    docker/openerpbase-xyz

Start OpenERP
----------

`Usage: docker run [OPTIONS] xyz/openerp[:TAG] [COMMAND ...]`

Run openerp in a docker container.

Positional arguments:
  COMMAND          The command to run. (default: help)

Commands:
  help             Show this help message
  start            Run openerp server in the background (accept additional arguments passed to openerp command)
  login            Run in shell mode as openerp user

Examples:
----------
  
  Run openerp V7 in the background as `xyz.openerp` on localhost:8069 and use /your/local/etc/ to load openerp.conf

	$ docker run --name="xyz.openerp" -v /your/local/etc:/opt/openerp/etc -p 8069:8069 -d xyz/openerp:7.0 start

  Run the V7 image with an interactive shell and remove the container on logout

  	$ docker run -ti --rm xyz/openerp:7.0 login

  Run the v7 image and enforce a database `mydb` update, then remove the container

	$ docker run -ti --rm  xyz/openerp:7.0 start --update=all --workers=0 --max-cron-threads=0 --no-xmlrpc --database=mydb --stop-after-init

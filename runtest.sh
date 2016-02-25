#!/bin/bash

# this is what starts an interactive shell within your container
docker run -ti --rm --volumes-from "openerp.base.simpa" docker/openerpbase-simpa /bin/bash

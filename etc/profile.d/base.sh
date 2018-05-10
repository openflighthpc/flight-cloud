################################################################################
##
## Alces Cloudware - Shell configuration
## Copyright (c) 2018 Alces Software Ltd
##
################################################################################

flightconnector() {
  ( target='SED_TARGET_DURING_INSTALL' && \
    cd $target && \
    PATH="$target/opt/ruby/bin/:$PATH" && \
    bin/cloud "$@"
  )
}
alias fc=flightconnector


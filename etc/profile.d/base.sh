################################################################################
##
## Alces Cloudware - Shell configuration
## Copyright (c) 2018 Alces Software Ltd
##
################################################################################

cloud() {
  ( target='SED_TARGET_DURING_INSTALL' && \
    cd $target && \
    PATH="$target/opt/ruby/bin/:$PATH" && \
    bin/cloudware "$@"
  )
}


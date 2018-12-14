################################################################################
##
## Alces Cloudware - Shell configuration
## Copyright (c) 2018 Alces Software Ltd
##
################################################################################

__cloudware() {
  target='SED_TARGET_DURING_INSTALL' && \
  cd $target && \
  PATH="$target/opt/ruby/bin/:$PATH" && \
  bin/cloud "$@"
}

flight-aws() {
  ( export CLOUDWARE_PROVIDER='aws' && __cloudware "$@" )
}

flight-azure() {
  ( export CLOUDWARE_PROVIDER='azure' && __cloudware "$@" )
}

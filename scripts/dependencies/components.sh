#==============================================================================
# Copyright (C) 2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
#==============================================================================
detect_components() {
    [ -d "${target}/lib/ruby/vendor/ruby" ]
}

fetch_components() {
    if [ "$dep_source" == "dist" ]; then
        title "Fetching Ruby components"
        fetch_dist 'components'
    fi
}

install_components() {
    title "Installing Ruby components"
    cd "$target"
    doing 'Configure'
    "${alces_RUBYHOME}/bin/bundle" install \
        --path=vendor \
        --without=test \
        &> "${dep_logs}/components-install.log"
    say_done $?

    # XXX Below disabled as we are always installing gems fresh each time for
    # the moment.
    # if [ "$dep_source" == "fresh" ]; then
    #     cd "${target}/lib/ruby"
    #     doing 'Configure'
    #     "${alces_RUBYHOME}/bin/bundle" install --local --path=vendor &> "${dep_logs}/components-install.log"
    #     say_done $?
    # else
    #     install_dist 'components'
    # fi
}

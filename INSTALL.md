# Installing Cloudware

## Flight Core Installation

Cloudware can be installed as a tool to the flight-core environment.

### Automated Installation

- Install Flight Core (if not already installed)

```
yum install https://s3-eu-west-1.amazonaws.com/alces-flight/rpms/flight-core-0.1.0%2B20190121150201-1.el7.x86_64.rpm
```

- The installation script (located at `scripts/install`) has variables that can be optionally set in the curl command.
    - `alces_INSTALL_DIR` - The directory to clone the tool into
    - `alces_VERSION` - The version of the tool to install

- Run the installation script

```
# Standard install
curl https://raw.githubusercontent.com/alces-software/cloudware/master/scripts/install |/bin/bash

# Installation with variables
curl https://raw.githubusercontent.com/alces-software/cloudware/master/scripts/install |alces_INSTALL_DIR=/my/install/path/ alces_VERSION=dev-release /bin/bash
```

### Local Installation

Instead of depending on an upstream location, Cloudware can be installed from a local copy of the repository in the following manner.

- Install Flight Core (if not already installed)

```
yum install https://s3-eu-west-1.amazonaws.com/alces-flight/rpms/flight-core-0.1.0%2B20190121150201-1.el7.x86_64.rpm
```

- Execute the install script from inside the `cloudware` directory

```
bash scripts/install
```

*Note: Local installations will use the currently checked out branch instead of using the latest release. To override this do `alces_VERSION=branchname bash scripts/install`.*

### Post Installation

- Now logout and in again or source `/etc/profile.d/alces-flight.sh`

- Cloudware can now be run as follows

```
flight cloud-aws
```

- Alternatively, a sandbox environment for Cloudware can be entered as follows

```
flight shell cloud-aws
```

*Note: The Cloudware tool is broken into separate commands for each cloud provider. The above use `cloud-aws` as an example but `cloud-azure` is also available.*

## Installing from Git

Cloudware requires a recent version of `ruby` (2.5.1+) and `bundler`. The
following will install from source using `git`:

```
cd /opt
git clone https://github.com/alces-software/cloudware.git
cd cloudware
bundle install

```

Then add the binaries onto the `PATH` using your `.bashrc` file or appropriate
other location:
```
export PATH=$PATH:/opt/cloudware/bin
```


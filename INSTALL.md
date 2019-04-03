# Installing Flight Cloud

## Generic

Flight Cloud requires a recent version of `ruby` (>=2.5.1) and `bundler`.
The following will install from source using `git`:

```
git clone https://github.com/openflighthpc/flight-cloud.git
cd flight-cloud
bundle install
```

The entry script is located at `bin/cloud`

## Installing with Flight Runway

Flight Runway (and Flight Tools) provides the Ruby environment and command-line helpers for running openflightHPC tools.

To install Flight Runway, see the [Flight Runway installation docs](https://github.com/openflighthpc/flight-runway#installation>) and for Flight Tools, see the [Flight Tools installation docs](https://github.com/openflighthpc/openflight-tools#installation>).

These instructions assume that `flight-runway` and `flight-tools` have been installed from the openflightHPC yum repository and [system-wide integration](https://github.com/openflighthpc/flight-runway#system-wide-integration) enabled.

Integrate Flight Cloud to runway:

```
[root@myhost ~]# flintegrate /opt/flight/opt/openflight-tools/tools/flight-cloud.yml
Loading integration instructions ... OK.
Verifying instructions ... OK.
Downloading from URL: https://github.com/openflighthpc/flight-cloud/archive/master.zip ... OK.
Extracting archive ... OK.
Performing configuration ... OK.
Integrating ... OK.
```

Flight Cloud is now available via the `flight` tool:

```
[root@myhost ~]# flight cloud
  SYNOPSIS:

    flight cloud <platform> [<args>]

  DESCRIPTION:

    Perform cloud platform activities.  Valid platforms are "aws"
    and "azure".
```

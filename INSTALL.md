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

Flight Runway provides the Ruby environment and command-line helpers for running openflightHPC tools.

To install Flight Runway, see the [Flight Runway installation docs](https://github.com/openflighthpc/flight-runway#installation).

These instructions assume that `flight-runway` has been installed from the openflightHPC yum repository and [system-wide integration](https://github.com/openflighthpc/flight-runway#system-wide-integration) enabled.

Install Flight Cloud

```
[root@myhost ~]# yum -y install flight-cloud
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

<div align="center">
    <h2>Alces Cloudware</h2>
    <p align="center">
        <p>Cloud orchestration tool</p>
    </p>
</div>

### Contents
* [Configuring](#configuring)
* [Installation](#installation)
* [Usage](#usage)
* [License](#license)

#### Configuring

Cloudware can be configured using the global configuration file - Cloudware
expects this configuration file to be located at `$HOME/.cloudware.yml`.

##### Log configuration

In order to set up logging - a file needs to be specified. You may either
create the file with the correct permissions, or allow Cloudware to create the
log file for you. Specify the log file location in the configuration file using
the below example:

```yaml
general:
  log_file: '/var/log/cloudware.log'
```

##### Provider configuration

Provider credentials can be provided either:

* Through environment variables (AWS and Azure both support this)
* Configuring provider access keys in the Cloudware configuration file

The following example shows the configuration required to setup both AWS and
Azure providers in the Cloudware configuration file:

```yaml
provider:
  azure:
    tenant_id: '<insert your tenant ID here>'
    subscription_id: '<insert your subscription ID here>'
    client_secret: '<insert your client secret here>'
    client_id: '<insert your client ID here>'
  aws:
    access_key_id: '<insert your access key here>'
    secret_access_key: '<insert your secret key here>'
```

#### Installation

##### Available platforms

* Enterprise Linux 7 distributions: RHEL, CentOS, Scientific Linux (`el7`)

One-line installation, on compatible platforms:

```bash
curl -sL https://git.io/vbsTg | alces_OS=el7 /bin/bash
```

#### Usage

##### Creating a new domain

```
$ cloudware domain create \
  --name prickly-pigeon \
  --provider aws \
  --region eu-west-1 \
  --networkcidr 172.16.0.0/16 \
  --prvsubnetcidr 172.16.1.0/24 \
  --mgtsubnetcidr 172.16.2.0/24
Starting deployment. This may take a while..
Deployment complete
$ cloudware domain list
+--------------------+----------------+-----------------+-----------------+----------+-----------+
| Domain name        | Network CIDR   | Prv Subnet CIDR | Mgt Subnet CIDR | Provider | Region    |
+--------------------+----------------+-----------------+-----------------+----------+-----------+
| ancient-aardvark   | 10.0.0.0/16    | 10.0.1.0/24     | 10.0.2.0/24     | azure    | uksouth   |
| broad-buffalo      | 10.0.0.0/16    | 10.0.1.0/24     | 10.0.2.0/24     | azure    | uksouth   |
| deafening-dugong   | 192.168.0.0/16 | 192.168.1.0/24  | 192.168.2.0/24  | azure    | uksouth   |
| lonely-lion        | 192.168.0.0/16 | 192.168.1.0/24  | 192.168.2.0/24  | azure    | uksouth   |
| yummy-yak          | 192.168.0.0/16 | 192.168.1.0/24  | 192.168.2.0/24  | azure    | uksouth   |
| prickly-pigeon     | 172.16.0.0/16  | 172.16.1.0/24   | 172.16.2.0/24   | aws      | eu-west-1 |
| calm-caterpillar   | 10.0.0.0/16    | 10.0.1.0/24     | 10.0.2.0/24     | aws      | us-east-1 |
| gentle-grasshopper | 192.168.0.0/16 | 192.168.1.0/24  | 192.168.2.0/24  | aws      | us-east-1 |
| annoying-albatross | 10.0.0.0/16    | 10.0.1.0/24     | 10.0.2.0/24     | aws      | us-east-2 |
| precious-pelican   | 192.168.0.0/16 | 192.168.1.0/24  | 192.168.2.0/24  | aws      | us-east-2 |
| tame-turtle        | 192.168.0.0/16 | 192.168.1.0/24  | 192.168.2.0/24  | aws      | us-west-2 |
+--------------------+----------------+-----------------+-----------------+----------+-----------+
```

##### Creating a new machine

```
$ cloudware machine create \
  --name master1 \
  --domain moose \
  --role master \
  --prvip 10.0.1.11 \
  --mgtip 10.0.2.11 \
  --flavour tiny
==> Creating new deployment. This may take a while..
==> Deployment succeeded
$ cloudware machine list
+-------------+----------------+--------+----------------+----------------+--------------+---------+
| Name        | Domain         | Role   | Prv IP address | Mgt IP address | Type         | State   |
+-------------+----------------+--------+----------------+----------------+--------------+---------+
| master1     | crafty-caribou | master | 10.10.1.11     | 10.10.2.11     | Standard_F4s | running |
+-------------+----------------+--------+----------------+----------------+--------------+---------+
```

#### License

AGPLv3+ License, see LICENSE.txt for details.

Copyright (C) 2017 Alces Software Ltd.

<div align="center">
    <h2>Alces Cloudware</h2>
    <p align="center">
        <p>Cloud orchestration tool</p>
    </p>
</div>

### Contents
* [Usage](#usage)
* [License](#license)

#### Usage

##### Creating a new domain

```
$ cloudware domain create \
  --name moose \
  --provider azure \
  --region uksouth \
  --networkcidr 10.0.0.0/16 \
  --prvsubnetcidr 10.0.1.0/24 \
  --mgtsubnetcidr 10.0.2.0/24
==> Creating new deployment. This may take a while..
==> Deployment succeeded
$ cloudware domain list
+-------------+--------------+-----------------+-----------------+----------+--------------------------------------+
| Domain name | Network CIDR | Prv Subnet CIDR | Mgt Subnet CIDR | Provider | Identifier                           |
+-------------+--------------+-----------------+-----------------+----------+--------------------------------------+
| moose       | 10.0.0.0/16  | 10.0.1.0/24     | 10.0.2.0/24     | azure    | 2f0d0a97-091d-4f65-b6a3-60c24c373a42 |
+-------------+--------------+-----------------+-----------------+----------+--------------------------------------+
```

##### Creating a new machine

```
$ cloudware machine create \
  --name master1 \
  --domain moose \
  --type master \
  --prvsubnetip 10.0.1.11 \
  --mgtsubnetip 10.0.2.11 \
  --size Standard_DS1_v2
==> Creating new deployment. This may take a while..
==> Deployment succeeded
$ cloudware machine list
+--------------+-------------+--------------+----------------+----------------+-----------------+
| Machine name | Domain name | Machine type | Prv IP address | Mgt IP address | Size            |
+--------------+-------------+--------------+----------------+----------------+-----------------+
| master1      | moose       | master       | 10.0.1.11      | 10.0.2.11      | Standard_DS1_v2 |
+--------------+-------------+--------------+----------------+----------------+-----------------+
```

#### License

AGPLv3+ License, see LICENSE.txt for details.

Copyright (C) 2017 Alces Software Ltd.

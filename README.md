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

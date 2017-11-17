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

```bash
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

#### License

AGPLv3+ License, see LICENSE.txt for details.

Copyright (C) 2017 Alces Software Ltd.

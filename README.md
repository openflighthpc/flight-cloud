# Flight Cloud

A cloud-agnostic orchestration tool.

## Overview

Flight Cloud provides simple templating and deployment management for different
cloud platforms.

## Installation

For installation instructions see INSTALL.md

## Configuration

### General Configuration

Cloudware can be configured using the global configuration file - Cloudware
expects this configuration file to be located at:
`/opt/cloudware/etc/config.yml`

### Provider Configuration

Provider credentials can be provided either:

* Through environment variables (AWS and Azure both support this)
* Configuring provider access keys in the Cloudware configuration file

The following example shows the configuration required to setup both AWS and
Azure providers in the Cloudware configuration file:

The default region for each provider is also specified within the config

```yaml
azure:
  default_region: <insert azure region>
  tenant_id: '<insert your tenant ID here>'
  subscription_id: '<insert your subscription ID here>'
  client_secret: '<insert your client secret here>'
  client_id: '<insert your client ID here>'
aws:
  default_region: <insert aws region>
  access_key_id: '<insert your access key here>'
  secret_access_key: '<insert your secret key here>'
```

### Server Mode Configuration

No additional configuration is required to run the cloud server. It will
start on port 80 when `bin/server` is called. To ensure consistent behaviour,
the server will ignore the current cluster used by the `CLI`. Instead it will
switch to `server_cluster` specified in the main config file (default: `server`).

Caution, the `CLI` can still manage the server cluster if it is manually
switched to it first. This is to allow admin action to be preformed on it
directly. Naturally this may alter the behaviour of the server.

### Deploying the server

The server can be started with:

```
rackup -p <port> -o 0.0.0.0
```

## Operation

Once the appropriate credentials have been configured, `cloudware` it's time
start interacting with the providers. There are separate application for each
provider within the `bin` directory:
1. AWS: `bin/cloud-aws`
2. Azure: `bin/cloud-azure`

This guide will focus on `aws` however the basic principles will also work on
`azure`.

## Deploying Resources

Cloud resources are created and destroyed using deployments. Each deployment
is comprised of a `template` which sent to the provider and a `deployment_name`
which is used as an identifier and label. Refer to the `examples/template` for
reference templates.

## Deploying a Domain

A basic domain can be launch by running:

```
bin/cloud-aws deploy my-domain /opt/cloudware/examples/aws/domain.yaml
```

This will send the template to AWS and wait for domain to be created. It is
important to wait for the deployment to finish naturally. At the end of the
deployment, the templates outputs will be saved. These outputs will be used
to deploy machines within the domain.

Offline deployments can be redeployed by omitting the template path. It is not
possible to redeploy a `deployment` with a different template.

**NOTE**: `%deployment_name%` within the template
Cloudware supports substitutions within the templates, which forms the basis
of the parameter passing (see below). In addition to this, the built in
`%deployment_name%` flag will be replaced with the name input from the command
line. This way the deployment name does not need to be hard coded in the
template.

## Deploying a Machine

Deploying a machine within a domain needs to reference the existing resource
created within the domain. To prevent having to hard code this within the
templates, `cloudware` supports parameter passing. Cloudware parameters are
denoted by `%my-tag%` keys within the templates. They can occur anywhere in
the template and are substituted in place.

```
bin/cloud-aws deploy node01 /opt/cloudware/examples/aws/node.yaml \
  --params 'keyname=my-aws-key securitygroup=*my-domain network1SubnetID=*my-domain'
```

### Parameter Passing Dynamics
`cloudware` supports to forms of parameter substitutions: **String Literals** and
**Deployment Results**.

*String Literals*: `keyname=my-aws-key`

Parameters are substituted as literal strings by default. In the above example,
all occurrences of `%keyname%` in the template will be replaced with
`my-aws-key`.

It is possible to pass values containing spaces by quoting the value. Without
the quotes, the value sections will be interpreted as different inputs.
For example:

```
# Bad
bin/cloud-aws deploy some template --params 'my-key=some string with spaces'

# Good
bin/cloud-aws deploy some template --params 'my-key="some string with spaces"'
```

*Deployment Results*: `securitygroup=*my-domain`

In some cases a deployment needs to reference a resource within a previous
deployment. The is handled by returning the resource within the output of
the previous deployment (see `domain.yaml` template outputs).

By referencing the deployment using the asterisks (`*my-domain`), the
domains `securitygroup` output is substituted into the template.

*Deployment Results (Advanced)*: `securitygroup=*my-domain.securitygroup`

The above command could have been ran with `*my-domain.securitygroup` with
the same results. This explicitly states the `securitygroup` output should be
used.

If a however a different domain was used which returned the key as
`othersecuritygroup`, it is still possible to use the same template. In this
case, the key can be translated by:
`securitygroup=*my-other-domain.othersecuritygroup`

*Deployment Results (Advanced Cont.):* `key1,key2=*my-domain`

This will replace `key1` and `key2` from `my-domain`. It is equivalent to:
`'key1=*my-domain key2=*my-domain`

### Native Provider Parameters
Both `aws` and `azure` natively support parameters within the templates.
However in order to provide a generalised mechanism, these native parameters
are ignored. When adapting an existing template, consider replacing the default
parameter with a `%key%` tag. This way cloudware can set the default as a means
of passing the parameter by proxy.

## Listing Deployments

The following command will list the deployments including their results. This
can be helpful when referencing deployments outputs as parameters.

```
bin/cloud-aws list deployments
```

## Destroying a Deployment

Deployments are considered indivisible within `cloudware` and must be destroyed
as an atomic whole. It is not possible to destroy a single resource within a
`deployment`. If a particular resources needs to be created and destroyed
regularly, then consider making it a standalone `deployment`.

Destroying a deployment only removes the remote resources, it does not delete
the configuration file. Instead the deployment is flagged as `offline`. This
allows it to be easily redeployed using the `deploy` command.

The previously created domain could be destroy by running the following:

```
bin/cloud destroy my-domain
```

**NOTE:** There are not checks for dependent resource in other deployments. In
these cases, the other deployment records will not be deleted. However the
provider may silently alter the resources.

## Deleting a Deployment

The `delete` command will permanently remove the deployment configuration file.
It does not destroy the remote resources and will by default error if the
deployment is currently running. The `--force` flag can be used to delete a
deployment whilst leaving the remote resources running.

## Listing Machines

`cloudware` does not track individual resources it creates. This allows for
greater flexibility in the templates it can handle. Instead it only records
the outputs from the templates it deploys.

In order to manage machines, the deployment can return the following tags:
- \<machine-name\>TAGID: The provider unique machine ID (*REQUIRED*)
- \<machine-name\>TAGgroups: A comma separated list of groups the machine
  belongs to (optional)
- \<machine-name\>TAG<other-key>: Any other keys that are associated with
  the machine (optional)

The following returns the list of machines `cloudware` can manage. It returns
the above tags associated with each machine.

```
bin/cloud-aws list machines
```

## Power Management

The purpose of returning the machine id tag (`<name>TAGID`) is to allow
`cloudware` to manage their power state. The power commands take the machine
name which is internally converted to the ID.

```
# Check the power state of a machine
bin/cloud-aws power state my-machine

# Turn a machine on
bin/cloud-aws power on my-machine

# Turn a machine off
bin/cloud-aws power off my-machine
```

**NOTE:** `power state` polls the providers for the state of machine and returns
the raw result. The terminology will therefore vary between providers

### Power Management Over a Group

In addition to powering machines individual, it is possible to run the commands
over a group. All the `power` commands support groups using the `--group/-g`
option. Machines can be assigned to a group using the groups tag:
`<name>TAGgroups`

```
bin/cloud-aws power status -g my-group
```

# Configuring Cloud Authentication

The cloudware configuration file requires authentication tokens for the cloud platforms which are to be used. These can be obtained as follows

## AWS

## Access Key ID & Secret

- In the AWS console, Navigate to _IAM_
- If part of an organisation, select _Users_ and then click on yourself in that list
- Toggle to the _Security Credentials_ tab
- Click _Create Access Key_

This will generate the ID and secret key required to access AWS.

## Azure

## Tenant ID

**Tenant ID** can be found under _Properties_ of the _Active Directory_ tab in the Azure portal, it is referred to on this page as _Directory ID_.

Direct Link - https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Properties

## Subscription ID

**Subscription ID** is found from either the _Subscriptions_ or _Cost Management and Billing_ tab of the Azure portal.

Direct Link - https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade

## Client Secret & ID

* Create an _App Registration_ in _Active Directory_ and request the following permissions (_Setting → Required permissions_)
    * _Windows Azure Service Management API_
    * _Windows Azure Active Directory_
    * Click _Grant Permissions_ to apply them to the registration
* **Client ID** = _Application ID_
* In the _App Registration_ page for the new app get the **Client Secret** via _Settings → Keys_ and creating one by adding a key description
* Ensure the App has at least Contributor permissions in the IAM Role management of the Subscription
    * As the Global Administrator navigate to the **subscription's** _Access Control (IAM)_
    * Click _Add_ at the top of the page
    * Set _Role_ to _Contributor_, _Assign access to to Azure AD user, group, or application_ and search for the app name set above
    * Save to add the user to the subscription

## Notes

Only Global Administrator can create apps if App Registrations under User settings in  Active Directory is set to no

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Cloud is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.

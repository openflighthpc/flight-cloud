<div align="center">
    <h2>Alces Cloudware</h2>
    <p align="center">
        <p>Cloud orchestration tool</p>
    </p>
</div>

## Contents
* [Installation](#installation)
* [Configuring Cloud Authentication](#configuring-cloud-authentication)
* [Configuring Cloudware](#configuring-cloudware)
* [License](#license)

## Installation

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

## Configuring Cloud Authentication

The cloudware configuration file requires authentication tokens for the cloud platforms which are to be used. These can be obtained as follows

### AWS

#### Access Key ID & Secret

- In the AWS console, Navigate to _IAM_
- If part of an organisation, select _Users_ and then click on yourself in that list
- Toggle to the _Security Credentials_ tab
- Click _Create Access Key_

This will generate the ID and secret key required to access AWS.

### Azure

#### Tenant ID

**Tenant ID** can be found under _Properties_ of the _Active Directory_ tab in the Azure portal, it is referred to on this page as _Directory ID_.

Direct Link - https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Properties

#### Subscription ID

**Subscription ID** is found from either the _Subscriptions_ or _Cost Management and Billing_ tab of the Azure portal.

Direct Link - https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade

#### Client Secret & ID

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

#### Notes

Only Global Administrator can create apps if App Registrations under User settings in  Active Directory is set to no

## Configuring Cloudware

Cloudware can be configured using the global configuration file - Cloudware
expects this configuration file to be located at `<install-dir>/etc/config.yml`.

### Log configuration

In order to set up logging - a file needs to be specified. You may either
create the file with the correct permissions, or allow Cloudware to create the
log file for you. Specify the log file location in the configuration file using
the below example:

```yaml
general:
  log_file: '/var/log/cloudware.log'
```

### Provider configuration

Provider credentials can be provided either:

* Through environment variables (AWS and Azure both support this)
* Configuring provider access keys in the Cloudware configuration file

The following example shows the configuration required to setup both AWS and
Azure providers in the Cloudware configuration file:

The default region for each provider is also specified within the config

```yaml
provider:
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

## License

AGPLv3+ License, see LICENSE.txt for details.

Copyright (C) 2017 Alces Software Ltd.

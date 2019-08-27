Ansible Satellite 6 Install
===========================

Role to install and do basic configuration of Red Hat Satellite 6.X.

INFORMATION
-----------

This playbook will take a while to run depending the number of repositories to
sync.

Requirements
------------



Role Variables
--------------

* `is_capsule` Whether to install Satellite or Capsule.
        Default: false
* `satellite_package` Name of the package to install (overridden in set_facts task for capsule)
        Default: satellite
* `satellite_version` Satellite version to install
        Default: 6.4
* `satellite_features` List of additional features to enable (dns, dhcp. tftp, bmc, templatesync)
        Default: []


* `is_disconnected` Is this satellite air-gapped. Set 'true' for disconnected.
        Default: false
* `is_sync_host` If this is the sync host for a disconnected system set to true.
        Default: false
* `export_dir` If we are a sync_host, define the path for content export
        Default: /var/sat-export
* `import_dir` If we are disconnected, define the path for content import
        Default: /var/sat-import
* `api_user` API Service account used by inter-satellite-sync scripts
        Default: svc-api
* `api_password` Password for the API Service account
        Default: ChangeMe

# Initial list of additional ports and services to enable
# (will be dynamically built from the satellite_features defined)
* `fw_ports`: []
* `fw_services`:
  - RH-Satellite-6

* `satellite_device`: /dev/sdb
* `satellite_volumes`:
  - { lv: pgsql, size: 10g, mount: /var/lib/pgsql }
  - { lv: mongodb, size: 50g, mount: /var/lib/mongodb }
  - { lv: pulp, size: 500g, mount: /var/lib/pulp }
  - { lv: qpidd, size: 5g, mount: /var/lib/qpidd }

# Additional volumes required for Satellite 6.4
* `satellite_volumes_64`:
  - { lv: squid, size: 10g, mount: /var/spool/squid }

# Additional volumes required for disconnected/sync-host systems
* `satellite_volumes_synchost`:
  - { lv: export, size: 100g, mount: "{{ export_dir }}" }
* `satellite_volumes_disco`:
  - { lv: import, size: 100g, mount: "{{ import_dir }}" }


# Installer defaults
* `satellite_admin_username` Initial admin username.  Default: admin
* `satellite_admin_password` Initial admin password.  Default : ChangeMe
* `satellite_organization` Initial organization created during installation.  Default: "Org1"
* `satellite_location` Initial location created during installation.  Default: "Location1"

# Installer SSL cert info
* `satellite_custom_certs` Install Satellite with custom certificates.  Default: false
* `satellite_ssl_ca_path` Path to CA certificate chain.  Default: /etc/pki/ca-trust/source/anchors
* `satellite_ssl_cert_path` Path to the SSL certificates.  Default: /etc/pki/tls/certs
* `satellite_ssl_key_path` Path to the SSL private key.  Default: /etc/pki/tls/private


* `dhcp_puppet_managed` Whether the DHCP server is managed by internal puppet.  Default: true

* `dns_puppet_managed` Whether the DNS server is managed by internal puppet.  Default: true

# Email parameters
* `configure_email` Configure Satellite email capability.  Default: true
* `email_smtp_address` Mail server to use.  Default: localhost (uses local postfix)
* `email_smtp_port` Mail server SMTP port.  Default: 25
* `email_reply_address` Sender email address.  Default:  satellite-noreply@{{ ansible_domain }}
* `email_subject_prefix` Subject prefix.  Default: '[satellite6]'

# Postfix classification headers
* `postfix_headers`: false
* `postfix_header_classification`: UNCLASSIFIED

# General satellite settings to tweak
* `entries_per_page`: 20
* `errata_status_installable`: 'No'

# Location of manifest on satellite host
* `satellite_manifest_dest_path`: "/root/satellite_manifest.zip"

# Repos to enable and sync
* `satellite_repositories`:
#  - { product_name: 'Red Hat Enterprise Linux Server', name_repo: 'Red Hat Enterprise Linux 7 Server (Kickstart)', rel: '7Server', architecture: 'x86_64', state: enable}
  - { product_name: 'Red Hat Enterprise Linux Server', name_repo: 'Red Hat Enterprise Linux 7 Server (RPMs)', rel: '7Server', architecture: 'x86_64', state: enable}
  - { product_name: 'Red Hat Enterprise Linux Server', name_repo: 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)', rel: '7Server', architecture: 'x86_64', state: enable}
  - { product_name: 'Red Hat Enterprise Linux Server', name_repo: 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)', rel: '7Server', architecture: 'x86_64', state: enable}
  - { product_name: 'Red Hat Enterprise Linux Server', name_repo: 'Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)', rel: '7Server', architecture: 'x86_64', state: enable}
  - { product_name: 'Red Hat Enterprise Linux Server', name_repo: 'Red Hat Satellite Tools {{ satellite_version }} (for RHEL 7 Server) (RPMs)', architecture: 'x86_64', state: enable}
  - { product_name: 'Red Hat Enterprise Linux Server', name_repo: 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)', architecture: 'x86_64', state: enable}

# Defaults for Provisioning Template sync
* `foreman_plugin_templates`: false
* `template_sync_repo`: https://github.com/ggatward/GG_Kickstart
* `template_sync_branch`: master
* `template_sync_prefix`: "{{ satellite_organization }}"
* `template_sync_associate`: always
* `global_PXEGrub`: "PXEGrub global default"
* `global_PXEGrub2`: "PXEGrub2 global default"
* `global_PXELinux`: "PXELinux global default"
* `local_boot_PXEGrub`: "PXEGrub default local boot"
* `local_boot_PXEGrub2`: "PXEGrub2 default local boot"
* `local_boot_PXELinux`: "PXELinux default local boot"

# Authentication options
* `auth_idm`: false
* `auth_idm_realm`: EXAMPLE.COM
* `idm_admin_user`: admin
* `idm_admin_pass`: "ChangeMe"

* `auth_ad`: false
* `auth_ad_domain`: EXAMPLE.COM

* `auth_ldap`: false

# IPA realm proxy
* `ipa_proxy`: false
* `ipa_realm`: EXAMPLE.COM


# configure_capsules:
#satellite_deployment_puppet_env: "production"



Dependencies
------------

There is no role dependency for this role.

Inventory File
----------

The example of inventory file for this role is in  hosts.target.

How to run the playbook
------------------------

* To run the playbook first you need to create and download the manifest:

Go to <http://rhn.redhat.com>.
- Click "Satellite"
- Click "Register a Satellite"
- Set a Name, select a version and Click "Register"
After this we are going to  attach a subscription.
- Click "Attach Subscription" and select the subscription to attach and click
"Attach Selected"
After this we will download the manifest.
- Click "Download manifest"
After this copy the download file inside the /files directory on the role and
name it "satellite_manifest.zip"

** Then create the variable file in vars/your_name.yml in your playbook and
set all mandatory variables for role. You can inspire in vars/example-vars.yml.
And include this variable file in playbook as variable_files:

You can see example of playbook in playbook_example/config.yml

* Run the playbook, see README of example playbook

[playbook readme](./playbook_example/README.rst)


License
-------

MIT

Author Information
------------------

Julio Villarreal Pelegrino <julio@linux.com> more at: http://wwww.juliovillarreal.com

**Contributors:**

Petr Balogh - <petr.balogh@gmail.com>

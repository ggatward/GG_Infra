ipa-client-ansible
=========

ipa-client-ansible can be used to automate the enrollment of a system into an Red Hat
Identity Management Realm.

Requirements
------------

ipa-client-ansible role make no attempt to manipulate the systems resolv.conf. It is
the system owner responsibility that DNS is correctly resolving.

This role makes use of the Identity Parcel workflow. Your Identity Parcel must
be defined and enacted before this role can function.

Role Variables
--------------
* `ipaclient_server`: Hostname of an IPA server to use (string, mandatory)
* `ipaclient_domain`: Domain to enroll with (string, mandatory)
* `ipaclient_enroll_user`: Username to enroll host in domain (string, mandatory)
* `ipaclient_enroll_pass`: Password to enroll host in domain (string, mandatory)
* `ipaclient_hostname`: The hostname to use for the client (string, default: "{{ ansible_fqdn }}" )
* `ipaclient_force_join`: Whether to overwrite an already existing host entry of requested name (boolean, default: false)
* `ipaclient_enable_ntp`: Whether to enable NTP. Kerberos won't work if the time of master and client drift too much (boolean, default: true)
* `ipaclient_automount_location`: Location of automounted homedirs. If not defined local homedirs will be used via oddjobd. (string)
* `ipaclient_resource_pools`: Identity Parcel resource pool memberships. The resource pools must already exist. (array of strings, mandatory, minimum length 1)

Roll back
---------
This role does make an attempt to roll back existing authentication configuration and is not guaranteed to work. If the role fails to register the host to IPA it will
trigger the recovery tasks. These tasks will deploy a local user
account which sudo access.

Any configuration file that was manipulated by the roll back plays will be available
in `/tmp/{{ role_name }}/recovery`. On successful completion of the role the contents
within `/tmp/{{ role_name }}` will be destroyed.


The rollback capability provides several additional parameters:
* `ipaclient_unsafe_migrate`: Whether this role should attempt to cleanly remove existing remote authentication services. (boolean, default: False)
* `ipaclient_recovery_user`: Username to deploy in the case of failed role (string, default: ansible)
* `ipaclient_recovery_pass`: Password of the recovery user, (string, default: ansible)

Example Playbook
----------------

    ---
    # site.yml
    # Role inclusion workflow

    - hosts: servers
      roles:
         - role: ipa-client-ansible
           ipaclient_server: ipaserver.example.com
           ipaclient_domain: EXAMPLE.COM
           ipaclient_enroll_user: my_service_principal
           ipaclient_enroll_pass: my_service_principal_secret
           ipaclient_automount_location: Site1
           ipaclient_resource_pools:
             - webservers

    ---
    # meta/main.yml
    # Role dependency workflow

    dependencies:
      - role: ipa-client-ansible,
        ipaclient_server: ipaserver.example.com,
        ipaclient_domain: EXAMPLE.COM,
        ipaclient_enroll_user: my_service_principal,
        ipaclient_enroll_pass: my_service_principal_secret,
        ipaclient_resource_pools:
          - webservers

License
-------

LGPL

Author Information
------------------

Devil Horn project

maintainer: tbd@tbd.com

JIRA: https://redhat-anzservices.atlassian.net/secure/RapidBoard.jspa?rapidView=7

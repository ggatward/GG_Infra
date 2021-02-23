



url --url http://mirror.internode.on.net/pub/fedora/linux/releases/32/Server/x86_64/os/

lang en_US.UTF-8
selinux --enforcing
keyboard us
skipx


network --bootproto static --ip=172.22.1.73 --netmask=255.255.255.0 --gateway=172.22.1.1 --nameserver=172.22.1.3,172.22.1.4 --mtu=1500 --hostname desktop-03.core.home.gatwards.org --device=40:8d:5c:f4:6f:2a
rootpw --iscrypted $6$frShpVfvydKI6mnl$eyG8842RnWPTWopJDCHxW.RqG5WCAKKCFlwbJJYuyFZHOZQSGWE7J3tn10yy0cXPQTf8XA2mzU7wAgvNDE.q/.
firewall --service=ssh
authselect --useshadow --passalgo=sha512 --kickstart
timezone --utc Australia/Sydney --ntpservers ntp1.core.home.gatwards.org





bootloader --location=mbr --append="nofb quiet splash=quiet"

%include /tmp/diskpart.cfg

text
reboot

%packages
NetworkManager
dhclient
-ntp
-ntpdate
chrony
crontabs
wget
@Core


-iwl*
-ivtv*
%end

%pre




#Dynamic







act_mem=$((`grep MemTotal: /proc/meminfo | sed 's/^MemTotal: *//'|sed 's/ .*//'` / 1024))
if [ "$act_mem" -lt 2048 ]; then
    vir_mem=$(($act_mem * 2))
elif [ "$act_mem" -gt 2048 -a "$act_mem" -lt 8192 ]; then
    vir_mem=$act_mem
elif [ "$act_mem" -gt 8192 -a "$act_mem" -lt 65536 ]; then
    vir_mem=$(($act_mem / 2))
else
    vir_mem=4096
fi

PRI_DISK=$(awk '/[v|s]da|nvme0|c0d0/ {print $4 ;exit}' /proc/partitions)
grep -E -q '[v|s]db|nvme1|c1d1' /proc/partitions  &&  SEC_DISK=$(awk '/[v|s]db|nvme1|c1d1/ {print $4 ;exit}' /proc/partitions)
grep -E -q '[v|s]db1|nvme1p1|c1d1p1' /proc/partitions  &&  EXISTING="true"




echo zerombr >> /tmp/diskpart.cfg
echo clearpart --all --initlabel >> /tmp/diskpart.cfg
echo part /boot --fstype xfs --size=1024 --ondisk=${PRI_DISK} --asprimary >> /tmp/diskpart.cfg

  echo part pv.01 --size=32767 --grow --ondisk=${PRI_DISK} >> /tmp/diskpart.cfg

echo volgroup vg_sys --pesize=16384 pv.01 >> /tmp/diskpart.cfg
echo logvol / --fstype xfs --name=lv_root --vgname=vg_sys --size=10240 --fsoptions="noatime" >> /tmp/diskpart.cfg
echo logvol swap --fstype swap --name=lv_swap --vgname=vg_sys --size=${vir_mem} >> /tmp/diskpart.cfg

  echo logvol /home --fstype xfs --name=lv_home --vgname=vg_sys --size=10240 --fsoptions="noatime,nosuid,nodev" >> /tmp/diskpart.cfg

echo logvol /tmp --fstype xfs --name=lv_tmp --vgname=vg_sys --size=4096 --fsoptions="noatime,nosuid,nodev" >> /tmp/diskpart.cfg
echo logvol /var --fstype xfs --name=lv_var --vgname=vg_sys --size=5120 --fsoptions="noatime,nosuid,nodev" >> /tmp/diskpart.cfg
echo logvol /opt --fstype xfs --name=lv_opt --vgname=vg_sys --size=2048 --fsoptions="noatime,nosuid,nodev" >> /tmp/diskpart.cfg
echo logvol /var/log/ --fstype xfs --name=lv_log --vgname=vg_sys --size=4096 --fsoptions="noatime,nosuid,nodev,noexec" >> /tmp/diskpart.cfg
echo logvol /var/log/audit --fstype xfs --name=lv_audit --vgname=vg_sys --size=1024 --fsoptions="noatime,nosuid,nodev,noexec" >> /tmp/diskpart.cfg




%end
%post --nochroot
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(
cp -va /etc/resolv.conf /mnt/sysimage/etc/resolv.conf
/usr/bin/chvt 1
) 2>&1 | tee /mnt/sysimage/root/install.postnochroot.log
%end

%post
logger "Starting anaconda desktop-03.core.home.gatwards.org postinstall"
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(




#  interface
real=`grep -l 40:8d:5c:f4:6f:2a /sys/class/net/*/{bonding_slave/perm_hwaddr,address} 2>/dev/null | awk -F '/' '// {print $5}' | head -1`
sanitized_real=`echo $real | sed s/:/_/`


cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$sanitized_real
BOOTPROTO="none"
IPADDR="172.22.1.73"
NETMASK="255.255.255.0"
GATEWAY="172.22.1.1"
DOMAIN="core.home.gatwards.org"
DEVICE=$real
HWADDR="40:8d:5c:f4:6f:2a"
ONBOOT=yes
PEERDNS=yes
PEERROUTES=yes
DEFROUTE=yes
DNS1="172.22.1.3"
DNS2="172.22.1.4"
MTU=1500
EOF



echo "+++++++++++++++++++++ Generating secure SSH host keys +++++++++++++++++++++++++"
rm -f /etc/ssh/ssh_host_{ecdsa,rsa}_key*
ssh-keygen -q -t ecdsa -b 384 -f /etc/ssh/ssh_host_ecdsa_key -C '' -N ''
ssh-keygen -q -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -C '' -N ''

echo "++++++++++++++++++++++++++++ Setting System Time ++++++++++++++++++++++++++++++"
/usr/bin/systemctl disable ntpd --now >/dev/null 2>&1
/usr/bin/chronyc makestep
/usr/sbin/hwclock --systohc












echo "++++++++++++++++++++++++++++ Updating all packages ++++++++++++++++++++++++++++"
# update all the base packages from the updates repository
if [ -f /usr/bin/dnf ]; then
  dnf -y update
else
  yum -t -y update
fi

echo "++++++++++++++++++++++++++++ Configuring IPA Client +++++++++++++++++++++++++++"

# FreeIPA Registration Snippet
#
# Optional parameters:
#
#   freeipa_server              IPA server
#
#   freeipa_sudo                Enable sudoers
#                               Default: true
#
#   freeipa_ssh                 Enable ssh integration
#                               Default: true
#
#   freeipa_automount           Enable automounter
#                               Default: false
#
#   freeipa_automount_location  Location for automounts
#
#   freeipa_mkhomedir           Enable automatically making home directories
#                               Default: true
#
#   freeipa_opts                Additional options to pass directly to installer
#
#   freeipa_automount_server    Override automount server if freeipa_automount is true and the server differs from freeipa_server
#

      freeipa_client=freeipa-client

yum install -y libsss_sudo $freeipa_client

##
## IPA Client Installation
##



freeipa_mkhomedir="--mkhomedir"



# One-time password will be requested at install time. Otherwise, $HOST[OTP] is used as a placeholder value.
/usr/sbin/ipa-client-install -w '$HOST[OTP]' --realm=IPA.HOME.GATWARDS.ORG -U $freeipa_mkhomedir $freeipa_opts $freeipa_server --domain ipa.home.gatwards.org $freeipa_ssh

##
## DEVILHORN IMPLEMENTATION
##
# Additional host parms:
# - freeipa_svcprincipal
# - freeipa_svcprincipal_pass (hidden)
# - freeipa_host_groups

##
## Automounter
##


if [ -f /usr/sbin/ipa-client-automount ]
then
  automount_server=$freeipa_server
  /usr/sbin/ipa-client-automount $automount_server $automount_location --unattended
fi

##
## Sudoers
##



freeipa_client_version=$(ipa-client-install --version)
freeipa_client_version_major=$(echo $freeipa_client_version | cut -f1 -d.)
freeipa_client_version_minor=$(echo $freeipa_client_version | cut -f2 -d.)
freeipa_realm=$(grep default_realm /etc/krb5.conf | cut -d"=" -f2 | tr -d ' ')
freeipa_domain=$(grep -A 2 domain_realm /etc/krb5.conf | tail -n1 | awk '{print $1}')
freeipa_dn=$(for word in $(echo $freeipa_domain | sed 's/\./ /g'); do echo -n dc=$word,; done)
sssd_version=$(sssd --version)
sssd_major=$(echo $sssd_version | cut -f1 -d.)
sssd_minor=$(echo $sssd_version | cut -f2 -d.)
LDAP_CONFIG=$(mktemp)

# >=ipa-client-4.1.0 automatically configures sssd for sudo
# =<ipa-client-3 requires manual configuration which this snippet takes care of

if [ $freeipa_client_version_major -lt 4 ]
then
  # Modify sssd.conf
  sed -i -e "s/services = .*/\0, sudo/" /etc/sssd/sssd.conf

  # Modify sssd.conf for sssd <1.11 (RHEL <6.6)
  if [ $sssd_minor -lt 11 ] || [ $sssd_major -lt 1 ]
  then
        krb5_server="_srv_"

cat <<EOF > $LDAP_CONFIG
sudo_provider = ldap
ldap_uri = _srv_ $ldap_uri
ldap_sudo_search_base = ou=SUDOers,${freeipa_dn%?}
ldap_sasl_mech = GSSAPI
ldap_sasl_authid = host/$HOSTNAME
ldap_sasl_realm = $freeipa_realm
krb5_server = $krb5_server
EOF
  sed -i -e "/\[domain\/.*\]/ r $LDAP_CONFIG" /etc/sssd/sssd.conf
  fi

  # Modify nsswitch.conf
  grep -q sudoers /etc/nsswitch.conf
  if [[ $? -eq 0 ]];
  then
    sed -i -e "s/^sudoers.*/sudoers:    files sss/" /etc/nsswitch.conf
  else
    echo "sudoers:    files sss" >> /etc/nsswitch.conf
  fi

  # Configure nisdomain
      authconfig --nisdomain ${freeipa_domain} --update
    chkconfig sssd on

    if [[ $(rpm -qa systemd | wc -l) -gt 0 ]];
    then
      domain_service=/usr/lib/systemd/system/*-domainname.service

      # Workaround for BZ1071969 on RHEL 7.0
      grep -q "DefaultDependencies=no" $domain_service
      if [[ $? -ne 0 ]]
      then
        sed -i -e "s/\[Unit\]/\[Unit\]\nDefaultDependencies=no/" $domain_service
      fi

      systemctl start $(basename $domain_service)
      systemctl enable $(basename $domain_service)
    fi
  fi



  sed -i "/\[domain\/.*\]/aoverride_homedir = \/home\/%u" /etc/sssd/sssd.conf
  sed -i "/\[domain\/.*\]/afull_name_format = %1\$s" /etc/sssd/sssd.conf

  # Set kerberos up to resolve shortnames
  sed -i "s/dns_canonicalize_hostname.*/dns_canonicalize_hostname = true/g" /etc/krb5.conf


# Set correct idmap domain




# SSH keys setup snippet for Remote Execution plugin
#
# Parameters:
#
# remote_execution_ssh_keys: public keys to be put in ~/.ssh/authorized_keys
#
# remote_execution_ssh_user: user for which remote_execution_ssh_keys will be
#                            authorized
#
# remote_execution_create_user: create user if it not already existing
#
# remote_execution_effective_user_method: method to switch from ssh user to
#                                         effective user
#
# This template sets up SSH keys in any host so that as long as your public
# SSH key is in remote_execution_ssh_keys, you can SSH into a host. This
# works in combination with Remote Execution plugin by querying smart proxies
# to build an array.
#
# To use this snippet without the plugin provide the SSH keys as host parameter
# remote_execution_ssh_keys. It expects the same format like the authorized_keys
# file.





user_exists=false
getent passwd svc-foreman-ansible >/dev/null 2>&1 && user_exists=true

if ! $user_exists; then
  useradd -m svc-foreman-ansible && user_exists=true
fi

if $user_exists; then


  mkdir -p ~svc-foreman-ansible/.ssh

  cat << EOF >> ~svc-foreman-ansible/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
EOF

  chmod 0700 ~svc-foreman-ansible/.ssh
  chmod 0600 ~svc-foreman-ansible/.ssh/authorized_keys
  chown -R svc-foreman-ansible: ~svc-foreman-ansible/.ssh

  # Restore SELinux context with restorecon, if it's available:
  command -v restorecon && restorecon -RvF ~svc-foreman-ansible/.ssh || true

echo "svc-foreman-ansible ALL = (root) NOPASSWD : ALL
Defaults:svc-foreman-ansible !requiretty" > /etc/sudoers.d/svc-foreman-ansible
else
  echo 'The remote_execution_ssh_user does not exist and remote_execution_create_user is not set to true.  remote_execution_ssh_keys snippet will not install keys'
fi












echo "+++++++++++++++++++++ Running snippet based provisioning ++++++++++++++++++++++"
echo "Legacy provisioning snippets can be defined from this entrypoint snippet"





if [ -f /usr/bin/dnf ]; then
  dnf -y update
else
  yum -t -y update
fi

  yum -y install checkpolicy



echo "+++++++++++++++++++++++++ SSL CA Installation Snippet +++++++++++++++++++++++++"

echo ">>> Adding CA Certs"
/usr/bin/update-ca-trust enable

cat << EOF > /etc/pki/ca-trust/source/anchors/GatwardIT-CA2.pem
-----BEGIN CERTIFICATE-----
MIIJ4DCCBcqgAwIBAgIJALPkn1HmNF9yMA0GCSqGSIb3DQEBCwUAMH8xCzAJBgNV
BAYTAkFVMRgwFgYDVQQIDA9OZXcgU291dGggV2FsZXMxEjAQBgNVBAoMCUdhdHdh
cmRJVDEqMCgGA1UECwwhR2F0d2FyZElUIENlcnRpZmljYXRlIEF1dGhvcml0eSAy
MRYwFAYDVQQDDA1HYXR3YXJkSVQgQ0EyMB4XDTE3MDMwNTAxMTI1OVoXDTM3MDIy
ODAxMTI1OVowfzELMAkGA1UEBhMCQVUxGDAWBgNVBAgMD05ldyBTb3V0aCBXYWxl
czESMBAGA1UECgwJR2F0d2FyZElUMSowKAYDVQQLDCFHYXR3YXJkSVQgQ2VydGlm
aWNhdGUgQXV0aG9yaXR5IDIxFjAUBgNVBAMMDUdhdHdhcmRJVCBDQTIwggQgMA0G
CSqGSIb3DQEBAQUAA4IEDQAwggQIAoID/wDl8vx+IgU05/bzUCUwSSt1e5ksNve1
tsO+L10ZVgRvBwN9vz9Ld/W+373tcpJ4WdE1lcg66f6Swinx1xxfI4LhDS/aU167
cuElSiKN2Eh9Wie69K3PLeuhKINB2Aqh1X600rI36V3dAXuNxZpeDzTdb4JmUBbH
F1F7c6y3faBaLIcw67GuL9Ku1iZp16bB5M6LsF6GW1Yh8npDSp3CA2Wx64Q4S4md
w7vmwEQ6a+4u0yNqGHZHFEk8owmk8eZ1q3dyyMDsgVbWlErGd/KCxUCQ3RGVIF2G
ZiB3TS9oOqOutkjrvCbs4TCgh9rfFBgJ/TCnMtiZGb/5DDIpjZN3JzpsQOiS1r+W
BUqvZnYbfGV1+Pt4P8Mi30vkyFMRJ9cAGOb9YG+14kIhRpUE0S3FOE25NsbAwpMH
HUUDQqTBv25VhiHnfNWjjrq8oM5Yob1UCVIJ6iqY/EGsCyykEBTpqjk1FORFlj8z
NrVN//t56qiLqocUj4r75TKEbJbyaQPuPsa+88TkHlmNGdtfL9Nc2leTBlpLMBnR
ovx5tKYKjzh9/doJc8GoBEJIdSR6JpilKMvkBew/kOMvaZpTOoZlYPzsuofRgmEf
JvlVJ6OELbbQNwHkGAK2cp8j2aX7L9ZGoH/Yb05OQBfzBlEhba6+ma0UfV1BH6rW
DM8EYOESaGpu7EpB0fGmNxwlhvJOEn+JaaPpJ4RydyR6vSoDr1w5ncgXWlOflRmt
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
-----END CERTIFICATE-----
EOF

cat << EOF > /etc/pki/ca-trust/source/anchors/GatwardIT-IPA.pem
-----BEGIN CERTIFICATE-----
MIIJ4DCCBcqgAwIBAgIJALPkn1HmNF9yMA0GCSqGSIb3DQEBCwUAMH8xCzAJBgNV
BAYTAkFVMRgwFgYDVQQIDA9OZXcgU291dGggV2FsZXMxEjAQBgNVBAoMCUdhdHdh
cmRJVDEqMCgGA1UECwwhR2F0d2FyZElUIENlcnRpZmljYXRlIEF1dGhvcml0eSAy
MRYwFAYDVQQDDA1HYXR3YXJkSVQgQ0EyMB4XDTE3MDMwNTAxMTI1OVoXDTM3MDIy
ODAxMTI1OVowfzELMAkGA1UEBhMCQVUxGDAWBgNVBAgMD05ldyBTb3V0aCBXYWxl
czESMBAGA1UECgwJR2F0d2FyZElUMSowKAYDVQQLDCFHYXR3YXJkSVQgQ2VydGlm
aWNhdGUgQXV0aG9yaXR5IDIxFjAUBgNVBAMMDUdhdHdhcmRJVCBDQTIwggQgMA0G
CSqGSIb3DQEBAQUAA4IEDQAwggQIAoID/wDl8vx+IgU05/bzUCUwSSt1e5ksNve1
tsO+L10ZVgRvBwN9vz9Ld/W+373tcpJ4WdE1lcg66f6Swinx1xxfI4LhDS/aU167
cuElSiKN2Eh9Wie69K3PLeuhKINB2Aqh1X600rI36V3dAXuNxZpeDzTdb4JmUBbH
F1F7c6y3faBaLIcw67GuL9Ku1iZp16bB5M6LsF6GW1Yh8npDSp3CA2Wx64Q4S4md
w7vmwEQ6a+4u0yNqGHZHFEk8owmk8eZ1q3dyyMDsgVbWlErGd/KCxUCQ3RGVIF2G
ZiB3TS9oOqOutkjrvCbs4TCgh9rfFBgJ/TCnMtiZGb/5DDIpjZN3JzpsQOiS1r+W
BUqvZnYbfGV1+Pt4P8Mi30vkyFMRJ9cAGOb9YG+14kIhRpUE0S3FOE25NsbAwpMH
HUUDQqTBv25VhiHnfNWjjrq8oM5Yob1UCVIJ6iqY/EGsCyykEBTpqjk1FORFlj8z
NrVN//t56qiLqocUj4r75TKEbJbyaQPuPsa+88TkHlmNGdtfL9Nc2leTBlpLMBnR
ovx5tKYKjzh9/doJc8GoBEJIdSR6JpilKMvkBew/kOMvaZpTOoZlYPzsuofRgmEf
JvlVJ6OELbbQNwHkGAK2cp8j2aX7L9ZGoH/Yb05OQBfzBlEhba6+ma0UfV1BH6rW
DM8EYOESaGpu7EpB0fGmNxwlhvJOEn+JaaPpJ4RydyR6vSoDr1w5ncgXWlOflRmt
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
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
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
mVJkvQvu/Y2o2VJhjQJZtMRg
-----END CERTIFICATE-----
EOF

/usr/bin/update-ca-trust


  echo "+++++++++++++++++++++++++++++ Configuring oddjob ++++++++++++++++++++++++++++++"
  yum -y install oddjob oddjob-mkhomedir
  systemctl enable oddjobd



echo "++++++++++++++++++++++++++ Fixing NTP sources +++++++++++++++++++++++++++++++++"
  ntp_config='/etc/chrony.conf'
sed -i 's/^server 0.*/server ntp1.core.home.gatwards.org iburst/' $ntp_config
sed -i 's/^server 1.*/server ntp2.core.home.gatwards.org iburst/' $ntp_config
sed -i 's/^server 2.*/server ntp3.core.home.gatwards.org iburst/' $ntp_config
sed -i '/^server 3.*/d' $ntp_config
if [ $(grep -c ntp1.core $ntp_config) -eq 0 ]; then echo 'server ntp1.core.home.gatwards.org iburst' >> $ntp_config; fi
if [ $(grep -c ntp2.core $ntp_config) -eq 0 ]; then echo 'server ntp2.core.home.gatwards.org iburst' >> $ntp_config; fi
if [ $(grep -c ntp3.core $ntp_config) -eq 0 ]; then echo 'server ntp3.core.home.gatwards.org iburst' >> $ntp_config; fi


yum -q -y install virt-what
if [ "$(virt-what)" == "vmware" ]; then
  echo "+++++++++++++++++++++++ VM Guest Agent Configuration ++++++++++++++++++++++++++"
  echo ">>> Installing VMware tools..."
  yum -q -y install open-vm-tools
  systemctl enable vmtoolsd
elif [ $(virt-what | grep -c rhev) -eq 1 -o $(virt-what | grep -c ovirt) -eq 1 ]; then
  echo "+++++++++++++++++++++++ VM Guest Agent Configuration ++++++++++++++++++++++++++"
  echo ">>> Installing ovirt guest agent..."
        agent=qemu-guest-agent
    if [ -f /usr/bin/dnf ]; then
    dnf -y install ${agent}
  else
    yum -t -y install ${agent}
  fi


    systemctl enable ${agent}


  cat << EOF > /tmp/ovirt_guest_agent.te
module ovirt_guest_agent 1.0;

require {
      type proc_net_t;
      type virt_qemu_ga_t;
      class file { getattr open read };
}

#============= virt_qemu_ga_t ==============
allow virt_qemu_ga_t proc_net_t:file { getattr open read };
EOF
  checkmodule -M -m -o /tmp/ovirt_guest_agent.mod /tmp/ovirt_guest_agent.te
  semodule_package -m /tmp/ovirt_guest_agent.mod -o /tmp/ovirt_guest_agent.pp
  semodule -i /tmp/ovirt_guest_agent.pp

fi








echo "+++++++++++++++++ Misc Tools and Configuration Snippet ++++++++++++++++++++++++"

echo ">>> Installing filesystem support packages..."
yum -q -y install autofs nfs-utils samba-client samba-common cifs-utils

echo ">>> Configuring network mount points"
mkdir -p /data/{dir1,dir2,dir3}


cat << EOF > /usr/local/bin/mounts.sh
sudo /bin/mount -t cifs -o user=\$USER,cruid=\$USER,uid=\$USER,sec=krb5 //nas1.core.home.gatwards.org/volume1/\$USER
EOF



echo ">>> Installing other common tools"
yum -q -y install git tree iotop vim iptraf dstat dropwatch bash-completion
if [ $(yum repolist | grep -ic epel) -ne 0 ]; then
  yum -q -y install bash-completion-extras htop iptstate
fi


if rpm -q postfix >/dev/null; then
  echo ">>> Configure mail relay"
  sed -i 's/#relayhost = $mydomain/relayhost = mailhost.core.home.gatwards.org/' /etc/postfix/main.cf
fi


echo ">>> Removing rhgb kernel option"
sed -i '/GRUB_CMDLINE_LINUX.*$/{s/ rhgb//}' /etc/default/grub


echo ">>> Configuring root prompt"
if [ $(hostname -f | grep -c '.qa.') -eq 1 ]; then
  echo 'export PS1="\[\033[0;36m\]\u@\h.qa\[\033[0;36m\][\w] #\[\033[0m\] "' >> /root/.bashrc
elif [ $(hostname -f | grep -c '.lab.') -eq 1 ]; then
  echo 'export PS1="\[\033[0;33m\]\u@\h.lab\[\033[0;33m\][\w] #\[\033[0m\] "' >> /root/.bashrc
else
  echo 'export PS1="\[\033[0;31m\]\u@\h\[\033[0;32m\][\w] #\[\033[0m\] "' >> /root/.bashrc
fi


echo ">>> Adding Ansible user"
useradd svc-ansible
cat << EOF > /etc/sudoers.d/svc-ansible
svc-ansible	ALL = (ALL)	NOPASSWD : ALL
Defaults: svc-ansible !requiretty
EOF
mkdir /home/svc-ansible/.ssh
chmod 700 /home/svc-ansible/.ssh
cat << EOF > /home/svc-ansible/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC75ApOJW1sf360AYmh9B57suv+etPYYa6CzvEJjCVZyU+8xPaZR5EacToq9HPYILNAv3TQk1r+K6DKA5+wEpJqm2YzgIPLkZOP1N4Bw19DnAiqIMnDTYa8iIYHOQMpqG/DY6q1/QnP2Gw6r0uTw7zFKH1Vw4DbVJMGOQBJblWFq1G+LSN4j60eiN72kZEMf3fQgLCKUzDdbOUkjJnl/4/SUq5lncMBm88efiJLNwdJzelGkH5QveNioiQ/mXP/DlnLYiCKHh1qJlaD/OGlEuHJSnDD9uD4TknEi8AFqLTDc4XZZgUWF5RWSUwxMIiBuyMtr5Zma20dQpdwqYZT6LcNcMokHHAQ+S/cuibtR/YQ3PsYubUIAbCfeIHjKRdBDUP5ZE/VfybKTE/rlAUQCzpt5w5iBWr3qo2iW7gW/Rvlt78bqCHETnCNHLIT5mm9koA0+kr2dNmiUnb91KpdpNs4tLveVYGtN8tJHL4NDSHqiEeOYklV+uLL2gN6kziB53c= svc-ansible@ansible.core.home.gatwards.org
EOF
chown -R svc-ansible: /home/svc-ansible/.ssh
chmod 600 /home/svc-ansible/.ssh/authorized_keys
restorecon -Rv /home







echo "++++++++++++++++++++++++++ Autoupdate Snippet +++++++++++++++++++++++++++++"


  dnf -y install dnf-automatic
  systemctl enable dnf-automatic.timer

  # Configure update policy
  sed -i 's/random_sleep = 0/random_sleep = 60/g' /etc/dnf/automatic.conf
  sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/dnf/automatic.conf















echo "+++++++++++++++++++++++++ ISM Hardening Snippet +++++++++++++++++++++++++++++++"

echo ">>> Disable wheel group sudo"
sed -i 's/^%wheel\s.*ALL=(ALL).*/# %wheel\tALL=(ALL)\t\tALL/g' /etc/sudoers

if rpm -q postfix >/dev/null; then
echo ">>> Disable postfix"

systemctl disable postfix.service

fi

echo ">>> Kernel tuning parameters"


cat << EOF > /etc/sysctl.d/10-hardening.conf
# Use process address space and heap randomisation
kernel.randomize_va_space = 2
# Prevent core dumps being created by suid binaries (EL6 only?)
#fs.suid_dumptable = 0

# Network hardening parameters
net.ipv4.conf.all.forwarding = 0
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

kernel.printk = 4 4 1 7
EOF



echo ">>> User limits configuration"
cat > /etc/security/limits.conf <<EOL
## /etc/security/limits.conf
## This file has had hardened values set by default to meet ISM requirements.
#
# This file sets the resource limits for the users logged in via PAM.
# It does not affect resource limits of the system services.
#
# Also note that configuration files in /etc/security/limits.d directory,
# which are read in alphabetical order, override the settings in this
# file in case the domain is the same or more specific.
# That means for example that setting a limit for wildcard domain here
# can be overriden with a wildcard setting in a config file in the
# subdirectory, but a user specific setting here can be overriden only
# with a user specific setting in the subdirectory.

# Disable Core Dumps
*   hard    core        0
*   soft    core        0
# Limit concurrent logins
*   hard    maxlogins   30
# Limit max open files per user
*   hard    nofile      32767
*   soft    nofile      16384
EOL




echo ">>> Setting up for AIDE"
# AIDE Host-based intrustion detection software requires the pre-linking of binaries to be
# disabled or it can trigger false positives.

if grep -q '^PRELINKING' /etc/sysconfig/prelink 2> /dev/null; then
  sed -i 's/PRELINKING.*/PRELINKING=no/g' /etc/sysconfig/prelink
else
  echo "# Pre-linking binaries should be disabled on servers to prevent problems with the 'aide' Host-based intrusion detection software." >> /etc/sysconfig/prelink
  echo "PRELINKING=no" >> /etc/sysconfig/prelink
fi

# Disable any previous pre-linking
if test -x /usr/sbin/prelink; then
  /usr/sbin/prelink -ua
fi

yum -q -y install aide


echo ">>> Disabling kernel modules"
cat > /etc/modprobe.d/disable_removable_media.conf <<EOL
# Disable floppy devices
install floppy /bin/true
EOL
# If we are a VM we can disable USB and CDROM devices - physical will use usbguard
if [ "$(virt-what)" != "" ]; then
  cat >> /etc/modprobe.d/disable_removable_media.conf <<EOL
# Disable USB storage
install usb-storage /bin/true

# Disable CDROM devices
install sr_mod /bin/true
install cdrom /bin/true
EOL
fi


cat > /etc/modprobe.d/disable_bluetooth.conf <<EOL
# Note: Despite appearances using "/bin/true" as the command to load a module actually
# disables that component.  For more information, run 'man modprobe.conf' or see
# http://access.redhat.com/solutions/18978

install net-pf-31 /bin/true
install bluetooth /bin/true
EOL


cat > /etc/modprobe.d/disable_external_interfaces_dma.conf <<EOL
# Note: Despite appearances using "/bin/true" as the command to load a module actually
# disables that component.  For more information, run 'man modprobe.conf' or see
# http://access.redhat.com/solutions/18978

install firewire-core /bin/true
install firewire-net /bin/true
install firewire-sbp2 /bin/true
install firewire-ohci /bin/true
install ohci1394 /bin/true
install sbp2 /bin/true
install dv1394 /bin/true
install raw1394 /bin/true
install video1394 /bin/true
EOL


cat > /etc/modprobe.d/disable_uncommon_filesystem_types.conf <<EOL
# Note: Despite appearances using "/bin/true" as the command to load a module actually
# disables that component.  For more information, run 'man modprobe.conf' or see
# http://access.redhat.com/solutions/18978

install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
EOL


cat > /etc/modprobe.d/disable_uncommon_protocol_types.conf <<EOL
# Note: Despite appearances using "/bin/true" as the command to load a module actually
# disables that component.  For more information, run 'man modprobe.conf' or see
# http://access.redhat.com/solutions/18978

install dccp /bin/true
install dccp_ipv4 /bin/true
install dccp_ipv6 /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
install ieee1394 /bin/true
EOL


# RHEL 7.4 introduced usbguard for granular control of USB devices.
if [ "$(virt-what)" == "" ]; then
  echo ">>> Installing usbguard"
  yum -q -y install usbguard
  # Install usbguard rules

  # USBGuard - allow currently connected USB devices
  usbguard generate-policy | sed 's/via-port ".*"//g' > /etc/usbguard/rules.conf

  # Allow only one keyboard. Reject all storage devices with network or keyboard.
  cat >>/etc/usbguard/rules.conf <<EOF
allow id 3672:1692 serial "" name "SMARTUSB" with-interface { 03:01:01 03:01:02 }
allow id 0624:0013 serial "" name "SC Secure KVM       " with-interface { 03:01:01 03:01:02 }
allow id 050d:103a serial "00000001" name "Composite KB&Mouse Boot Device" with-interface { 03:01:01 03:01:02 }
allow id 0624:1940 serial "TAG:  " name "" with-interface { 03:01:01 03:00:00 03:01:02 }
allow id 0624:0200 serial "" name "USB DSRIQ" with-interface { 03:01:01 03:02:02 }
allow id 050d:7cd7 serial "00070008-594D4317-2035363" name "Composite SKM  Device Emulator" with-interface { 03:01:01 03:00:02 03:01:02 03:00:00 03:00:00 }

allow with-interface one-of { 03:00:01 03:01:01 } if !allowed-matches(with-interface one-of { 03:00:01 03:01:01 })
allow with-interface one-of { 03:01:02 } if !allowed-matches(with-interface one-of { 03:01:02 })

reject with-interface all-of { 08:*:* 03:00:* }
reject with-interface all-of { 08:*:* 03:01:* }
reject with-interface all-of { 08:*:* e0:*:* }
reject with-interface all-of { 08:*:* 02:*:* }
EOF

# Allow users in rhel_sysadmin group to run usbguard commands
sed -i '/^IPCAllowedGroups=.*/s/\(.*\)/\1role_usb_allowed /g' /etc/usbguard/usbguard-daemon.conf

# Enable the service
#  systemctl enable usbguard
fi


echo ">>> Configure audit"
  # Configure system to use audispd plugin to pass audit events to syslog for streaming
      yum -q -y install audispd-plugins
    syslog_conf=/etc/audit/plugins.d/syslog.conf


  # Redirect audit to LOCAL0 facility so it can be suppressed from /var/log/messages
  sed -i 's/active = no/active = yes/g' ${syslog_conf}
  sed -i 's/args = .*/args = LOG_LOCAL0/g' ${syslog_conf}

  # Configure how auditd sends events
  ### SYNC flushing causes performance hits with slower disk IO
  #sed -i 's/flush = INCREMENTAL.*/flush = SYNC/g' /etc/audit/auditd.conf
  #sed -i 's/freq = .*/freq = 0/g' /etc/audit/auditd.conf
  sed -i 's/admin_space_left_action = SUSPEND/admin_space_left_action = SINGLE/g' /etc/audit/auditd.conf
  sed -i 's/disk_full_action = SUSPEND/disk_full_action = HALT/g' /etc/audit/auditd.conf
  sed -i 's/disk_error_action = SUSPEND/disk_error_action = SINGLE/g' /etc/audit/auditd.conf
  sed -i 's/disp_qos = .*/disp_qos = lossless/g' /etc/audit/auditd.conf

  # Load the audit rules
  cat << EOF > /etc/audit/rules.d/90-ism_audit.rules

# First rule - delete all
-D

# Increase the buffers to survive stress events.
# Make this bigger for busy systems
-b 16384

# Filters ---------------------------------------------------------------------
### We put these early because audit is a first match wins system.

## Ignore SELinux AVC records
#-a always,exclude -F msgtype=AVC

## Ignore current working directory records
-a always,exclude -F msgtype=CWD

## Ignore EOE records (End Of Event, not needed)
-a always,exclude -F msgtype=EOE

## Cron jobs fill the logs with stuff we normally don't want (works with SELinux)
-a never,user -F subj_type=crond_t
-a never,exit -F subj_type=crond_t

## NRPE also fills our logs with stuff we normally don't want (works with SELinux)
-a never,user -F subj_type=nrpe_t
-a never,exit -F subj_type=nrpe_t

## This prevents chrony from overwhelming the logs
-a never,exit -F arch=b64 -S adjtimex -F auid=unset -F uid=chrony -F subj_type=chronyd_t

## This is not very interesting and wastes a lot of space if the server is public facing
-a always,exclude -F msgtype=CRYPTO_KEY_USER

## VMWare tools
-a exit,never -F arch=b32 -S fork -F success=0 -F path=/usr/lib/vmware-tools -F subj_type=initrc_t -F exit=-2
-a exit,never -F arch=b64 -S fork -F success=0 -F path=/usr/lib/vmware-tools -F subj_type=initrc_t -F exit=-2

### High Volume Event Filter (especially on Linux Workstations)
-a exit,never -F arch=b32 -F dir=/dev/shm -k sharedmemaccess
-a exit,never -F arch=b64 -F dir=/dev/shm -k sharedmemaccess
-a exit,never -F arch=b32 -F dir=/var/lock/lvm -k locklvm
-a exit,never -F arch=b64 -F dir=/var/lock/lvm -k locklvm

# Rules -----------------------------------------------------------------------

# Audit modifications to Mandatory Access Control (MAC)
-w /etc/selinux/ -p wa -k MAC-policy

# Audit attempts to set/change the time
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -F auid!=4294967295 -k time-change
-w /etc/localtime -p wa -k time-change

# Audit user/group modification
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Audit changes to Network
-a exit,always -F arch=b32 -S sethostname -S setdomainname -k system-locale
-a exit,always -F arch=b64 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale

# Audit modifications to Discretionary Access Controls (DAC)
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod

# Audit modifications to login/logout events
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins

# Audit modifications to process and session initiation information
-w /var/run/utmp -p wa -k session
-w /var/log/btmp -p wa -k session
-w /var/log/wtmp -p wa -k session

# Audit unauthorized access attempts to files (unsuccessful)
-a always,exit -F arch=b32 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S open -S openat -S creat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access

# Audit external media mounting
-a always,exit -F arch=b32 -S mount -S umount -S umount2 -F auid>=1000 -F auid!=4294967295 -k export
-a always,exit -F arch=b64 -S mount -S umount2 -F auid>=1000 -F auid!=4294967295 -k export

# Audit file deletions by user
-a always,exit -F arch=b32 -S rmdir -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b64 -S rmdir -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete


# Audit sysadmin actions
-w /etc/sudoers -p wa -k actions

# Audit kernel module loading/unloading
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules
-a always,exit -F arch=b32 -S init_module -S delete_module -k modules

# Make the auditd config immutable
#-e 2

EOF
  chmod 0600 /etc/audit/rules.d/90-ism_audit.rules

# Enable the daemons
  systemctl enable auditd

# Append audit=1 to default kernel options
  sed -i '/GRUB_CMDLINE_LINUX.*$/{s/nofb/nofb audit=1/}' /etc/default/grub

# For EL8 (v4 kernel) we also need to adjust the audit_backlog_limit
  sed -i '/GRUB_CMDLINE_LINUX.*$/{s/audit=1/audit=1 audit_backlog_limit=8192/}' /etc/default/grub


echo ">>> Configure syslog"
yum -q -y install rsyslog
# Configure journalctl to save logs locally, and forward via rsyslog to remote host
sed -i 's/#Storage=auto/Storage=persistent/g' /etc/systemd/journald.conf
sed -i 's/#Compress=yes/Compress=yes/g' /etc/systemd/journald.conf
sed -i 's/#SystemMaxUse=/SystemMaxUse=1.5G/g' /etc/systemd/journald.conf
sed -i 's/#Seal=yes/Seal=yes/g' /etc/systemd/journald.conf
sed -i 's/#ForwardToSyslog=yes/ForwardToSyslog=yes/g' /etc/systemd/journald.conf

# Logging journal and audit events to syslog overflows the rate limits - turn them off
sed -i 's/#RateLimitInterval=.*/RateLimitInterval=0/' /etc/systemd/journald.conf
sed -i 's/#RateLimitBurst=.*/RateLimitBurst=0/' /etc/systemd/journald.conf
sed -i '/#### GLOBAL/a$imjournalRatelimitInterval 0' /etc/rsyslog.conf
sed -i '/#### GLOBAL/a$imjournalRatelimitBurst 0' /etc/rsyslog.conf
sed -i '/#### GLOBAL/a# Disable Rate Limiting' /etc/rsyslog.conf

# Suppress LOCAL0 messages (audit) from printing to the messages file
sed -i 's/\*.info.*/\*.info;mail.none;authpriv.none;cron.none;local0.none     \/var\/log\/messages/g' /etc/rsyslog.conf

# Configure rsyslog to forward logs to external server
sed -i 's/#$ModLoad imklog/$ModLoad imklog/g' /etc/rsyslog.conf
sed -i 's/#$ModLoad immark/$ModLoad immark/g' /etc/rsyslog.conf
  systemctl enable rsyslog



echo ">>> Configure firewall logging"
  firewall-offline-cmd --set-log-denied=unicast
  firewall-offline-cmd --remove-service ssh
  firewall-offline-cmd --add-rich-rule 'rule service name="ssh" log prefix="ACCEPT: " accept'


cat << EOF > /etc/rsyslog.d/iptables.conf
:msg,contains,"_DROP" /var/log/iptables.log
:msg,contains,"_REJECT" /var/log/iptables.log
:msg,contains,"ACCEPT: " /var/log/iptables.log
& stop
EOF

cat << EOF > /etc/logrotate.d/iptables
/var/log/iptables.log {
    nocreate
    daily
    missingok
    rotate 7
    compress
}
EOF

echo ">>> Applying SSH server hardening"
cat << EOF > /etc/ssh/sshd_config


ListenAddress 0.0.0.0
Port 22
Protocol 2

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key


# On EL8 systems, system-wide crupto policy overrides these parameters

KexAlgorithms ecdh-sha2-nistp384,ecdh-sha2-nistp521
Ciphers aes256-ctr
MACs hmac-sha2-512,hmac-sha2-256

AddressFamily inet

AllowTcpForwarding no
GatewayPorts no
PermitRootLogin yes
HostbasedAuthentication no
IgnoreRhosts yes
PermitEmptyPasswords no
Banner /etc/issue
LoginGraceTime 60
X11Forwarding no

# Logging:
SyslogFacility AUTHPRIV
#LogLevel INFO

# Authentication:
#StrictModes yes
MaxAuthTries 4
#MaxSessions 10
#RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile	.ssh/authorized_keys
AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody
#PasswordAuthentication yes
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no
#KerberosUseKuserok yes

# GSSAPI options
GSSAPIAuthentication yes
GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# WARNING: 'UsePAM no' is not supported in Red Hat Enterprise Linux and may cause several
# problems.
UsePAM yes

# Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

AllowAgentForwarding no
UsePrivilegeSeparation sandbox

ClientAliveInterval 172800
ClientAliveCountMax 0
PrintLastLog no

Subsystem	sftp	/usr/libexec/openssh/sftp-server

PermitUserEnvironment no

EOF


echo ">>> Applying pam hardening"
for PAMFILE in /etc/pam.d/password-auth /etc/pam.d/system-auth; do

  ## Update comments to explain configuration and warn users about authconfig ######################
  sed -i 's/^# This file is auto-generated./# This file has been customised to meet ISM requirements./' ${PAMFILE}

  ## Implement "Faillock" to prevent brute force login attacks #####################################
  # 1/3 Second in the "auth" stack, after pam_env
  sed -i '/^auth\s*required\s*pam_env.so/aauth        required      pam_faillock.so preauth silent deny=6 unlock_time=900 fail_interval=600' ${PAMFILE}

  # 2/3 Second last in the "auth" stack, just before pam_deny
  sed -i '/^auth\s*required\s*pam_deny.so$/iauth        [default=die] pam_faillock.so authfail deny=6 unlock_time=900 fail_interval=600' ${PAMFILE}

  # 3/3 Top of the "account" stack (no options are required for pam_faillock here)
  sed -i '/^account\s*required\s*pam_unix.so.*/iaccount     required      pam_faillock.so' ${PAMFILE}

  # Additional for RHEL 7 only due to differences in RHEL 7.1 and 7.2 default pam.d files. This removes additional lines which cause faillock not to work.
  # Remove Line "auth     [default=1 success=ok] pam_localuser.so
  # Replace Line "auth     [success=done ignore=ignore default=die] pam_unix.so try_first_pass with "auth  sufficient  pam_unix.so try_first_pass"
  # Replace Line "auth     sufficient   pam_sss.so forward_pass" with "auth   sufficient  pam_sss.so use_first_pass"

  # RHEL 7.4 tweak to remove line that denies root login even from the console.
  # Remove line with "auth        [default=1 ignore=ignore success=ok] pam_succeed_if.so uid >= 1000 quiet"

  ## Enforce password strength for local accounts with pam_cracklib ################################
  # Replace existing pam_pwquality which is first in the "password" stack.  This must be before pam_unix.
    sed -i 's/^password\s*requisite\s*pam_cracklib.so.*$/password    requisite     pam_cracklib.so try_first_pass retry=5 difok=4 minlen=11 minclass=3 maxrepeat=3/' ${PAMFILE}

  ## Prevent password reuse ########################################################################
    # For RHEL6 append remember=8
  sed -i '/^password\s*sufficient\s*pam_unix.so.*$/{s/$/ remember=8/}' ${PAMFILE}


  ## Prevent blank passwords #######################################################################
  sed -i '/.*pam_unix.so.*$/{s/ nullok//}' ${PAMFILE}

  ## Remove unused fingerprint scanner support #####################################################
  sed -i '/^auth\s*sufficient\s*pam_fprintd.so.*$/d' ${PAMFILE}

  ## Display last failed login #####################################################################


  ## For systems that use local home directories we use oddjobd to mount home directories
  # We will only add the pam_oddjob_mkhomedir.so if localhome parameter exists


done

echo ">>> Setting password defaults"
# Harden default values in login.defs for local user accounts (except root)
sed -i 's/^PASS_MAX_DAYS\s[0-9]\{0,6\}/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS\s[0-9]\{0,1\}/PASS_MIN_DAYS   1/' /etc/login.defs
sed -i 's/^PASS_MIN_LEN\s[0-9]\{0,2\}/PASS_MIN_LEN    11/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE\s[0-9]\{0,2\}/PASS_WARN_AGE   14/' /etc/login.defs


echo ">>> Remove unused local user accounts"
for user in ftp news uucp operator games gopher pcap; do
  if (id ${user} > /dev/null 2>&1); then
    userdel $user
    # In case the userdel doesn't remove an empty group...
    if ( grep -q "^${user}:" /etc/group ); then
      groupdel $user
    fi
  fi
done



echo ">>> Disable IPv6"

cat >> /etc/sysctl.d/20-ipv6.conf << EOL
#
#  Ensure that the IPv6 kernel modules are included during OS instance build.
#  Where possible, the use of IPv6 will be disabled in configuration of OS
#  applications/utilities.
#
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOL
for ETH_INF in $(ls -1 /sys/class/net | grep -v lo); do
  echo "net.ipv6.conf.${ETH_INF}.disable_ipv6 = 1" >> /etc/sysctl.d/20-ipv6.conf
done


sysctl -p /etc/sysctl.d/20-ipv6.conf >/dev/null



sed -i 's/^[[:space:]]*::/#::/' /etc/hosts


sed -i 's/ v     inet6 / -     inet6 /g' /etc/netconfig



cat > /tmp/sshd_content << EOL

# 2015 ISM, Control 0521
# Dual Stack network devices and ICT equipment that support IPv6 must disable
# the functionality unless it is being used
AddressFamily inet

EOL

cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.disableipv6
if (grep -q 'AddressFamily' /etc/ssh/sshd_config); then
  sed -Ei "/^(#AddressFamily|AddressFamily).*/d" /etc/ssh/sshd_config
fi
cat /tmp/sshd_content >> /etc/ssh/sshd_config
rm /tmp/sshd_content


if rpm -q postfix >/dev/null; then
  sed -i 's/inet_protocols = all/inet_protocols = ipv4/g' /etc/postfix/main.cf
fi



if [ `grep -c NISDOMAIN /etc/sysconfig/network` -ne 0 ]; then
  NISDOMAIN=$(grep NISDOMAIN /etc/sysconfig/network | cut -f2 -d=)
fi

cat > /etc/sysconfig/network << EOL
##
# 2015 ISM, Control 0521
# Dual Stack network devices and ICT equipment that support IPv6 must disable
# the functionality unless it is being used
#
NETWORKING=yes
NOZEROCONF=yes
IPV6INIT=no
IPV6_AUTOCONF=no
EOL


if [ ! -z $NISDOMAIN ]; then
  echo "NISDOMAIN=$NISDOMAIN" >> /etc/sysconfig/network
fi



sed -i 's/^OPTIONS=.*/OPTIONS="-4"/g' /etc/sysconfig/chronyd



if (! grep -q 'OPTIONS' /etc/sysconfig/nscd 2>/dev/null); then
  cat >> /etc/sysconfig/nscd << EOL
## IPv6 is disabled by default to meet ISM control 0521.
#  nscd caches both IPv4 and IPv6 sockets unless explicitly configured
#  to start with a '-4' option for IPv4 only.
OPTIONS="-4"
EOL
fi


firewall-offline-cmd --remove-service dhcpv6-client


echo ">>> Set login banner"
cat << EOF > /etc/issue

###############################################################
#  All connections to this system are monitored and recorded  #
#  Disconnect IMMEDIATELY if you are not an authorized user!  #
###############################################################

EOF


echo ">>> Setup SELinux"
# Add selinux=1 kernel option
sed -i '/GRUB_CMDLINE_LINUX.*$/{s/nofb/nofb selinux=1 enforcing=1/}' /etc/default/grub

  /usr/sbin/setsebool -P xguest_mount_media 0
  /usr/sbin/setsebool -P xguest_use_bluetooth 0
  /usr/sbin/setsebool -P httpd_builtin_scripting 0
  /usr/sbin/setsebool -P httpd_enable_cgi 0
    /usr/sbin/setsebool -P deny_ptrace 1
  /usr/sbin/setsebool -P guest_exec_content 0
  /usr/sbin/setsebool -P xguest_exec_content 0




echo ">>> Disable Ctrl-Alt-Del"

systemctl disable ctrl-alt-del.target
systemctl mask ctrl-alt-del.target && systemctl daemon-reload



yum -q -y remove at rhnsd rhnlib iwl*-firmware 2>/dev/null




  yum -q -y install rng-tools

    systemctl enable rngd






### Commented out for now as RedHat CDN and Fedora repos only use 2048bit RSA ###
### 'FUTURE MODE' requires a minimum of 3072bit RSA ###
#echo ">>> Setting global crypto policy"
#/usr/bin/update-crypto-policies --set FUTURE




cat << EOF >> /root/.bashrc

# root shell timeout
TMOUT=1800
readonly TMOUT
export TMOUT
EOF


echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" >> /etc/fstab






if [ -f /usr/bin/dnf ]; then
  dnf -y update
else
  yum -t -y update
fi










  echo "+++++++++++++++++++++ Reconfiguring Grub and Kernel +++++++++++++++++++++++++++"
  grub2-mkconfig -o /boot/grub2/grub.cfg




      dracut -f --regenerate-all --kernel-cmdline "ip=172.22.1.73::172.22.1.1:255.255.255.0::$real:none nameserver=172.22.1.3 nameserver=172.22.1.4"




sync

# Inform the build system that we are done.
echo "Informing Foreman that we are built"
wget -q -O /dev/null --no-check-certificate http://foreman.core.home.gatwards.org/unattended/built
) 2>&1 | tee /root/install.post.log
exit 0

%end

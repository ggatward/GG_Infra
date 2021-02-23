




url --url http://mirror.internode.on.net/pub/centos/7.9.2009/os/x86_64


lang en_US.UTF-8
selinux --enforcing
keyboard us
skipx


network --bootproto static --ip=172.22.4.11 --netmask=255.255.255.0 --gateway=172.22.4.1 --nameserver=172.22.1.3,172.22.1.4 --mtu=1500 --hostname baremetal1.lab.home.gatwards.org --device=0c:c4:7a:a9:1f:08
rootpw --iscrypted $6$YIYwkSe4yv422JoP$iQQRNqV42UxX4F2DGhntJt.pbfEGko9LI50pX3pGyuV70gvTKu.PntUf/RVsacFkMwHxv5RHZTjno4VRMp.M71
firewall --service=ssh

authconfig --useshadow --passalgo=sha512 --kickstart
timezone --utc UTC




bootloader --location=mbr --append="nofb quiet splash=quiet"



zerombr
clearpart --all --initlabel

part /boot --fstype xfs --size=1024 --ondisk=sda --asprimary
part pv.01 --size=1 --grow --ondisk=sda

volgroup vg_sys --pesize=32768 pv.01

logvol / --fstype xfs --name=root --vgname=vg_sys --size=10240 --fsoptions="noatime"
logvol swap --fstype swap --name=swap --vgname=vg_sys --size=4096
logvol /home --fstype xfs --name=home --vgname=vg_sys --size=1024 --fsoptions="noatime,nosuid,nodev"
logvol /tmp --fstype xfs --name=tmp --vgname=vg_sys --size=8192 --fsoptions="noatime,nosuid,nodev"
logvol /var --fstype xfs --name=var --vgname=vg_sys --size=10240 --fsoptions="noatime,nosuid,nodev"
logvol /var/log/ --fstype xfs --name=log --vgname=vg_sys --size=20480 --fsoptions="noatime,nosuid,nodev,noexec"
logvol /var/log/audit --fstype xfs --name=audit --vgname=vg_sys --size=8192 --fsoptions="noatime,nosuid,nodev,noexec"

# Docker volume
logvol /var/lib/docker --fstype xfs --name=docker --vgname=vg_sys --size=40960 --grow --fsoptions="noatime,nosuid,nodev"


text
reboot

%packages
@Core
NetworkManager
chrony
crontabs
dhclient
redhat-lsb-core
wget
python
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
logger "Starting anaconda baremetal1.lab.home.gatwards.org postinstall"
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(




# eno1 interface
real=`grep -l 0c:c4:7a:a9:1f:08 /sys/class/net/*/{bonding_slave/perm_hwaddr,address} 2>/dev/null | awk -F '/' '// {print $5}' | head -1`
sanitized_real=`echo $real | sed s/:/_/`


cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$sanitized_real
BOOTPROTO="none"
IPADDR="172.22.4.11"
NETMASK="255.255.255.0"
GATEWAY="172.22.4.1"
DOMAIN="lab.home.gatwards.org"
DEVICE=$real
HWADDR="0c:c4:7a:a9:1f:08"
ONBOOT=yes
PEERDNS=yes
PEERROUTES=yes
DEFROUTE=yes
DNS1="172.22.1.3"
DNS2="172.22.1.4"
MTU=1500
EOF



# eno2 interface
real=`grep -l 0c:c4:7a:a9:1f:09 /sys/class/net/*/{bonding_slave/perm_hwaddr,address} 2>/dev/null | awk -F '/' '// {print $5}' | head -1`
sanitized_real=`echo $real | sed s/:/_/`


cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$sanitized_real
BOOTPROTO="none"
IPADDR="172.22.3.11"
NETMASK="255.255.255.0"
GATEWAY="172.22.3.1"
DEVICE=$real
HWADDR="0c:c4:7a:a9:1f:09"
ONBOOT=yes
PEERDNS=no
PEERROUTES=no
DEFROUTE=no
MTU=1500
EOF



# ens5f0 interface
real=`grep -l b4:96:91:09:96:c4 /sys/class/net/*/{bonding_slave/perm_hwaddr,address} 2>/dev/null | awk -F '/' '// {print $5}' | head -1`
sanitized_real=`echo $real | sed s/:/_/`


cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$sanitized_real
BOOTPROTO="none"
IPADDR="172.22.106.11"
NETMASK="255.255.255.0"
DEVICE=$real
HWADDR="b4:96:91:09:96:c4"
ONBOOT=yes
PEERDNS=no
PEERROUTES=no
DEFROUTE=no
MTU=9000
EOF



# ens5f1 interface
real=`grep -l b4:96:91:09:96:c5 /sys/class/net/*/{bonding_slave/perm_hwaddr,address} 2>/dev/null | awk -F '/' '// {print $5}' | head -1`
sanitized_real=`echo $real | sed s/:/_/`


cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$sanitized_real
BOOTPROTO="none"
DEVICE=$real
HWADDR="b4:96:91:09:96:c5"
ONBOOT=yes
PEERDNS=no
PEERROUTES=no
DEFROUTE=no
EOF



# Copy root SSH key for bootstrap
mkdir -p /root/.ssh && chmod 700 /root/.ssh
cat << EOF > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCu4S8wzEwXIVuHD+KK7y08lravhF5BvApvXRAPXXeaHtQ3HeYN+7t9HpyIQYg6OwsxNX7WbKgZ50Ok12t3EPRbEr8M9wWW+S5l0SJlzv7h26uNcIucFvlo5aPmV+XLFY7qokaKPaMEwrb7wG/gBTfsjLbhFNFXfT1bEMEp87/K6LUwoNQ3dBrZq5UWYuvMMW4kMH1igKB9dCWraHGqzlyJh4ol9XApPaDfJ8ujSiNs7NzZhUFeYpGC/eMAwnuhFWUZf/SJJJ53Y6AmPTBZVmpPbaJSNnakWssAG54t6Ay3orVi+cvvQlIB2oyilxE06i7FXgZSouwtJAk0Q2E/4mfj root@localhost.localdomain
EOF
chmod 600 /root/.ssh/authorized_keys
restorecon -Rv /root

# Adding Ansible user

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
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwLQuUy4yp71QeXIv6IiB5yJH5vUIMZnhwPJ+2mE4QLIDEJGMUvJkdJAfX1/Pzh6ngNo+E6dRfQtwG0Uo+9fx2CLFsnZxXT/pMzZcwIZxhl3LVQdvjQlrExb3Z3FfAITK7HlzyEDaVu1VdnNh/KSSwkqr7hb5ytdA85OUZaTw7Hvi73oSH8hpmr4lurfbtcMWkYhlxaS1jI08RYx0bJvwsUQOu8M3TuyVCSNTEM43woS4aXLHI3Grycp4vyMrfUJMtujA/wWxhDYRhfOA1R3S1ABx5EDty/3gtczSKlWQ/Ncdmsd9h5OWU9CWyWGvf32ndU0SeJlOujHxcXBMM/jLV foreman-proxy@foreman.core.home.gatwards.org
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


useradd svc-ansible
cat << EOF > /etc/sudoers.d/svc-ansible
svc-ansible	ALL = (ALL)	NOPASSWD : ALL
Defaults: svc-ansible !requiretty
EOF
mkdir /home/svc-ansible/.ssh && chmod 700 /home/svc-ansible/.ssh
cat << EOF > /home/svc-ansible/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC75ApOJW1sf360AYmh9B57suv+etPYYa6CzvEJjCVZyU+8xPaZR5EacToq9HPYILNAv3TQk1r+K6DKA5+wEpJqm2YzgIPLkZOP1N4Bw19DnAiqIMnDTYa8iIYHOQMpqG/DY6q1/QnP2Gw6r0uTw7zFKH1Vw4DbVJMGOQBJblWFq1G+LSN4j60eiN72kZEMf3fQgLCKUzDdbOUkjJnl/4/SUq5lncMBm88efiJLNwdJzelGkH5QveNioiQ/mXP/DlnLYiCKHh1qJlaD/OGlEuHJSnDD9uD4TknEi8AFqLTDc4XZZgUWF5RWSUwxMIiBuyMtr5Zma20dQpdwqYZT6LcNcMokHHAQ+S/cuibtR/YQ3PsYubUIAbCfeIHjKRdBDUP5ZE/VfybKTE/rlAUQCzpt5w5iBWr3qo2iW7gW/Rvlt78bqCHETnCNHLIT5mm9koA0+kr2dNmiUnb91KpdpNs4tLveVYGtN8tJHL4NDSHqiEeOYklV+uLL2gN6kziB53c= svc-ansible@ansible.core.home.gatwards.org
EOF
chown -R svc-ansible: /home/svc-ansible/.ssh
chmod 600 /home/svc-ansible/.ssh/authorized_keys
restorecon -Rv /home

sync

# Inform the build system that we are done.
echo "Informing Foreman that we are built"
wget -q -O /dev/null --no-check-certificate http://foreman.core.home.gatwards.org/unattended/built
) 2>&1 | tee /root/install.post.log
exit 0

%end

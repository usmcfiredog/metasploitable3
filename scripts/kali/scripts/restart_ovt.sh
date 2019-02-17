#!/bin/bash

cat << EOF > /usr/local/sbin/restart-vm-tools
#!/bin/bash
systemctl stop run-vmblock\\\\x2dfuse.mount
killall -q -w vmtoolsd
systemctl start run-vmblock\\\\x2dfuse.mount
systemctl enable run-vmblock\\\\x2dfuse.mount
vmware-user-suid-wrapper vmtoolsd -n vmusr 2>/dev/null
vmtoolsd -b /var/run/vmroot 2>/dev/null
EOF
chmod +x /usr/local/sbin/restart-vm-tools
ln -sf /usr/local/sbin/restart-vm-tools /root/Desktop/restart-vm-tools
ln -sf /usr/local/sbin/restart-vm-tools /home/vagrant/Desktop/restart-vm-tools
dbus-launch gsettings set org.gnome.nautilus.preferences executable-text-activation 'ask'



set -e
set -x

# clear logs to reset
rm $LOGFILE -f
# to look at the logs live, do
# tail -f install_logs.txt

# the 5.0 bootstrap file installs the correct version of vagrant
# the 4.1 file doesn't
# but we still want to install 4.1 (don't we?)
# so manually install vagrant first

echo "uninistalling existing vagrant installations" | tee $LOGFILE -a
sudo rm -rf /opt/vagrant /usr/bin/vagrant ~/.vagrant.d
echo "Installing vagrant and associated tools..." | tee $LOGFILE -a
sudo apt-get -y install qemu-kvm libvirt-bin libvirt-dev nfs-kernel-server
sudo adduser $USER libvirtd
VAGRANT_SHA256SUM="2f9498a83b3d650fcfcfe0ec7971070fcd3803fad6470cf7da871caf2564d84f"  # version 2.0.1
curl -o /tmp/vagrant.deb https://releases.hashicorp.com/vagrant/2.0.1/vagrant_2.0.1_x86_64.deb
echo "$VAGRANT_SHA256SUM  /tmp/vagrant.deb" | sha256sum -c -
sudo dpkg -i /tmp/vagrant.deb
echo "done"

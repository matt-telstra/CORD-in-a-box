
# this script implements the steps in
# https://guide.opencord.org/install_virtual.html#corddev-vm


LOGFILE=~/install_logs.txt
BRANCH=cord-4.1
#POD_YAML=rcord-virtual.yml # default
POD_YAML=mcord-ng40-virtual.yml
LICENSE_F=~/cord/orchestration/xos_services/venb/xos/synchronizer/files/ng40-license

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

echo 'downloading bootstrap script' | tee $LOGFILE -a
curl -o ~/cord-bootstrap.sh https://raw.githubusercontent.com/opencord/cord/$BRANCH/scripts/cord-bootstrap.sh
chmod +x cord-bootstrap.sh
echo 'running bootstrap script' | tee $LOGFILE -a
./cord-bootstrap.sh -v

#echo 'generating license file' | tee $LOGFILE -a
#python3 gen_license.py $LICENSE_F
#echo 'license file saved to $LICENSE_F' | tee $LOGFILE -a
cp ~/ng40-license $LICENSE_F

cd ~/cord/build
echo 'running make config on pod $POD_YAML' | tee $LOGFILE -a
make PODCONFIG=$POD_YAML config
echo 'running makescript' | tee $LOGFILE -a
make -j4 build |& tee ~/build.out
echo 'finished makescript' | tee $LOGFILE -a

cd ~/cord/build

echo 'repo sync' | tee $LOGFILE -a
repo sync
rm milestones/copy-cord -f
echo 'running 2nd make' | tee $LOGFILE -a
make xos-update-images

echo 'waiting for everything to come up' | tee $LOGFILE -a
sleep 300
echo 'woke up from sleep' | tee $LOGFILE -a

echo 'running make tests' | tee $LOGFILE -a
make  mcord-ng40-test
echo 'make tests passed' | tee $LOGFILE -a
echo 'test logs in ~/cord/build/logs/<timestamp>_mcord-ng40-test' | tee $LOGFILE -a

cd ~/cord/build
export VAGRANT_CWD=~/cord/build/scenarios/cord
vagrant status > status.txt

if diff -wB status.txt ~/expectedStatus.txt; then
    echo 'vagrant status is as expected' | tee $LOGFILE -a
else
    cat status.txt | tee $LOGILE -a
    echo 'vagrant status is ~/cord/build/status.txt, but I expected expectedStatus.txt' | tee $LOGFILE -a
    exit 1
fi


echo 'sshing into all the VMs' | tee $LOGFILE -a

# this will fail if we can't ssh in to this machine
# or that directory doesn't exist
ssh corddev ls /opt/cord

# just check we can ssh in, and that this VM is spun up
for VM in head1
do
    ssh $VM ls
done

# check we can log into the comput1 vm
# but we need to do it via head 1
ssh head1 ssh ubuntu@magnificent-vein.cord.lab ls

echo 'setting up EPC' | tee $LOGFILE -a

PASSWD_FILE=~/cord/build/platform-install/credentials/xosadmin@opencord.org
PASSWD=$(cat $PASSWD_FILE)

echo 'curl -u xosadmin@opencord.org:$PASSWD -X POST http://localhost/xosapi/v1/vepc/vepcserviceinstances -H "Content-Type: application/json" -d "{\"blueprint\":\"build\", \"site_id\": 1}"; exit' | ssh head1

echo 'verifying installation' | tee $LOGFILE -a

for VM in mcordng40_venb-synchronizer_1 mcordng40_vspgwc-synchronizer_1 mcordng40_vspgwu-synchronizer_1 mcordng40_vepc-synchronizer_1
do
   VMLIST=$(ssh head1 docker ps)
   VMFOUND=$(echo $VMLIST | grep $VM | grep " up " -i -c )
   if [ $(ssh head1 docker ps | grep $VM | grep " up " -i -c) == 1 ]
   then
      echo "VM $VM is in head1 and up" | tee $LOGFILE -a
   else
      echo "Error: VM $VM not found in head1, or not up" | tee $LOGFILE -a
      exit 1
   fi
done

ssh head1 "source /opt/cord_profile/admin-openrc.sh; ssh head1 nova list --all-tenants"

echo 'I think I am done.' | tee $LOGFILE -a
echo ' Follow the instructions from https://guide.opencord.org/install_virtual.html#corddev-vm to check' | tee $LOGFILE -a


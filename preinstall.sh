echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
sudo addgroup admin
sudo addgroup libvirtd
sudo adduser $USER admin
sudo adduser $USER libvirtd

echo 'now log out and log back in'
echo 'then run install.sh'

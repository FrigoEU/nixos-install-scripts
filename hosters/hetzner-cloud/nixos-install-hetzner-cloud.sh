#! /usr/bin/env bash

# Script to install NixOS from the Hetzner Cloud NixOS bootable ISO image.
# (tested with Hetzner's `NixOS 20.03 (amd64/minimal)` ISO image).
#
# This script wipes the disk of the server!
#
# Instructions:
#
# 1. Mount the above mentioned ISO image from the Hetzner Cloud GUI
#    and reboot the server into it; do not run the default system (e.g. Ubuntu).
# 2. To be able to SSH straight in (recommended), you must replace hardcoded pubkey
#    further down in the section labelled "Replace this by your SSH pubkey" by you own,
#    and host the modified script way under a URL of your choosing
#    (e.g. gist.github.com with git.io as URL shortener service).
# 3. Run on the server:
#
#       # Replace this URL by your own that has your pubkey in
#       curl -L https://raw.githubusercontent.com/nix-community/nixos-install-scripts/master/hosters/hetzner-cloud/nixos-install-hetzner-cloud.sh | sudo bash
#
#    This will install NixOS and power off the server.
# 4. Unmount the ISO image from the Hetzner Cloud GUI.
# 5. Turn the server back on from the Hetzner Cloud GUI.
#
# To run it from the Hetzner Cloud web terminal without typing it down,
# you can either select it and then middle-click onto the web terminal, (that pastes
# to it), or use `xdotool` (you have e.g. 3 seconds to focus the window):
#
#     sleep 3 && xdotool type --delay 50 'curl YOUR_URL_HERE | sudo bash'
#
# (In the xdotool invocation you may have to replace chars so that
# the right chars appear on the US-English keyboard.)
#
# If you do not replace the pubkey, you'll be running with my pubkey, but you can
# change it afterwards by logging in via the Hetzner Cloud web terminal as `root`
# with empty password.

set -e

# Hetzner Cloud OS images grow the root partition to the size of the local
# disk on first boot. In case the NixOS live ISO is booted immediately on
# first powerup, that does not happen. Thus we need to grow the partition
# by deleting and re-creating it.
sgdisk -d 1 /dev/sda
sgdisk -N 1 /dev/sda
partprobe /dev/sda

mkfs.ext4 -F /dev/sda1 # wipes all data!

mount /dev/sda1 /mnt

nixos-generate-config --root /mnt

# Delete trailing `}` from `configuration.nix` so that we can append more to it.
sed -i -E 's:^\}\s*$::g' /mnt/etc/nixos/configuration.nix

# Extend/override default `configuration.nix`:
echo '
  boot.loader.grub.devices = [ "/dev/sda" ];

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7HGY1mElaItSH+YgegFQJD1uyDCz4kxyiRPv4QHLPQjQMV6i6LiRbBJLMfQcgiWkPXUldCrfxBNwpXzn3KVnXYgITRLg5/Hs+R37EGfOYJfF+ZUnsT9/mXk0RXclVJr9Ysrvcd74IL3f4S5HVykv83P5mfO7dcLO4CVzv3bbf7cfgrM3guBygqgkNieC4s5gPvjWZPeTzMCE4OSiCvpmJvd7AUZVtV5/a8pQbCgbMTKip83lYvhKSKQNnlikrqtzkXKP5sPyeEFdRQBL/HIi4ZcIqkwBfTe9Ej//TSgIrFU52bson0UNVte93x1qtLbQxVPjFg+7JVTBJlJM/tmAoPZPAmIYpTrHVixXBxHf3kDfVvevZCvZA+eDJaoh8jkuqcEg8dL0dQbY+S6r0eCLHB0sIYi6+0y1jIez5YJqzW/G1ApzjmUFBml6lXkZfBtYWp2Ep99natHOurLDi8zGb7w0mNAPo1HWJv6KsRKxSKzMG0LhuAtERIShDUurnjOYU9JUlfw+pMIYoeQce6KIV0ORDvZFrjYCeFFmDMgocaJMl97lOnqpIP+ucWUeJQC7n+Y9dvlLewKtPNgDIdac55VhcFjIHZC3sKpKzdW7sg1eE8/tjE5yiHzTIypZYflrYXXtNDTjW0VlF3wdImjRv33NiFUnDdAMJC5qy/bHRew== simon.van.casteren@gmail.com" # Desktop nixos
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhPcR4aSAww66+ICNd9NOx1lmJQOUY3YIt0gl2SGeROg967N7oxt3AWVnmVndy6FgpqyKjmYWCE4dX/Ncjk4aGskpkHmn4PmzWNCmYwpD7hwtr5OgS/l5i8BGbW3bWMjOExeHtwgWBfV3n0rMrKtP4qt5236XNWOTOtDvcg7gNRvRxXvZmEN86dHPHQAi2bygQpaDjSCN6BB8950nrl7NicQbHOIDUfWd0sMTK7Mrw53peDKQB2NU6jLnLK9El04KTmur0QgSZc1MQjXOjt+P76/p2luJPTe8ZTybs1PARjKjwV3ZZdgGhDPLY8G5GQ6PL73F10kYRpk2p8Cpu9ryb simon@nixos" # Laptop nixos
  ];
}
' >> /mnt/etc/nixos/configuration.nix

nixos-install --no-root-passwd

poweroff

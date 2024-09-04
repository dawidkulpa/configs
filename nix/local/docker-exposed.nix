{...}: {
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk"];
  boot.loader.grub.device = "/dev/vda";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  systemd.services.freeMemory = {
    description = "nix optimise makes a big blueprint on memory, which doesn't work well with proxmox's discard, so this should free up the memory once a day";
    after = "nix-optimise.service";
    script = ''
      sh -c "echo 1 > /proc/sys/vm/drop_caches"
    '';
  };

  swapDevices = [];
  networking.hostName = "docker-exposed";
}

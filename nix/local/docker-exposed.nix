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
    description = "Free memory after nix-optimise.service is run";
    after = ["nix-optimise.service"];
    requires = ["nix-optimise.service"];
    wantedBy = ["nix-optimise.service"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = ''echo 1 > /proc/sys/vm/drop_caches'';
    };
  };

  swapDevices = [];
  networking.hostName = "docker-exposed";
}

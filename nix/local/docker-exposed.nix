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

  fileSystems."/mnt/nfs/traefik-edge" = {
    device = "nas.home:/mnt/nvme/docker-volumes/traefik-edge";
    fsType = "nfs4";
    options = ["rw"];
  };

  fileSystems."/mnt/nfs/pterodactyl-panel" = {
    device = "nas.home:/mnt/nvme/docker-volumes/pterodactyl-panel";
    fsType = "nfs4";
    options = ["rw"];
  };

  swapDevices = [];
  networking.hostName = "docker-exposed";
}
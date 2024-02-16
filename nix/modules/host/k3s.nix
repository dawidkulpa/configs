{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.programs.k3s;
in {
  options.my.programs.k3s = {
    enable = mkEnableOption "my k3s configuration";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 
      6443
      2379 # etcd
      2380 # etcd
    ];

    networking.firewall.allowedUDPPorts = [ 8472 ]; # flannel

    services.k3s = {
      enable = true;
      role = "server";
      token = ''$(cat "${config.age.secrets.k3sToken.path}")'';
      serverAddr = "192.168.50.4";
    };
  };
}

{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.k3s;
  language = name: text: text;
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
      token = language "fish" ''(cat "${config.age.secrets.k3sToken.path}")'';
      serverAddr = "192.168.50.4";
    };
  };
}

# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let unstable = import <nixpkgs-unstable> {
  config = config.nixpkgs.config;
};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    # Home assistant requirements
    "net.ipv4.ip_forward" = 1; 
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.eno1.accept_ra" = 2;
    "net.ipv6.conf.eno1.accept_ra_rt_info_max_plen" = 64;
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  powerManagement.enable = true;
  services.tlp.enable = true;

  system.autoUpgrade = {
    enable = true;
    dates = "02:00";
    allowReboot = true;
  };

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  networking.hostName = "martinsv"; # Define your hostname.

  networking.useDHCP = false;
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [ ]; 
  };
  systemd.network = {
    enable = true;
    wait-online.enable = false;
    networks."20-wired" = {
      matchConfig.Name = "eno1";
      networkConfig = {
        Address = "192.168.0.10/24";
        Gateway = "192.168.0.1";
        # Use the local Pi-hole proxy. Its upstream fallback is configured in nginx.conf.
        DNS = "192.168.0.10";
        DHCP = false;
      };
    };
  };

  # Set your time zone.
  time.timeZone = "America/Montreal";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.martin = {
    isNormalUser = true;
    description = "Martin";
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.fish;
    home = "/home/martin";
    linger = true;
  };

  powerManagement.powertop.enable = true;

  environment.localBinInPath = true;
  programs.fish.enable = true;
  programs.nix-ld.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    # utils
    git
    git-lfs
    vim 
    gh
    btop
    nvtopPackages.intel
    lazygit
    tree
    zip unzip
    wget rsync
    bind # dig, etc
    smartmontools
    ffmpeg
    hdparm

    # nicer shell
    tmux
    ripgrep
    eza
    bat
    fd
    direnv
    zoxide
    fzf

    # required tooling
    docker-compose
    docker-buildx
    restic
    pigz
    sqlite
    nginx
    gnupg

    # "apps"
    unstable.codex
  ];

  # docker
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    hosts = ["tcp://192.168.0.10:2375" "unix:///var/run/docker.sock"];
  };
  
  # podman
  virtualisation.containers.enable = true;
  virtualisation.podman.enable = true;
  environment.etc."containers/systemd".source = /home/martin/home-server-configs/podman/root;
  systemd.timers.podman-auto-update = {
    wantedBy = [ "timers.target" ];
    overrideStrategy = "asDropin";
  };
  systemd.services.podman-tcp = {
    description = "Podman TCP API Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0 tcp://192.168.0.10:2377";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # nginx
  services.nginx = {
    enable = true;
    config = pkgs.lib.readFile /home/martin/home-server-configs/nginx.conf;
  };

  # exim (mail sending)
  services.exim = {
    enable = true;
    config = pkgs.lib.readFile /var/lib/mail/exim.conf;
  };

  # smarctl notif
  services.smartd = {
    enable = true;
    
    notifications = {
      mail = {
        enable = true;
        sender = "root";
        recipient = "martin.chaperot@proton.me";
        mailer = "/run/current-system/sw/bin/sendmail";
      };
      wall.enable = false;
      test = true;
    };

    autodetect = true;
  };

  # fail2ban
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment.enable = true;

    ignoreIP = [ "192.168.0.0/16" ];

    jails = {
      sshd.settings = {
        enabled = true;
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitEmptyPasswords = false;
      PermitRootLogin = "no";
    };
  };

  # Open ports in the firewall.
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      80 443 # web
      22 # ssh
      21027 22000 # syncthing
    ];
    allowedUDPPorts = [ 
      22000 # syncthing
    ];
    extraInputRules = ''
      ip saddr 192.168.0.0/24 accept
      ip saddr 172.16.0.0/12 accept
    '';
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}


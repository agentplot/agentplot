{ lib, ... }:
let
  machineIdFor = name: builtins.substring 0 32 (builtins.hashString "sha256" "microvm:${name}");
  persistDirFor = name: "/data/microvm/${name}";

  # Deterministic vsock CID: hash hostname to a value >= 3 (0-2 are reserved)
  cidFor = name:
    let
      hash = builtins.hashString "sha256" "vsock:${name}";
      # Take first 4 hex chars → 0..65535, then shift to >= 3
      raw = builtins.fromTOML "v = 0x${builtins.substring 0 4 hash}";
    in
    raw.v + 3;

  # Deterministic MAC: 02:<first 5 octets of SHA-256(hostname)>
  macFor = name:
    let
      hash = builtins.hashString "sha256" name;
      octets = lib.genList (i: builtins.substring (i * 2) 2 hash) 5;
    in
    "02:${lib.concatStringsSep ":" octets}";

  # TAP interface name: vm-<hostname>, truncated to 15 chars max (Linux limit)
  tapNameFor = name:
    let
      prefix = "vm-";
      maxLen = 15;
      available = maxLen - (builtins.stringLength prefix);
    in
    if builtins.stringLength name <= available
    then "${prefix}${name}"
    else "${prefix}${builtins.substring (builtins.stringLength name - available) available name}";
in
{
  _class = "clan.service";
  manifest.name = "microvm";
  manifest.description = "Run Clan machines as MicroVMs on a host with cloud-hypervisor";
  manifest.readme = builtins.readFile ./README.md;
  manifest.categories = [ "System" ];

  roles.host = {
    description = "Machine that runs MicroVM guests";

    perInstance =
      {
        roles,
        machine,
        ...
      }:
      {
        nixosModule =
          { self, pkgs, ... }:
          let
            guests = lib.filterAttrs (_: cfg: cfg.settings.host == machine.name) (roles.guest.machines or { });
            guestNames = lib.attrNames guests;
          in
          {
            imports = [ self.inputs.microvm.nixosModules.host ];

            microvm.vms = lib.genAttrs guestNames (_: {
              flake = self;
              autostart = true;
            });

            systemd.tmpfiles.rules = lib.flatten (
              map (
                name:
                let
                  persistDir = persistDirFor name;
                  machineId = machineIdFor name;
                in
                [
                  "d ${persistDir} 0755 root root"
                  "d ${persistDir}/ssh 0700 root root"
                  "d ${persistDir}/journal 0700 root root"
                  "d ${persistDir}/sops-nix 0700 root root"
                  "L+ /var/log/journal/${machineId} - - - - ${persistDir}/journal/${machineId}"
                  "L+ /var/lib/machines/${name}/var/log/journal - - - - ${persistDir}/journal"
                ]
              ) guestNames
            );

            systemd.services = lib.mkMerge (
              lib.mapAttrsToList (
                name: cfg:
                let
                  persistDir = persistDirFor name;
                in
                lib.mkIf (cfg.settings.ageKeyFile != null) {
                  "microvm-seed-age-${name}" = {
                    description = "Pre-seed sops age key for microvm ${name}";
                    wantedBy = [ "microvms.target" ];
                    before = [ "microvm@${name}.service" ];
                    unitConfig.ConditionPathExists = "!${persistDir}/sops-nix/key.txt";
                    serviceConfig = {
                      Type = "oneshot";
                      RemainAfterExit = true;
                      ExecStart = toString [
                        "${pkgs.coreutils}/bin/install"
                        "-m" "400"
                        cfg.settings.ageKeyFile
                        "${persistDir}/sops-nix/key.txt"
                      ];
                    };
                  };
                }
              ) guests
            );

            clan.core.state.microvm.folders = [ "/data/microvm" ];
          };
      };
  };

  roles.guest = {
    description = "Machine that runs as a MicroVM guest";

    interface =
      { lib, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "Inventory machine name of the host that runs this guest";
          };
          ageKeyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Host-side path to the decrypted age key for this guest. Copied to persistent storage before first boot.";
          };
        };
      };

    perInstance =
      { ... }:
      {
        nixosModule =
          {
            self,
            config,
            lib,
            ...
          }:
          let
            hostName = config.networking.hostName;
            machineId = machineIdFor hostName;
            baseDir = "/var/lib/microvms/${hostName}";
            persistDir = persistDirFor hostName;
            mac = macFor hostName;
            tapName = tapNameFor hostName;
          in
          {
            imports = [ self.inputs.microvm.nixosModules.microvm ];

            clan.core.deployment.requireExplicitUpdate = true;

            environment.etc."machine-id" = {
              mode = "0644";
              text = machineId + "\n";
            };

            sops.useSystemdActivation = true;

            microvm = {
              hypervisor = lib.mkDefault "cloud-hypervisor";
              vcpu = lib.mkDefault 1;
              hotplugMem = lib.mkDefault 1536;
              socket = lib.mkDefault "control.socket";
              vsock.cid = cidFor hostName;

              interfaces = [
                {
                  type = "tap";
                  id = tapName;
                  mac = mac;
                }
              ];

              shares = [
                {
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                  tag = "store";
                  proto = "virtiofs";
                  socket = "${baseDir}/store.socket";
                }
                {
                  source = "${persistDir}/sops-nix";
                  mountPoint = "/var/lib/sops-nix";
                  tag = "sops-nix";
                  proto = "virtiofs";
                  readOnly = false;
                  socket = "${baseDir}/sops.socket";
                }
                {
                  source = "${persistDir}/ssh";
                  mountPoint = "/persist/ssh-host-keys";
                  tag = "ssh";
                  proto = "virtiofs";
                  socket = "${baseDir}/ssh.socket";
                }
                {
                  source = "${persistDir}/journal";
                  mountPoint = "/var/log/journal";
                  tag = "journal";
                  proto = "virtiofs";
                  socket = "journal.sock";
                }
                {
                  source = persistDir;
                  mountPoint = "/persist";
                  tag = "persist";
                  proto = "virtiofs";
                  socket = "${baseDir}/persist.socket";
                }
              ];
            };

            # Rename TAP interface inside guest to eth0 by matching MAC
            systemd.network.links."10-eth0" = {
              matchConfig.MACAddress = mac;
              linkConfig.Name = "eth0";
            };

            # Mark all share mountpoints as neededForBoot
            fileSystems = lib.genAttrs
              (map (share: share.mountPoint) config.microvm.shares)
              (_: { neededForBoot = true; });

            services.openssh.hostKeys = [
              { path = "/persist/ssh-host-keys/ssh_host_ed25519_key"; type = "ed25519"; }
              { path = "/persist/ssh-host-keys/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
            ];

            networking.useNetworkd = true;
            networking.useDHCP = false;
            networking.firewall.trustedInterfaces = [ "eth0" ];

            system.stateVersion = "25.11";
          };
      };
  };
}

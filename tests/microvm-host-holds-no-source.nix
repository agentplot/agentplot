# Flake check: a microvm host's closure holds its guests' systems and none of
# the consuming flake's source.
#
# Evaluates a host and a guest through the microvm service's own roles and the
# real microvm.nix host module, as x86_64-linux NixOS systems that are
# instantiated, never built, and reads the string context of each
# install-microvm-<guest> script: the store paths the host's closure will hold
# through it. The verdict is reached at evaluation; a failure is a throw.
#
# Run: nix build --no-link ".#checks.$(nix config show system).microvm-host-holds-no-source"
{ self }:
let
  inherit (self.inputs.nixpkgs) lib;

  svc = import ../services/microvm { inherit lib; };

  hostModule =
    (svc.roles.host.perInstance {
      roles.guest.machines = {
        guest.settings = {
          host = "host";
          ageKeyFile = null;
        };
        elsewhere.settings = {
          host = "other";
          ageKeyFile = null;
        };
      };
      machine.name = "host";
    }).nixosModule;

  guestModule = (svc.roles.guest.perInstance { }).nixosModule;

  # Options clan-core and sops-nix would declare, which the roles set.
  stubs =
    { lib, ... }:
    {
      options.clan.core.state = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
      };
      options.clan.core.deployment.requireExplicitUpdate = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      options.sops.useSystemdActivation = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

  # The consuming flake. Its outPath is this flake's source, which stands for
  # any consumer's.
  consumer = self // {
    nixosConfigurations.guest = guest;
  };

  system =
    modules:
    lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs.self = consumer;
      modules = [ stubs ] ++ modules;
    };

  guest = system [
    guestModule
    { networking.hostName = "guest"; }
  ];

  hostModules = [
    hostModule
    {
      networking.hostName = "host";
      system.stateVersion = "25.11";
    }
  ];

  host = system hostModules;

  # A host that installs its guest from the flake, as the role once did.
  standIn = system (
    hostModules
    ++ [
      {
        microvm.vms.guest = {
          flake = lib.mkForce consumer;
          evaluatedConfig = lib.mkForce null;
        };
      }
    ]
  );

  source = builtins.unsafeDiscardStringContext (toString consumer.outPath);

  installScript = sys: name: sys.config.systemd.services."install-microvm-${name}".script;

  refersTo = path: sys: name: builtins.hasAttr path (builtins.getContext (installScript sys name));

  # The reader: whether a system's install unit for a guest refers to the source.
  readsSource = refersTo source;

  drvPath = drv: builtins.unsafeDiscardStringContext drv.drvPath;

  vms = host.config.microvm.vms;
  guestNames = lib.attrNames vms;

  failing = pred: lib.filter pred guestNames;

  fail =
    requirement: guests: why:
    throw "microvm-host-holds-no-source: ${requirement}: ${why}: ${lib.concatStringsSep ", " guests}";

  installs = "A host installs each of its guests from its evaluated configuration";
  holds = "A host's closure holds its guests' systems and none of the flake's source";
  gate = "The merge gate fails a host that holds the flake's source";

  # 1. The reader is proven before it is trusted.
  readerSees =
    if readsSource standIn "guest" then
      true
    else
      fail gate [ "guest" ]
        "the reader is blind, finding no source in the install unit of a stand-in host that installs from the flake";

  # 2. No guest is installed from a flake or with an updateFlake.
  noFlake =
    let
      guests = failing (name: vms.${name}.flake != null || vms.${name}.updateFlake != null);
    in
    if guests == [ ] then true else fail installs guests "the host installs it from a flake";

  # 3. The host installs exactly its own guests.
  ownGuests =
    let
      missing = lib.subtractLists guestNames [ "guest" ];
      extra = lib.subtractLists [ "guest" ] guestNames;
    in
    if missing != [ ] then
      fail installs missing "the host does not install its guest"
    else if extra != [ ] then
      fail installs extra "the host installs a guest of another host"
    else
      true;

  # 4. Each guest's evaluated configuration is the consumer's.
  evaluated =
    let
      guests = failing (
        name:
        vms.${name}.evaluatedConfig == null
        || drvPath vms.${name}.evaluatedConfig.config.system.build.toplevel
          != drvPath consumer.nixosConfigurations.${name}.config.system.build.toplevel
      );
    in
    if guests == [ ] then
      true
    else
      fail installs guests "its evaluatedConfig is not the consuming flake's nixosConfigurations.<guest>";

  # 5. Each install unit refers to its guest's system and runner.
  refersToGuest =
    let
      guestConfig = name: vms.${name}.evaluatedConfig.config;
      guests = failing (
        name:
        !(refersTo (drvPath (guestConfig name).system.build.toplevel) host name)
        || !(refersTo (drvPath (guestConfig name).microvm.declaredRunner) host name)
      );
    in
    if guests == [ ] then
      true
    else
      fail holds guests "its install unit does not refer to the guest's system toplevel and declared runner";

  # 6. No install unit refers to the source.
  noSource =
    let
      guests = failing (readsSource host);
    in
    if guests == [ ] then
      true
    else
      fail holds guests "its install unit refers to the consuming flake's source ${source}";

  verdict = readerSees && noFlake && ownGuests && evaluated && refersToGuest && noSource;
in
pkgs:
assert verdict;
pkgs.runCommand "microvm-host-holds-no-source" { } "touch $out"

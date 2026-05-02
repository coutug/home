{ lib, ... }:

{
  disko.devices = {
    disk.root = {
      device = lib.mkDefault "/dev/disk/by-id/ata-WDC_WD7500BPKT-80PK4T0_WD-WX41E72JJ094";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          efi = {
            name = "efi";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "150G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
          data-root = {
            name = "data-root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/data-root";
            };
          };
        };
      };
    };
  };
}

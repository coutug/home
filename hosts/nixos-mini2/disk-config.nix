{ lib, ... }:

{
  disko.devices = {
    disk.root = {
      device = lib.mkDefault "/dev/disk/by-id/ata-ST4000DM004-2U9104_ZFN5LSXN";
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
    disk.data = {
      device = lib.mkDefault "/dev/disk/by-id/ata-TOSHIBA_DT01ACA200_77U9XSUAS";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          data = {
            name = "data";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/data-ext";
            };
          };
        };
      };
    };
  };
}

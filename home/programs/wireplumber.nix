{ ... }:
{
  xdg.configFile."wireplumber/wireplumber.conf.d/50-disable-headset-autoswitch.conf".text = ''
    wireplumber.settings = {
      bluetooth.autoswitch-to-headset-profile = false
    }
  '';
}

# Example shown is using FirstMedia ISP in Indonesia, with their DOCSIS 2.0 modem.
# NOTE that this may not work with their DOCSIS 3.0 modem (the one with WiFi built-in).
# since the modem do not expose the ISP IP directly.

:local interfaceName;
:set interfaceName "ether2-fm"; # replace this with your interface name
:local newGw [ip dhcp-client get [find interface=$interfaceName] gateway];
:local newIp [ip dhcp-client get [find interface=$interfaceName] address];
:local newNetmask [:pick $newIp [:find $newIp "/" +1] [:len $newIp]];
:set newIp [:pick $newIp 0 [:find $newIp "/" -1]];
:log info "new FM lease (ip=$newip, gw=$newGw)";

# set routes
:local wanRouteLabel;
:set wanRouteLabel "FM"; # replace this with the label you use to identify the `comment` part in IP > Route
:foreach existingRoute in=[/ip route find where comment=$wanRouteLabel] do={
  :set $existingGw [:tostr [/ip route get $existingRoute gateway]];
  :if ($existingGw != $newGw) do={
    /ip route set $existingRoute gateway=$newGw;
  }
}

# set new redirection IP
:local wanFirewallLabel;
:set wanFirewallLabel "FM"; # replace this with the label you use to identify the `comment` part in IP > Firewall > NAT
:foreach existingNat in=[/ip firewall nat find where comment~$wanFirewallLabel] do={
  :set $existingIp [:tostr [/ip firewall nat get $existingNat dst-address]];
  :if ($existingIp != $newIp) do= {
    /ip firewall nat set $existingNat dst-address=$newIp;
  }
}

# setup new WAN address list
:local firewallAddressListLabel;
:set firewallAddressListLabel "wan-fm"; # replace this with the label you use to identify the `comment` part in IP > Firewall > Address :ost

# this section may need to be adapted if your ISP uses multi subnet.
:local wanSubnet [/ip firewall address-list find where comment=$firewallAddressListLabel];
:local existingWanSubnet [/ip firewall address-list get $wanSubnet address];
:local newWanSubnet [/ip address get [find interface=$interfaceName] network];
:set $newWanSubnet ($newWanSubnet . $newNetmask);
:if ($existingWanSubnet != $newWanSubnet do= {
  /ip firewall address-list set $wanSubnet address=$newWanSubnet;
}
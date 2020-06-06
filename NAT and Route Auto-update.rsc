# Example shown is using FirstMedia ISP in Indonesia, with their DOCSIS 2.0 modem.
# NOTE that this may not work with their DOCSIS 3.0 modem (the one with WiFi built-in).
# since the modem do not expose the ISP IP directly.

:local interfaceName "ether2-fm"; # replace this with your interface name
:local interfaceLabel "FM"; # replace this with desired name for your interface in the log.
/ip dhcp-client
:local newGw [get [find interface=$interfaceName] gateway];
:local newIp [get [find interface=$interfaceName] address];
:local newNetmask [:pick $newIp [:find $newIp "/" +1] [:len $newIp]];
:set newIp [:pick $newIp 0 [:find $newIp "/" -1]];
:log info "[dhcp-client] new $interfaceLabel lease (ip=$newIp, gw=$newGw, mask=$newNetmask)";

# set routes
/ip route
:local wanRouteLabel "FM"; # replace this with the label you use to identify the `comment` part in IP > Route
:local existingGw;
:local routeDstAddress;
:local routeDistance;
:local routeMark;
:foreach existingRoute in=[find where comment=$wanRouteLabel] do={
  :set $existingGw [:tostr [get $existingRoute gateway]];
  :if ($existingGw != $newGw) do={
    set $existingRoute gateway=$newGw;
    
    # extra info for logging
    :set $routeDstAddress [:tostr [get $existingRoute dst-address]];
    :set $routeDistance [:tostr [get $existingRoute distance]];
    :set $routeMark [:tostr [get $existingRoute distance]];
    :log info "[dhcp-client] updated route (dst=$routeDstAddress, distance=$routeDistance, mark=$routeMark) gateway from $existingGw to $newGw";
  }
}

# set new redirection IP for NAT addresses
/ip firewall nat
:local wanFirewallLabel "FM"; # replace this with the label you use to identify the `comment` part in IP > Firewall > NAT
:local existingIp;
:local natLabel;
:local natToAddresses;
:local natToPorts;
:local natDstPort;
:foreach existingNat in=[find where comment~$wanFirewallLabel] do={
  :set $existingIp [:tostr [get $existingNat dst-address]];
  :if ($existingIp != $newIp) do={
    set $existingNat dst-address=$newIp;

    # extra info for logging
    :set $natLabel [get $existingNat comment];
    :set $natDstPort [get $existingNat dst-port];
    :set $natToAddresses [get $existingNat to-addresses];
    :set $natToPorts [get $existingNat to-ports];
    :log info "[dhcp-client] updated NAT (comment=$natLabel, dst-port=$natDstPort, to-addresses=$natToAddresses, to-ports=$natToPorts) from $existingIp to $newIp"
  }
}

# setup new WAN address list
:local firewallAddressListLabel "wan-fm"; # replace this with the label you use to identify the `comment` part in IP > Firewall > Address :ost

# this section may need to be adapted if your ISP uses multi subnet.
/ip firewall address-list
:local wanSubnet [find where comment=$firewallAddressListLabel];
:local existingWanSubnet [get $wanSubnet address];
:local newWanSubnet [/ip address get [find interface=$interfaceName] network];
:set $newWanSubnet ($newWanSubnet . $newNetmask);
:if ($existingWanSubnet != $newWanSubnet) do={
  set $wanSubnet address=$newWanSubnet;

  # extra info for logging
  :log info "[dhcp-client] updated subnet for `$firewallAddressListLabel` from $existingWanSubnet to $newWanSubnet";
}
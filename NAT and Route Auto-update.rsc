:local newGw [ip dhcp-client get [find interface="ether2-fm"] gateway];
:local newIp [ip dhcp-client get [find interface="ether2-fm"] address];
:set newIp [:pick $newIp 0 [:find $newIp "/" -1]];
:log info "new FM lease (ip=$newip, gw=$newGw)";

# set routes
:foreach existingRoute in=[/ip route find where comment="FM"] do={
  :set $existingGw [:tostr [/ip route get $existingRoute gateway]];
  :if ($existingGw != $newGw) do={
    /ip route set $existingRoute gateway=$newGw;
  }
}

# set new redirection IP
:foreach existingNat in=[/ip firewall nat find where comment~"FM"] do={
  :set $existingIp [:tostr [/ip firewall nat get $existingNat dst-address]];
  :if ($existingIp != $newIp) do= {
    /ip firewall nat set $existingNat dst-address=$newIp;
  }
}
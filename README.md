# RouterOS Scripts

A collection of scripts for MikroTik routers running RouterOS.

Available scripts:
- **NAT and Route Auto-update.rsc** - for auto-updating Firewall (NAT and address list), and Route bindings.

## Notes

1. **NAT and Route Auto-update.rsc**
  - I personally installed the script on the DHCP Client > `<interface name>` > Advanced tab. Therefore, the script is set to trigger whenever a new address is fetched.
  - May need to be adapted if your ISP uses multi-subnet or multi-IP.

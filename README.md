# vpn-rules

Rule repository for app routing.

## Structure
- `rules/Direct/geoip`
- `rules/Direct/geosite`
- `rules/Proxy/geoip`
- `rules/Proxy/geosite`

## Sources
- geoip: `runetfreedom/russia-blocked-geoip` (`release/srs`)
- geosite: `runetfreedom/russia-v2ray-rules-dat` (`release/sing-box/rule-set-geosite`)

## Routing intent
- `ru-blocked` + `ru-blocked-community` -> proxy
- provider rules in Proxy -> proxy
- `ru-whitelist` + `ru` + `yandex` -> direct
- fallback -> direct

## Automation
- Auto-sync every 10 hours
- Manual run via GitHub Actions `Sync VPN Rules`

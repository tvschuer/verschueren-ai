# verschueren-ai

Statische site voor `verschueren.ai` — huisbasis voor de privé-automatisering, en de twee documenten die
Google OAuth in productiemodus verplicht stelt (homepage + privacybeleid).

Geen build-stap, geen JS, geen analytics, geen externe requests. Drie HTML-bestanden, één CSS-bestand,
nginx erbovenop.

## Waarom dit bestaat

De OAuth-app van de Gmail/Calendar/Drive-integratie staat in **Testing**, waardoor elke refresh token na
7 dagen vervalt. Publiceren naar productie vereist een *App domain*: homepage-URL, privacybeleid-URL en
geverifieerde authorised domains. Dit repo levert die URLs.

**Belangrijk:** upload géén logo in de Branding-pagina. Een logo maken van de app een geval voor
brand verification; zonder logo (en met user type External + status In production) blijft de app
functioneel voor eigen gebruik, met alleen de "unverified app"-waarschuwing en de 100-gebruikerscap —
ruim voldoende voor twee eigen accounts.

## Lokaal testen

```bash
docker build -t verschueren-ai:test .
docker run --rm -p 8099:80 verschueren-ai:test
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8099/privacy   # 200
```

## Status van de uitrol (2026-10-25)

| Laag | Status |
|---|---|
| Repo + CI | ✅ `tvschuer/verschueren-ai` (private), workflow `build` groen, image in GHCR |
| Portainer | ✅ stack **10** `verschueren-ai`, service `web`, container `verschueren-ai-web-1`, poort **8083** |
| NPM | ✅ proxy host **12** `verschueren.ai` + `www.verschueren.ai` → `192.168.1.105:8083`, block_exploits aan, geen origin-cert (TLS eindigt bij Cloudflare) |
| Cloudflare | ⛔ nog te doen: zone `verschueren.ai` + twee tunnel-public-hostnames |
| Easyhost | ⛔ nog te doen: nameservers naar Cloudflare (na zone-export) |

DNS-importbestand voor Cloudflare: `docs/dns-import-verschueren.ai.txt` (BIND-formaat; CNAME's na import op
DNS-only zetten).

## Uitrollen (bestaand homelab-patroon)

Repo → GHCR-image → Portainer-stack → NPM proxy host → Cloudflare Tunnel.

1. Private repo `tvschuer/verschueren-ai`; push naar `main` → `.github/workflows/build.yml` bouwt
   `ghcr.io/tvschuer/verschueren-ai:latest`.
2. Portainer (192.168.1.105): stack uit `docker-compose.yml`, poort **8083** (8081/8082 zijn bezet).
3. NPM (192.168.1.106:81): proxy host `verschueren.ai` → `192.168.1.105:8083`, block_exploits aan,
   Let's Encrypt-certificaat aanvragen.
4. Cloudflare Tunnel (`e3f28e2f-4c48-4ede-b639-ed4500e2dd29`): public hostname `verschueren.ai` →
   `http://192.168.1.106:80`. Idem `www` (of een redirect-regel).

## DNS: verschueren.ai staat nu bij Easyhost, niet bij Cloudflare

`NS = ns1/ns2/ns3.easyhost.be`, apex `A = 217.21.190.175` (Combell/Easyhost-parkpagina, nginx, **geen
TLS op 443**). De tunnelroute werkt alleen als de zone in Cloudflare staat — dus de zone moet verhuizen.
Dat raakt de **mail** (Proton), dus dit is de enige stap met echt risico.

### Records die vandaag live staan (geïnventariseerd 2026-10-25)

| Type | Naam | Waarde | Bijzonderheid |
|---|---|---|---|
| MX 10 | @ | `mail.protonmail.ch` | |
| MX 20 | @ | `mailsec.protonmail.ch` | |
| MX 50 | @ | `mx.backup.mailprotect.be` | backup-MX Easyhost |
| TXT | @ | `v=spf1 include:_spf.protonmail.ch ~all` | |
| TXT | @ | `protonmail-verification=276b07ad31945275056f0ac0a353d413d7f48962` | niet weglaten, breekt Proton-domeinverificatie |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine` | |
| CNAME | `protonmail._domainkey` | `protonmail.domainkey.d2lhzudw4yhe5thoreclhstwfafboqwlfqiqd3z73u32spqg6fssq.domains.proton.ch` | DKIM |
| CNAME | `protonmail2._domainkey` | `protonmail2.domainkey.…domains.proton.ch` | DKIM |
| CNAME | `protonmail3._domainkey` | `protonmail3.domainkey.…domains.proton.ch` | DKIM |
| CNAME | `autodiscover` | `autodiscover.mailprotect.be` | Outlook-autoconfig |
| A | @ en `www` | `217.21.190.175` | wordt vervangen door de tunnel |

Er is **geen** wildcard en **geen** CAA-record.

### Volgorde (niet omdraaien)

1. Exporteer de zone in het Easyhost-paneel (backup vóór alles).
2. Zone toevoegen in Cloudflare (Full setup), records hierboven **één op één** overnemen.
   Mail-records (MX, de drie DKIM-CNAME's, autodiscover) op **DNS-only** (grijze wolk) — proxying breekt
   mailverkeer en DKIM-validatie.
3. `dig`-vergelijking oud vs nieuw zolang de NS nog bij Easyhost staan (vergelijk via
   `dig @ns1.easyhost.be` en `dig @<nieuwe CF-nameserver>`).
4. Pas dan de nameservers bij Easyhost aan naar de twee CF-nameservers.
5. Na propagatie: MX + SPF + DKIM + DMARC opnieuw valideren (testmail naar Gmail/Outlook, headers
   controleren op `spf=pass` en `dkim=pass`), en de A-records naar de tunnel zetten.
6. Search Console: `verschueren.ai` verifiëren (DNS-TXT via Cloudflare) — nodig om het domein als
   *authorised domain* in de OAuth-branding te kunnen gebruiken.

## Google Cloud Branding-velden

| Veld | Waarde |
|---|---|
| App name | `Verschueren AI` (geen Google-merknamen, geen logo) |
| User support email | `tvschuer@gmail.com` |
| Application home page | `https://verschueren.ai` |
| Application privacy policy link | `https://verschueren.ai/privacy` |
| Application terms of service link | `https://verschueren.ai/terms` |
| Authorised domains | `verschueren.ai` (en `quadreg.be` alleen als daar echt een URL staat) |
| Developer contact | `tom@quadreg.be` |

`gmail.com` hoort **niet** in de authorised domains: dat is geen domein van jou en Google wijst het af.

# verschueren.ai

Statische site voor `verschueren.ai` — de huisbasis van de privé-automatisering, en de twee documenten die
Google OAuth in productiemodus verplicht stelt (homepage + privacybeleid).

Geen build-stap, geen JS, geen analytics, geen externe requests. Drie pagina's, één CSS-bestand.

## Waarom dit bestaat

De OAuth-app van de Gmail/Calendar/Drive-integratie staat in **Testing**, waardoor elke refresh token na
zeven dagen vervalt. Publiceren naar productie vereist een *App domain*: homepage-URL, privacybeleid-URL en
geverifieerde authorised domains. Deze repo levert die URL's.

**Twee regels bij het publiceren:** upload géén logo (dat maakt er een brand-verification-case van) en zet
`gmail.com` niet in de authorised domains (geen domein van jou). Met user type External + status
*In production* blijft de app werken voor eigen gebruik, met alleen de "unverified app"-waarschuwing en de
100-gebruikerscap — ruim voldoende voor twee eigen accounts.

## Structuur

De repo-root **is** de site-root. Zo serveren GitHub Pages en de nginx-image exact dezelfde bestanden,
zonder copieën of een build-stap.

```
index.html            /
style.css             /style.css
privacy/index.html    /privacy/  (en /privacy via 301)
terms/index.html      /terms/
CNAME                 custom domain voor GitHub Pages
.nojekyll             geen Jekyll-verwerking
Dockerfile            nginx-image voor de homelab-mirror
nginx/default.conf    nette URL's + robots.txt
docs/                 DNS-inventaris (alleen nodig bij een latere zone-verhuizing)
```

Alle interne links zijn **relatief**. Daardoor werkt dezelfde HTML op het domein, onder een
project-pages-pad (`/verschueren-ai/`) én achter nginx.

## Hosting: GitHub Pages (actief)

Route gekozen omdat Easyhost geld vraagt voor een nameserver-wijziging; met Pages blijft de DNS — en dus de
Proton-mail — volledig bij Easyhost staan.

**DNS bij Easyhost (enkel deze records aanpassen/toevoegen):**

| Type | Naam | Waarde |
|---|---|---|
| A | `@` | `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153` |
| AAAA (optioneel) | `@` | `2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153` |
| CNAME | `www` | `tvschuer.github.io` |

De bestaande park-A `217.21.190.175` moet **verdwijnen** (die vier A-records vervangen hem).
MX, SPF, Proton-verificatie, DMARC, de drie DKIM-CNAME's en `autodiscover` blijven **ongewijzigd** — dat is
het hele punt van deze route.

Certificaat: GitHub vraagt automatisch een Let's Encrypt-cert aan zodra de DNS-check slaagt. Daarna
**Enforce HTTPS** aanzetten in *Settings → Pages*.

## Lokale mirror (homelab, slapend)

Dezelfde inhoud draait ook als container in het homelab, klaar om over te schakelen als je ooit de zone naar
Cloudflare verhuist:

| Laag | Waarde |
|---|---|
| Image | `ghcr.io/tvschuer/verschueren-ai:latest` (CI bouwt op elke push naar `main`) |
| Portainer | stack **10** `verschueren-ai`, service `web`, poort **8083** |
| NPM | proxy host **12** `verschueren.ai` + `www.verschueren.ai` → `192.168.1.105:8083` |

Verifieer zonder DNS met een Host-header:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -H 'Host: verschueren.ai' http://192.168.1.106/privacy
docker build -t verschueren-ai:test . && docker run --rm -p 8099:80 verschueren-ai:test
```

## Later: zone naar Cloudflare

Alleen nodig als je de site naar de tunnel wil verhuizen. `docs/dns-import-verschueren.ai.txt` bevat de
volledige live-inventaris van 2026-10-25 in BIND-formaat. Volgorde: zone-export maken → records overnemen
(mail-records op **DNS-only**) → `dig`-vergelijking → dán de nameservers omzetten → mailvalidatie
(`spf=pass`, `dkim=pass`) → A-records naar de tunnel.

## Google Cloud Branding-velden

| Veld | Waarde |
|---|---|
| App name | `Verschueren AI` (geen logo) |
| User support email | `tvschuer@gmail.com` |
| Application home page | `https://verschueren.ai` |
| Application privacy policy link | `https://verschueren.ai/privacy/` |
| Application terms of service link | `https://verschueren.ai/terms/` |
| Authorised domains | `verschueren.ai` |
| Developer contact | `tom@quadreg.be` |

Gebruik de URL's **met** trailing slash: dat is de canonieke vorm die Pages serveert, zonder omweg via een
redirect.

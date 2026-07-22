# 08 – Authentik- und Nextcloud-Integration

Stand: 22.07.2026

## Zielbild

Authentik ist die zentrale Quelle für reguläre Benutzer, Passwörter, Gruppen und
MFA. Nextcloud übernimmt Dateien, Team Folders, Talk, Kalender, Collectives und
weitere Kollaborationsfunktionen.

Reguläre Konten werden ausschließlich in Authentik angelegt. Nextcloud erzeugt das
zugehörige Konto beim ersten erfolgreichen OIDC-Login automatisch. Gruppen werden
als anwendungsspezifische Authentik-Entitlements übertragen und steuern die
Berechtigungen in Nextcloud.

Getrennte lokale Rückfallzugänge bleiben erhalten:

- `akadmin` ist der Authentik-Break-Glass-Account und erhält keine
  Nextcloud-Entitlements.
- `nextcloudadmin` ist ein lokaler Nextcloud-Break-Glass-Account mit
  Datenbank-Backend.
- Persönliche Administratorkonten werden nicht als Break-Glass-Konten verwendet.

Produktive Client-Secrets, Passwörter, MFA-Schlüssel, Wiederherstellungscodes und
`.env`-Inhalte sind nicht Bestandteil des Repositories.

## Getesteter Stand

Die Integration wurde mit folgenden Versionen geprüft:

- Authentik `2026.5.4`
- Nextcloud `34.0.1`
- Nextcloud-App `user_oidc 8.10.1`

Öffentliche Endpunkte:

| Dienst | URL |
|---|---|
| Authentik | `https://auth.zircula.org` |
| Nextcloud | `https://cloud.zircula.org` |
| OIDC Discovery | `https://auth.zircula.org/application/o/nextcloud/.well-known/openid-configuration` |
| Nextcloud OIDC Callback | `https://cloud.zircula.org/apps/user_oidc/code` |

Die serverseitige Nextcloud-Verschlüsselung mit benutzerbezogenen Schlüsseln ist
deaktiviert. Falls sie später eingeführt wird, muss OIDC neu bewertet werden, weil
Nextcloud dabei das Klartextpasswort des Benutzers nicht erhält.

## Identitäten und Benutzer-IDs

Jeder reguläre Benutzer erhält in Authentik das Attribut
`nextcloud_user_id`. Der Wert ist die dauerhaft verwendete, lesbare
Nextcloud-Benutzer-ID:

```yaml
nextcloud_user_id: timohecken
```

Der Wert wird nach der ersten Nextcloud-Anmeldung nicht umbenannt. Änderungen von
Benutzernamen oder E-Mail-Adressen in Authentik dürfen die
`nextcloud_user_id` nicht verändern.

Ohne dieses Attribut verwendet die aktuelle Scope-Zuordnung ersatzweise die
Authentik-UUID. Das verhindert Kollisionen, erzeugt aber keine gut lesbare
Nextcloud-ID. Das Attribut gehört deshalb verbindlich zum Onboarding.

## Authentik-Konfiguration

### Scope Mapping

Unter **Customization → Property mappings** existiert ein Scope Mapping:

| Einstellung | Wert |
|---|---|
| Name | `Nextcloud Profile` |
| Scope name | `nextcloud` |

Expression:

```python
groups = [
    entitlement.name
    for entitlement in request.user.app_entitlements(provider.application)
]

quota = (
    request.user.app_entitlements_attributes(provider.application).get("nextcloud_quota")
    or request.user.group_attributes().get("nextcloud_quota")
)

return {
    "name": request.user.name,
    "groups": groups,
    "quota": quota,
    "user_id": request.user.attributes.get(
        "nextcloud_user_id",
        str(request.user.uuid),
    ),
}
```

Es werden nur Entitlements der Nextcloud-Anwendung übertragen. Interne Gruppen wie
`authentik Admins` oder `admin` gelangen dadurch nicht automatisch in
Nextcloud.

### OAuth2/OIDC-Provider

Die Anwendung und der Provider heißen `Nextcloud`; der Application-Slug ist
`nextcloud`.

Wesentliche Einstellungen:

| Einstellung | Wert |
|---|---|
| Client type | Confidential |
| Grant type | Authorization Code |
| Authorization flow | `default-provider-authorization-implicit-consent` |
| Authorization redirect | `https://cloud.zircula.org/apps/user_oidc/code` |
| Post-logout redirect | `https://cloud.zircula.org` |
| Signing key | Authentik Self-signed Certificate |
| Subject mode | Based on the User's UUID |
| Include claims in ID token | aktiviert |
| Issuer mode | eigener Issuer je Application-Slug |
| Scopes | `openid`, `email`, `profile`, `nextcloud` |
| Encryption key | nicht gesetzt |

Client-ID und Client-Secret werden getrennt von Git verwaltet. Ein bei Screenshots
oder Tests verwendeter Wert wird vor dem produktiven Einsatz neu erzeugt.

### Entitlements und Gruppen

Die Entitlement-Namen entsprechen exakt den Nextcloud-Gruppennamen:

| Nextcloud-Entitlement | Gebundene Authentik-Gruppe |
|---|---|
| `admin` | `Nextcloud Admins` |
| `Zircula e.V. Vorstand` | `Zircula e.V. Vorstand` |
| `Zircula e.V. Angestellte` | `Zircula e.V. Angestellte` |
| `Zircula e.V. Mitglieder:innen` | `Zircula e.V. Mitglieder:innen` |
| `Werk e.V. Vorstand` | `Werk e.V. Vorstand` |
| `Werk e.V. Mitglieder:innen` | `Werk e.V. Mitglieder:innen` |
| `Objekt 218 GmbH` | `Objekt 218 GmbH` |

Für WERK existiert bewusst keine Gruppe `Werk e.V. Angestellte`.

Das Entitlement `admin` wird ausschließlich an `Nextcloud Admins` gebunden.
Die Authentik-Gruppen `admin` und `authentik Admins` dürfen keine direkte
Nextcloud-Administratorzuweisung auslösen.

### Back-Channel-Logout

Der Authentik-Provider verwendet:

| Einstellung | Wert |
|---|---|
| Logout URI | `https://cloud.zircula.org/apps/user_oidc/backchannel-logout/authentik` |
| Logout Method | Back-channel |

Beim Abmelden aus Authentik wird die zugehörige Nextcloud-Browsersitzung
serverseitig beendet. Die Invalidierung kann einige Sekunden verzögert sichtbar
werden.

## Nextcloud-Konfiguration

Die App `user_oidc` ist aktiviert. Der administrative Provider-Identifier lautet
`authentik`.

Die produktive Einrichtung erfolgt über `occ`, ohne das Client-Secret in der
Shell-Historie oder einer versionierten Datei abzulegen:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

read -rp "Authentik Client ID: " OIDC_CLIENT_ID
read -rsp "Authentik Client Secret: " OIDC_CLIENT_SECRET
printf '\n'
export OIDC_CLIENT_SECRET

docker compose exec \
  -e OIDC_CLIENT_SECRET \
  --user www-data nextcloud \
  php occ user_oidc:provider authentik \
    --clientid="$OIDC_CLIENT_ID" \
    --clientsecret-env=OIDC_CLIENT_SECRET \
    --discoveryuri='https://auth.zircula.org/application/o/nextcloud/.well-known/openid-configuration' \
    --postlogouturi='https://cloud.zircula.org' \
    --scope='openid email profile nextcloud' \
    --unique-uid=0 \
    --check-bearer=0 \
    --bearer-provisioning=0 \
    --mapping-uid='user_id' \
    --mapping-display-name='name' \
    --mapping-email='email' \
    --mapping-quota='quota' \
    --mapping-groups='groups' \
    --group-provisioning=1 \
    --group-whitelist-regex='^(admin|Objekt 218 GmbH|Werk e\.V\. (Vorstand|Mitglieder:innen)|Zircula e\.V\. (Vorstand|Angestellte|Mitglieder:innen))$' \
    --group-restrict-login-to-whitelist=1 \
    --resolve-nested-claims=0 \
    --no-interaction

RESULT=$?
unset OIDC_CLIENT_SECRET OIDC_CLIENT_ID
test "$RESULT" -eq 0
```

`unique-uid=0` ist erforderlich, damit die explizite `user_id` verwendet und
das Entitlement `admin` korrekt verarbeitet wird.

Die Gruppen-Whitelist verhindert die Provisionierung nicht freigegebener Gruppen.
`group-restrict-login-to-whitelist=1` verweigert Benutzern ohne mindestens ein
freigegebenes Entitlement den Nextcloud-Zugang.

`allow_multiple_user_backends` bleibt aktiviert. Dadurch funktioniert der lokale
Break-Glass-Login weiterhin unter:

```text
https://cloud.zircula.org/login?direct=1
```

Eine automatische Weiterleitung aller Loginversuche zu Authentik wird erst nach
vollständigem Rollout und erneutem Break-Glass-Test bewertet.

## MFA

MFA wird in Authentik durch registrierte Geräte und die
`default-authentication-mfa-validation`-Stage umgesetzt.

Aktueller Stand:

- WebAuthn wurde für das persönliche Administratorkonto `timohecken` registriert
  und erfolgreich beim Login getestet.
- Die MFA-Stage ist mit Policy Engine Mode `Any` an die Gruppe
  `Nextcloud Admins` gebunden.
- `Not configured action` ist `Configure`; Mitglieder ohne geeignetes Gerät
  müssen beim Login eines einrichten.
- Eine MFA-Pflicht für Vorstände, Angestellte und Mitglieder der Objekt 218 GmbH
  ist organisatorisch noch nicht beschlossen.
- Der Authentik-Break-Glass-Account und der lokale Nextcloud-Break-Glass-Account
  benötigen vor dem Go-live jeweils ein eigenes MFA- und Recovery-Verfahren.

Mögliche weitere MFA-pflichtige Gruppen sind:

- `Zircula e.V. Vorstand`
- `Zircula e.V. Angestellte`
- `Werk e.V. Vorstand`
- `Objekt 218 GmbH`

Reine Vereinsmitglieder können nach aktueller Diskussion von der Pflicht
ausgenommen bleiben. Jede Änderung dieser Liste ist eine dokumentierte
Governance-Entscheidung.

MFA in Authentik schützt nur OIDC-Anmeldungen. Der lokale `nextcloudadmin`
umgeht Authentik bewusst und benötigt deshalb Nextcloud-eigenes TOTP sowie
Nextcloud-Wiederherstellungscodes.

## Onboarding

Für einen neuen regulären Benutzer:

1. Benutzer ausschließlich in Authentik erstellen.
2. eindeutigen Benutzernamen, Anzeigenamen und E-Mail-Adresse setzen
3. `nextcloud_user_id` als dauerhaftes Attribut setzen
4. die organisatorisch erforderlichen Gruppen zuweisen
5. bei administrativem Nextcloud-Zugriff zusätzlich `Nextcloud Admins` zuweisen
6. bei MFA-pflichtiger Gruppe die Ersteinrichtung im Authentik-Flow abschließen
7. den ersten Login über **Login with authentik** durchführen
8. Benutzer-ID, E-Mail, Backend und Gruppen mit `occ user:info` kontrollieren

Prüfung:

```bash
cd /opt/zircula/git/infrastructure/docker/nextcloud

docker compose exec --user www-data nextcloud \
  php occ user:info <nextcloud_user_id>
```

Vor dem ersten Login existiert der Benutzer noch nicht in Nextcloud. Individuelle
Freigaben oder Einladungen sind deshalb erst danach möglich. Eine eventuell später
benötigte Vorab-Provisionierung erfolgt ausschließlich über die unterstützte
`user_oidc`-API und nicht durch ein lokales Nextcloud-Passwortkonto.

## Gruppenänderungen

Authentik ist die Quelle der Gruppenzugehörigkeit. Änderungen werden beim nächsten
OIDC-Login in Nextcloud übernommen.

Geprüft wurden:

- Entzug und erneute Zuweisung einer Organisationsgruppe
- Entzug und erneute Zuweisung von `Nextcloud Admins`
- Entfernung des Nextcloud-Entitlements `admin` ohne Verlust der übrigen Gruppen
- Wiederherstellung der Administratorrechte nach erneuter Gruppenzuweisung

Team Folders und weitere gruppenbasierte Berechtigungen verwenden ausschließlich
die in der Entitlement-Tabelle aufgeführten Nextcloud-Gruppen.

## Offboarding

OIDC ersetzt kein vollständiges Deprovisionierungsprotokoll. Das Löschen oder
Deaktivieren eines Authentik-Benutzers löscht dessen Nextcloud-Daten nicht
automatisch. Bereits bestehende Nextcloud-Sitzungen, App-Passwörter und Clients
müssen ausdrücklich berücksichtigt werden.

Mindestens erforderlich:

1. Benutzer in Authentik deaktivieren.
2. alle Anwendungs- und Organisationsgruppen entziehen
3. aktive Authentik-Sitzungen und OAuth-Token widerrufen
4. aktive Nextcloud-Sitzungen und App-Passwörter prüfen und widerrufen
5. Nextcloud-Konto je nach Aufbewahrungsentscheidung deaktivieren oder löschen
6. Eigentum, Freigaben, Kalender, Talk-Räume und sonstige Anwendungsdaten prüfen
7. Abschluss und verantwortliche Person dokumentieren

Das Offboarding wird vor dem Go-live mit einem entbehrlichen Testkonto vollständig
durchgespielt.

## Break-Glass

### Nextcloud

Der lokale Benutzer `nextcloudadmin` bleibt im Datenbank-Backend erhalten. Vor
jeder Änderung an OIDC, MFA oder Login-Weiterleitungen wird in einem frischen
privaten Browserfenster geprüft:

```text
https://cloud.zircula.org/login?direct=1
```

Das Konto wird nicht für den täglichen Betrieb verwendet. Zugangsdaten,
TOTP-Seed und Wiederherstellungscodes werden getrennt und verschlüsselt verwahrt.

### Authentik

`akadmin` bleibt ein lokaler Authentik-Break-Glass-Account. Das Konto erhält
keine Nextcloud-Entitlements. Ein Loginversuch ohne freigegebene Gruppe wurde von
Nextcloud wie erwartet abgelehnt.

Der Account wird nicht für tägliche Administration verwendet. MFA und
Wiederherstellungsweg sind vor dem Go-live zu vervollständigen und anschließend
regelmäßig zu testen.

## Validierung vom 22.07.2026

Erfolgreich geprüft:

- OIDC Discovery, Authorization-, Token- und JWKS-Endpunkte erreichbar
- lokaler Nextcloud-Break-Glass-Login in frischem privaten Browserfenster
- OIDC-Login über Authentik
- automatische Neuanlage von `timohecken` ohne lokales Vorabkonto
- Übernahme von Benutzer-ID, Anzeigename und E-Mail-Adresse
- Backend `user_oidc`
- Provisionierung der drei Zircula-Gruppen und von `admin`
- Entzug und Wiedervergabe einer Organisationsgruppe
- Entzug und Wiedervergabe der Nextcloud-Administratorrechte
- Abweisung eines Authentik-Benutzers ohne freigegebene Entitlements
- Back-Channel-Logout von Authentik nach Nextcloud
- WebAuthn-Login für `timohecken`
- Löschung der entbehrlichen lokalen Testkonten

Zum Prüfzeitpunkt existierten regulär nur:

- `nextcloudadmin` mit lokalem Datenbank-Backend
- `timohecken` mit `user_oidc`-Backend

## Offene Go-live-Gates

- MFA und Recovery für beide Break-Glass-Konten abschließen
- organisatorische MFA-Pflicht für weitere Gruppen entscheiden
- vollständiges Offboarding mit einem Testkonto prüfen
- Nextcloud Desktop-/Mobile-Client und WebDAV/App-Passwort testen
- verschlüsseltes externes Backup und Restore-Test abschließen
- Authentik-Blueprint und wiederholbares Nextcloud-Konfigurationsverfahren gegen
  eine isolierte Testinstanz prüfen
- regelmäßige Kontrolle der Entitlement-, Gruppen- und Admin-Bindings festlegen

## Referenzen

- [Authentik: Nextcloud-Integration](https://integrations.goauthentik.io/chat-communication-collaboration/nextcloud/)
- [Nextcloud: OpenID Connect user backend](https://github.com/nextcloud/user_oidc)
- [Authentik: Authenticator Validation Stage](https://docs.goauthentik.io/add-secure-apps/flows-stages/stages/authenticator_validate/)

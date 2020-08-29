# 1. Descrizione
Questo setup consente di installare, in un ambiente demo, un piccolo cluster odoo, versione 12, con le seguenti caratteristiche:

- Localizzazione italiana
- Load balancer nginx (eventualmente si può aggiungere certbot per l'ssl)
- Filestore condiviso (si tratta di un semplice volume, non idoneo a cluster multi nodo)
- Sessioni redis (attraverso l'utilizzo di un apposito modulo)

## 1.1 Informazioni:

- ho esposto entrambe le porte dei due servizi odoo (la 8069 della prima istanza e la 8169 della seconda istanza) per 
consentire una verifica, ma non sarebbe necessario dato che il cluster dovrà poi essere accessibile solo attraverso la 
porta del balance nginx (8080).
- il setup è assolutamente insicuro e non adatto ad un uso di produzione (password semplici, assenza di ridondanza, solo 
http).

## 1.2 Dettagli utili:
- Il dockerfile della immagine odoo è stato costruito partendo dall [Dockerfile ufficiale](https://hub.docker.com/_/odoo)
e inserendo delle personalizzazioni.
- E' possibile cambiare la versione scaricata intervenendo sugli ARGS del ```docker-compose.yml```:
    - `ODOO_RELEASE`
    - `ODOO_SHA`
- Per installare una versione diversa dalla 12 occorre creare un nuovo Dockerfile per la 10 (gli utenti più smaliziati
sapranno sicuramente come fare) e poi sistemare i moduli da scaricare nei files extra-repositories-list.txt e extra-modules-list.txt.
I moduli disponibili (ed i relativi repositories) possono cambiare da versione a versione e non è detto che un modulo 
della versione 12.0 sia disponibile per la 10.0 o viceversa. 
- L'arg ```ODOO_VERSION``` viene propagato allo script extra-modules.sh per spostare i repository dei moduli sulla specifica
versione odoo.
- I moduli installabili attraverso questo repository rappresentano una mia personale selezione (anche basandomi su quanto
trovato attraverso i files di Franco ;)). Potete modificare la lista a vostro piacimento! 
- Per abilitare la cache redis è indispensabile che nel file odoo.conf venga attivato il modulo `smile_redis_session_store` 
prima del modulo `web`, usando il parametro `server_wide_modules`

## 1.3 Credits
- **Franco Tampieri e gli altri membri del gruppo Odoo ITA** - per aver fornito alcune dritte utilissime sulla 
installazione dei moduli nella immagine docker di odoo.

# 2. Utilizzo

## 2.1. Avviamo il database:

```bash
docker-compose up -d odoo-db
```

## 2.2. Costuriamo l'immagine di odoo:

```bash
docker-compose build odoo
```

## 2.3. Procediamo alla inizializzazione del db di odoo
Per inizializzare il database, abbiamo necessità di entrare in shell, per eseguire l'inizializzazione da riga di comando:

```bash
docker-compose run odoo odoo -c /etc/odoo/odoo.conf --without-demo=all --db_host=odoo-db --db_user=odoo --db_password=odoo --database=odoo --no-http --stop-after-init -i smile_redis_session_store,web,base
```

Per installare i moduli della localizzazione italiana:

```bash
docker-compose run odoo odoo -c /etc/odoo/odoo.conf --without-demo=all --db_host=odoo-db --db_user=odoo --db_password=odoo --database=odoo --no-http --stop-after-init -i l10n_it_abicab,l10n_it_account,l10n_it_account_tax_kind,l10n_it_ateco,l10n_it_causali_pagamento,l10n_it_central_journal,l10n_it_codici_carica,l10n_it_receipts,l10n_it_compensation,l10n_it_esigibilita_iva,l10n_it_fatturapa,l10n_it_fatturapa_in,l10n_it_fatturapa_in_purchase,l10n_it_fatturapa_out,l10n_it_fatturapa_pec,l10n_it_fiscal_document_type,l10n_it_fiscal_payment_term,l10n_it_fiscalcode,l10n_it_ipa,l10n_it_pec,l10n_it_rea,l10n_it_reverse_charge,l10n_it_ricevute_bancarie,l10n_it_sdi_channel,l10n_it_split_payment,l10n_it_vat_registries,l10n_it_vat_registries_cash_basis,l10n_it_withholding_tax,l10n_it_withholding_tax_causali,l10n_it_withholding_tax_payment
```


(**sconsigliato**) Potremmo anche installare - in un sol colpo - tutti gli altri moduli previsti dal nostro setup, inseriti nel file `odoo-ita/12.0/extra-modules-list.txt` attraverso un unico comando:
```bash
docker-compose run odoo odoo -c /etc/odoo/odoo.conf --without-demo=all --db_host=odoo-db --db_user=odoo --db_password=odoo --database=odoo --no-http --stop-after-init -i `cat odoo-ita/12.0/scripts/extra-modules-list.txt | paste -sd "," -`
```

__Il consiglio è quello di installare, comunque solo i moduli a noi necessari.__


## 2.4. Avvio di odoo
A questo punto possiamo avviare odoo:

```bash
docker-compose up -d odoo
```

## 2.5. Verifica funzionamento redis
Prima di effettuare la login su odoo, possiamo verificare che la cache redis sia usata per le sessioni:

```bash
docker-compose exec redis redis-cli -n 1 monitor
```

Questo comando avvia il client redis sul db usato per memorizzare i dati delle sessioni. Facendo la login su odoo, 
dovremmo vedere passare dei comandi GET e SETEX.

Premere CTRL+C per uscire

## 2.6. Accesso web alla istanza di odoo
Possiamo verificare che odoo stia girando, accedendo alla URL: http://localhost:8069. Se tutto è filato liscio, dovremmo 
vedere il modulo di login. Effettuate l'accesso usando le credenziali di default:

```
User: admin
Password: admin
```


## 2.7. Avvio di una seconda istanza di odoo
Nel docker-compose.yml è presente una seconda istanza di odoo. Questa seconda istanza si connetterà allo stesso database
e alla stessa cache redis della prima istanza, ma andrà in ascolto sulla porta 8169.
 
A questo punto la situazione dei container avviati dovrebbe essere simile a questa:

```bash
$ docker-compose ps
                     Name                                   Command               State                       Ports                     
----------------------------------------------------------------------------------------------------------------------------------------
odoo-ita-docker-cluster_mailhog_1_46381b577855   MailHog                          Up      0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
odoo-ita-docker-cluster_odoo-db_1_9c6e0eee4729   docker-entrypoint.sh postgres    Up      0.0.0.0:25432->5432/tcp                       
odoo-ita-docker-cluster_odoo2_1_46e9502d0fa0     /entrypoint.sh odoo              Up      0.0.0.0:8169->8069/tcp, 8071/tcp, 8072/tcp    
odoo-ita-docker-cluster_odoo_1_b4f7608c8661      /entrypoint.sh odoo              Up      0.0.0.0:8069->8069/tcp, 8071/tcp, 8072/tcp    
odoo-ita-docker-cluster_redis_1_cda42bbb8712     docker-entrypoint.sh redis ...   Up      0.0.0.0:26379->6379/tcp        
```

Notate le due istanze di odoo (sulla 8069 e la 8169). Proviamo ad accedere alla sceconda istanza: http://localhost:8169.
Se avete effettuato l'accesso nella prima istanza, usando la seconda vi troverete già loggati! 

Effettuando il logout nella prima istanza, verrete de-loggati anche nella seconda istanza :)

## 2.8. Balancer
E' arrivato il momento di avviare il balancer:
```bash
docker-compose up -d nginx
```

Se tutto è filato liscio, dovreste poter accedere attraverso l'url: http://localhost:8080/web/login.


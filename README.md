# Payment Reconciliation

1. Set the required environment variables:

```shell
SLACK_CHANNEL_ID, SLACK_API_KEY, RETRIEVAL_SERVICE_TOKEN
```

The `RETRIEVAL_SERVICE_TOKEN` must be the `id_token` obtained from the `fractl-met` login API call.

If you want to test against Odoo, follow [this link](https://hub.docker.com/_/odoo) for instructions on running Odoo locally.
Also export these environment variables:

```shell
ODOO_USER, ODOO_PASSWORD
```

Alternatively, you can create these integration configurations:

```clojure
;; config.edn
{:configurations
 {"slack"
  {"pr-slack-connection"
   {:Type :custom
    :Parameter {:apikey #$ SLACK_API_KEY :channelid #$ SLACK_CHANNEL_ID}}}
  "odoo"
  {"pr-odoo-connection"
   {:Type :custom
    :Parameter {:apiurl #$ ODOO_HOST
                :db #$ ODOO_DB
                :username #$ ODOO_USER
                :password #$ ODOO_PASSWORD}}}}}
```

2. Host payment receipts for invoice extraction:

```shell
$ cd ./sample
$ python3 -m http.server
$ ngrok http http://localhost:8000
```

3. Start the app:

```shell
$ agent run -c config.edn
```

4. If testing with local database, initialize the sample db:

```shell
POST api/PaymentReconciliation.Schema/InitSampleData

{"PaymentReconciliation.Schema/InitSampleData": {}}
```

If testing with Odoo, create a couple of orders and invoices in Odoo. Create a payment_receipt.pdf for the invoices
and copy that file to the ./sample folder.

5. Reconcile the receipt:

```shell
POST api/PaymentReconciliation.Core/PaymentReconciliation

{"PaymentReconciliation.Core/PaymentReconciliation":
  {"UserInstruction": "https://xxxxxxxxx.ngrok-free.app/payment_receipt.pdf"}}
```

For any invoice that cannot be reconciled, a message will be posted to the slack-channel,
where you can reconcile the invoice by clicking on a link. You may call the `GET api/PaymentReconciliation.Schema/Invoice/<invoice-no>`
endpoint to check the reconciliation-status of the invoices before and after clicking the link.

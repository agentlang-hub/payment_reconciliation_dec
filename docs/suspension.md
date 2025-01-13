### Restarting the suspension via API calls

Alternatively, you may use the suspension-id printed to the console to restart the dataflow and let it either mark the invoice as reconciled or not.
You can reconcile the first invoice as,

```shell
POST api/Agentlang.Kernel.Eval/RestartSuspension

{"Agentlang.Kernel.Eval/RestartSuspension":
  {"Id": "3761e0ae-bdff-4df0-a13a-80d711bfe1c6",
   "Value": {"Reconcile": true, "InvoiceNo": 1}}}
```

To confirm that both invoices are now reconciled:

```shell
GET api/ErpSuite.Core/Invoice
```

The suspended dataflow may also be restarted by the following `GET` request:

```
GET api/Agentlang.Kernel.Eval/Continue/3761e0ae-bdff-4df0-a13a-80d711bfe1c6$Reconcile:true,InvoiceNo:1
```

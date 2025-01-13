{:name :PaymentReconciliation
 :agentlang-version "0.6.2-alpha"
 ;; :dependencies [[:fs "resolvers/slack"]
 ;;                [:fs "resolvers/odoo"]]
 :dependencies [[:git "https://github.com/agentlang-hub/slack.git#integrations"]
                ;;[:git "https://github.com/agentlang-hub/odoo.git"]
                ]
 :components [:PaymentReconciliation.Receipt
              :PaymentReconciliation.Schema
              :PaymentReconciliation.Core]}

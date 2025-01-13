{:name :PaymentReconciliation
 :agentlang-version "current"
 ;; :dependencies [[:fs "resolvers/slack"]
 ;;                [:fs "resolvers/odoo"]]
 :dependencies [[:git "https://github.com/agentlang-hub/slack.git#integrations"]
                ;;[:git "https://github.com/agentlang-hub/odoo.git"]
                ]
 :components [:PaymentReconciliation.Receipt
              :PaymentReconciliation.Schema
              :PaymentReconciliation.Core]}
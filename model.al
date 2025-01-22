{:name :PaymentReconciliation
 :agentlang-version "current"
 :git-hub-url "https://github.com/agentlang-hub/payment_reconciliation_deploy",
 :github-org "agentlang-hub",
 :dependencies [[:git "https://github.com/agentlang-hub/slack.git" {:model :Slack}]
                ;;[:git "https://github.com/agentlang-hub/odoo.git"]
                ]
 :components [:PaymentReconciliation.Receipt
              :PaymentReconciliation.Schema
              :PaymentReconciliation.Core]}

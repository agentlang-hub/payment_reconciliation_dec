(component
 :PaymentReconciliation.Schema
 {:refer [:Slack.Core
          ;;:Odoo.Core
          ]
  :clj-import (quote [(:require [agentlang.datafmt.json :as json]
                                [agentlang.util :as u]
                                [agentlang.component :as cn]
                                [agentlang.evaluator :as e]
                                [agentlang.evaluator.suspend :as sp])])})

(entity
 :Order
 {:No {:type :Int :guid true}
  :Name {:type :String :unique true :default u/uuid-string}
  :Date :String
  :CustomerNo :Int
  :TotalPrice :Decimal
  :SystemData {:type :Any :optional true}})

(dataflow
 :LookupOrderByName
 {:Order {:Name? :LookupOrderByName.Name}})

(entity
 :Invoice
 {:No {:type :Int :guid true}
  :Name {:type :String :unique true}
  :OrderNo :Int
  :Date :String
  :DueDate {:type :String :optional true}
  :Reconciled {:type :Boolean :default false}})

(event :MarkInvoiceAsReconciled {:InvoiceNo :Int})

(dataflow
 :MarkInvoiceAsReconciled
 {:Invoice {:No? :MarkInvoiceAsReconciled.InvoiceNo
            :Reconciled true}})

(record
 :Payment
 {:Id :Identity
  :InvoiceNo :String
  :Date :String
  :Amount :Decimal})

(event
 :ReportPaymentMismatch
 {:OrderNo :Int
  :InvoiceNo :Int
  :OrderTotalPrice :Decimal
  :PaymentAmount :Decimal})

(entity
 :PaymentMismatch
 {:OrderNo :Int
  :InvoiceNo :Int
  :OrderTotalPrice :Decimal
  :PaymentAmount :Decimal
  :PaymentDifference {:type :Decimal
                      :expr (quote (- :OrderTotalPrice :PaymentAmount))}
  :SuspensionId {:type :String :optional true}
  :Reconcile {:type :Boolean :default false}})

(defn make-restart-url [inst reconcile?]
  (str (or (System/getenv "FRACTL_API_URL") "http://localhost:8080") "/api/Agentlang.Kernel.Eval/Continue/"
       (:SuspensionId inst)
       "$Reconcile:" reconcile? ",InvoiceNo:" (:InvoiceNo inst)))

(defn payment-mismatch-str [inst]
  (str "Payment mismatch detected. Order No: " (:OrderNo inst) "\n"
       "Invoice No: " (:InvoiceNo inst) "\n"
       "Order Total Price: " (:OrderTotalPrice inst) "\n"
       "Payment Amount: " (:PaymentAmount inst) "\n"))

(resolver
 :PaymentMismatchResolver
 {:with-methods
  {:create (fn [inst]
             (let [new-inst (assoc inst :SuspensionId (sp/get-suspension-id))]
               (e/evaluate-pattern {:Slack.Core/Chat {:text (str (payment-mismatch-str new-inst)
                                                                 "Reconcile? <" (make-restart-url new-inst true) "|yes>"
                                                                 " <" (make-restart-url new-inst false) "|no>")}})
               (println "dataflow suspended for manual reconciliation:")
               (clojure.pprint/pprint new-inst)
               (e/as-suspended new-inst)))}
  :paths [:PaymentReconciliation.Schema/PaymentMismatch]})

(dataflow
 :ReportPaymentMismatch
 {:PaymentMismatch
  {:OrderNo :ReportPaymentMismatch.OrderNo
   :InvoiceNo :ReportPaymentMismatch.InvoiceNo
   :OrderTotalPrice :ReportPaymentMismatch.OrderTotalPrice
   :PaymentAmount :ReportPaymentMismatch.PaymentAmount}
  :as :pm}
 [:match :pm.Reconcile
  true {:MarkInvoiceAsReconciled {:InvoiceNo :pm.InvoiceNo}}
  false :pm])

(event
 :LookupRelevantPaymentInformation
 {:Payments {:listof :Payment}})

(record
 :PaymentInformation
 {:PaymentId :UUID
  :PaymentDate :String
  :PaymentAmount :Decimal
  :OrderNo :Int
  :InvoiceNo :Int
  :OrderAmount :Decimal})

(defn payment-info-as-json [instances]
  (json/encode (mapv cn/instance-attributes instances)))

(dataflow
 :LookupRelevantPaymentInformation
 [:for-each :LookupRelevantPaymentInformation.Payments
  {:Invoice {:Name? :%.InvoiceNo} :as [:invoice]}
  {:Order {:No? :invoice.OrderNo} :as [:order]}
  {:PaymentInformation
   {:PaymentId :%.Id
    :PaymentDate :%.Date
    :PaymentAmount :%.Amount
    :OrderNo :order.No
    :InvoiceNo :invoice.No
    :OrderAmount :order.TotalPrice}}])

(event :PaymentsInfoAsJson {:PaymentsInfo :Any})

(dataflow
 :PaymentsInfoAsJson
 [:eval (quote (paymentreconciliation.schema/payment-info-as-json :PaymentsInfoAsJson.PaymentsInfo))])

(defn- normalize-order [obj]
  (when (seq obj)
    (cn/make-instance
     :PaymentReconciliation.Schema/Order
     {:No (:id obj)
      :Name (:name obj)
      :Date (:create_date obj)
      :CustomerNo (first (:partner_id obj))
      :TotalPrice (:amount_total obj)
      :SystemData {:invoice-ids (:invoice_ids obj)}})))

(defn- normalize-invoice [obj order]
  (when (seq obj)
    (let [paid? (= "paid" (:payment_state obj))]
      (cn/make-instance
       :PaymentReconciliation.Schema/Invoice
       {:No (:id obj)
        :Name (:name obj)
        :OrderNo (:id order)
        :Reconciled paid?
        :Date (:create_date obj)
        :DueDate (when-not paid? (:next_payment_date obj))}))))

;; (odoo.core/register-resolver
;;  [:PaymentReconciliation.Schema/Order
;;   :PaymentReconciliation.Schema/Invoice]
;;  {:Order normalize-order :Invoice normalize-invoice})

(dataflow
 :InitSampleData
 [:delete :Order :*]
 [:delete :Invoice :*]
 {:Order
  {:No 1 :Date "01-Dec-2024" :CustomerNo 101 :TotalPrice 17.3}}
 {:Order
  {:No 2 :Date "02-Dec-2024" :CustomerNo 101 :TotalPrice 340.0}}
 {:Invoice {:No 1 :Name "1" :Date "10-Dec-2024" :OrderNo 1 :DueDate "01-Jan-2025"}}
 {:Invoice {:No 2 :Name "2" :Date "10-Dec-2024" :OrderNo 2 :DueDate "01-Jan-2025"}})

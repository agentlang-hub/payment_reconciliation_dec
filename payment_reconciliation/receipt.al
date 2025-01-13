(component
 :PaymentReconciliation.Receipt
 {:clj-import (quote [(:require [clojure.string :as s]
                                [agentlang.connections.client :as cc]
                                [agentlang.util.http :as http])])})

(defn get-server-connection []
  {:Parameter
   {:token (or (cc/get-auth-token)
               (System/getenv "RETRIEVAL_SERVICE_TOKEN"))}})

(defn- tables-to-csv [tables]
  (let [headers (keys (first tables))
        rows (mapv (fn [obj] (mapv (fn [h] (get obj h)) headers)) tables)]
    (str (s/join "," (mapv name headers)) "\n"
         (s/join "\n" (mapv (fn [r] (s/join "," r)) rows)))))

(defn fetch-invoices-from-url [url]
  (let [token (:token (cc/connection-parameter (get-server-connection)))]
    (when-let [result (http/POST
                       "http://retrieval-service.fractl.io/extract"
                       {:headers {"token" token}}
                       {:document_url url} :json)]
      (when-let [tables (get-in result [:tables :tables])]
        (tables-to-csv (apply concat tables))))))

(event :FetchInvoicesAsCsv {:Url :String})

(dataflow
 :FetchInvoicesAsCsv
 [:eval (quote (paymentreconciliation.receipt/fetch-invoices-from-url :FetchInvoicesAsCsv.Url))])

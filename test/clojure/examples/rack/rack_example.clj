(ns examples.rack.rack-example
  (:require [puppetlabs.trapperkeeper.core :refer [defservice]]
            [clojure.tools.logging :as log]))

(defservice razor
  "Razor Sinatra service"
  [[:RackWrapperService add-rack-handler]]
  (init [this context]
        (log/info "Razor webservice starting up!")
        (add-rack-handler "." "/")
        context)

  (stop [this context]
        (log/info "Razor webservice shutting down!")
        context))
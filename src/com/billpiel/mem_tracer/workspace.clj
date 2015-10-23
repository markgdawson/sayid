(ns com.billpiel.mem-tracer.workspace
  (:require [com.billpiel.mem-tracer.trace :as trace]))

(defn default-workspace
  [& {:as m}]
  (trace/mk-entry :workspace? true :merge-map m))

(defn init-workspace!
  [ws]
  (if (= nil @ws)
    (compare-and-set! ws nil (default-workspace))))

(defn reset-workspace!
  [ws]
  (reset! ws nil))

(defn clear-log!
  [ws]
  (swap! ws assoc :children (atom [])))

(defn add-trace-ns!
  [ws ns-sym]
  (init-workspace! ws)
  (swap! ws #(update-in % [:traced] conj [:ns ns-sym]))
  (trace/trace-ns* ns-sym @ws))

(defn remove-trace-ns!
  "Untrace all fns in the given name space."
  [ws ns-sym]
  (init-workspace! ws)
  (swap! ws update-in [:traced] disj [:ns ns-sym])
  (trace/untrace-ns* ns-sym))

(defn enable-all-traces!
  [ws]
  (let [w @ws]
    (doseq [[type sym] (:traced w)]
      (trace/trace* type sym w))))

(defn disable-all-traces!
  [ws]
  (doseq [t (:traced @ws)]
    (apply trace/untrace* t)))

(defn remove-all-traces!
  [ws]
  (disable-all-traces! ws)
  (swap! ws assoc :traced #{}))

(defn deref-workspace!
  [ws]
  (clojure.walk/prewalk #(if (-> %
                                 meta
                                 ::trace/entry)
                           (update-in % [:children] deref)
                           %)
                        @ws))
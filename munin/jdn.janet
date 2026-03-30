(defn decode
  "Decode a string or buffer returning
   a single janet value. Trailing values
   are discarded. Panics on parse error."
  [b]
  (def p (parser/new))
  (parser/consume p b)
  (parser/eof p)
  (when (= :error (parser/status p))
    (error (parser/error p)))
  (unless (parser/has-more p)
    (error "expected at least one value"))
  (parser/produce p))


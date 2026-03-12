(import mendoza :as mdz)

(defn main [& args]
  (let [args (slice args 1) # Skip the binary name itself
        command (get args 0 "")]
    
    (mdz/init)

    (case command
      "build" (do
                (print "🔨 Building wiki...")
                (mdz/build))
      "help"  (print "Usage: munin [build|help]")
      (print "Unknown command. Try 'munin help'"))))

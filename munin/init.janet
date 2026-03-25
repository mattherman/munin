(import ./munin)

(defn main [& args]
  (let [args (slice args 1) # Skip the binary name itself
        command (get args 0 "")]

    (case command
      "build" (do
                (print "🔨 Building wiki...")
                (munin/build))
      "help"  (print "Usage: munin [build|help]")
      (print "Unknown command. Try 'munin help'"))))

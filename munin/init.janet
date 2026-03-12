(import mendoza :as mdz)

(defn main [& args]
  (let [args (slice args 1) # Skip the binary name itself
        command (get args 0 "build")]
    
    (case command
      "build" (do
                (print "🔨 Building wiki...")
                (mdz/build "content" "public"))
      "help"  (print "Usage: mywiki [build|version]")
      (print "Unknown command. Try 'mywiki help'"))))

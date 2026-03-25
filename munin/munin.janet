(def md-filename
  ~(sequence (some :a) ".md" (not 1)))

(defn read-file :private [path]
  (with [f (file/open path)]
    (file/read f :all)))

(defn build [&opt content-dir output-dir]
  (default content-dir "content")
  (default output-dir "site")

  (def pages @[])
  (defn collect-files [path]
    (case (os/stat path :mode)
      :directory (each f (sort (os/dir path))
                   (collect-files (string path "/" f)))
      :file (when true #(peg/match md-filename path)
              (print "Parsing " path " as markdown")
              (print (read-file path)))))
  (collect-files content-dir))

(build)

(import ./jdn)

(def md-filename
  ~(sequence (some :a) ".md" (not 1)))

(defn read-file :private [path]
  (with [f (file/open path)]
    (file/read f :all)))

(defn parse-page [content]
  (def end-of-frontmatter (string/find "---" content))
  (def raw-frontmatter
    (string/trim
      (string/slice content 0 end-of-frontmatter)))
  (def markdown
    (string/trim
      (string/slice content (+ end-of-frontmatter 3))))

  (def frontmatter (jdn/decode raw-frontmatter))

  [frontmatter markdown])

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
              (def page (parse-page (read-file path)))
              (pp page)
              (array/push pages page))))
  (collect-files content-dir))


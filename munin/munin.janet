(import ./jdn)
(import ./render)
(import spork/path :as path)

(def md-filename
  (peg/compile ~(sequence (some (if-not ".md" 1)) ".md" -1)))

(defn read-file :private [path]
  (with [f (file/open path)]
    (file/read f :all)))

(defn parse-page [path]
  (def content (read-file path))
  (def end-of-frontmatter (string/find "---" content))
  (def raw-frontmatter
    (string/trim
      (string/slice content 0 end-of-frontmatter)))
  (def markdown
    (string/trim
      (string/slice content (+ end-of-frontmatter 3))))

  (def frontmatter (jdn/decode raw-frontmatter))

  {:path path
   :frontmatter frontmatter
   :markdown markdown})

(defn build [&opt content-dir output-dir]
  (default content-dir "content")
  (default output-dir "site")

  (def pages @[])
  (defn collect-pages [path]
    (case (os/stat path :mode)
      :directory (each f (sort (os/dir path))
                   (collect-pages (string path "/" f)))
      :file (when (peg/match md-filename path)
              (print "Parsing " path " as markdown")
              (def page (parse-page path))
              (pp page)
              (array/push pages page))))
  (collect-pages content-dir)

  (defn write-file [path content]
    (print "dirname = " (path/dirname path))
    (with [f (file/open path :w)]
      (file/write f content)))

  (if-not (= (os/stat output-dir :mode) :directory)
    (os/mkdir output-dir))

  (each page pages
    (def output-path
      (string output-dir "/" (page :path)))
    (print "output-path = " output-path)
    (def output-path-html
      (string/replace ".md" ".html" output-path))
    (print "output-path-html = " output-path-html)
    (write-file output-path-html
                (render/render page))))
  
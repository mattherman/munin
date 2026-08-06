(import ./jdn)
(import ./render)
(import ./markdown :as md)
(import spork/path :as path)

(def md-filename :private
  (peg/compile ~(sequence (some (if-not ".md" 1)) ".md" -1)))

(def page-link :private
  (peg/compile ~(* "[[" (<- (any (if-not "]]" 1))) "]]")))

(defn read-file :private [path]
  (with [f (file/open path)]
    (file/read f :all)))

(defn create-dirs :private
  "Recursively create directories for a path if they don't exist
  Copied from mendoza: https://github.com/bakpakin/mendoza/blob/master/mendoza/init.janet"
  [path]
  (def parts (tuple/slice (string/split "/" path) 0 -2))
  (def buf @"")
  (each part parts
    (buffer/push-string buf part)
    (def path (string buf))
    (unless (= (os/stat path :mode) :directory)
      (os/mkdir path))
    (buffer/push-string buf "/")))

(defn write-file :private [path content]
  (create-dirs path)
  (with [f (file/open path :w)]
    (file/write f content)))

(defn get-relative-path :private [path]
  (path/join
    ;(match (path/parts path)
      [x y & rest] @[y ;rest]
      x x)))

(defn get-output-path :private [output-dir page]
  (string/replace ".md" ".html"
    (path/join output-dir (page :path))))

(defn parse-page [path]
  (print "=> " path)
  (def content (read-file path))
  (def end-of-frontmatter (string/find "---" content))
  (def raw-frontmatter
    (string/trim
      (string/slice content 0 end-of-frontmatter)))
  (def markdown
    (string/trim
      (string/slice content (+ end-of-frontmatter 3))))

  (def frontmatter (jdn/decode raw-frontmatter))

  (def relative-path (get-relative-path path))

  (def href (string/replace ".md" ".html" relative-path))

  @{:path relative-path
    :href href
    :title (frontmatter :title)
    :markdown markdown
    :html (md/markdown->html markdown)})

(defn process-links :private [pages page]
  (def links @())
  (defn subst-anchor-tag [_ title]
    (array/push links title)
    (def target (get pages title))
    (string "<a href='/" (target :href) "'>" title "</a>"))
  (def modified-html
    (peg/replace-all
      page-link
      subst-anchor-tag
      (page :html)))
  (put page :html modified-html)
  (put page :links-to links)
  page)

(defn process-backlinks [pages]
  (def backlinks @{})
  (each page pages
    (each target (page :links-to)
      (def source (page :title))
      (def list (get backlinks target))
      (if list
        (array/push list source)
        (put backlinks target @(source)))))
  backlinks)

(defn build [&opt content-dir output-dir]
  (default content-dir "content")
  (default output-dir "site")

  (def pages @{})
  (defn collect-pages [path]
    (case (os/stat path :mode)
      :directory (each f (sort (os/dir path))
                   (collect-pages (string path "/" f)))
      :file (when (peg/match md-filename path)
              (def page (parse-page path))
              (put pages (page :title) page))))
  (collect-pages content-dir)

  (each page pages
    (process-links pages page))

  (def backlinks (process-backlinks pages))

  (each page pages
    (def output-path (get-output-path output-dir page))
    (->> page
      (render/render)
      (write-file output-path))))

# parse-page
#  { :title "..." :markdown "..." }
# process-links
#  { :title "..." :markdown "..." :links-to @("a", "b", ...)}
# process-backlinks
#  { :title "..." :markdown "..." :links-to @(...) :linked-from @("d", "e", ...)}
# markdown -> html -> replace-links -> template -> full html -> file
(import ./jdn)
(import ./render)
(import ./markdown :as md)
(import spork/path :as path)

(def md-filename-pattern :private
  (peg/compile ~(sequence (some (if-not ".md" 1)) ".md" -1)))

(def page-link-pattern :private
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

  (def href (string/replace ".md" ".html" (string "/" relative-path)))

  @{:path relative-path
    :href href
    :title (frontmatter :title)
    :template (frontmatter :template)
    :markdown markdown
    :html (md/markdown->html markdown)
    :links-to @()
    :linked-from @()})

(defn page-link [page]
  (string "<a href='" (page :href) "'>" (page :title) "</a>"))

(defn process-links :private [pages page]
  (defn subst-anchor-tag [_ title]
    (def target (get pages title))
    (array/push (page :links-to) @{ :href (target :href) :text (target :title)})
    (array/push (target :linked-from) @{ :href (page :href) :text (page :title)})
    (page-link target))
  (def modified-html
    (peg/replace-all
      page-link-pattern
      subst-anchor-tag
      (page :html)))
  (put page :html modified-html)
  page)

(defn build [&opt content-dir output-dir]
  (default content-dir "content")
  (default output-dir "site")

  (def start-time (os/clock))

  (print "building wiki...")

  (print "\ndiscovering pages...")
  (def pages @{})
  (defn collect-pages [path]
    (case (os/stat path :mode)
      :directory (each f (sort (os/dir path))
                   (collect-pages (string path "/" f)))
      :file (when (peg/match md-filename-pattern path)
              (printf "\t%s" path)
              (def page (parse-page path))
              (put pages (page :title) page))))
  (collect-pages content-dir)
  (printf "\tfound %d pages" (length (keys pages)))

  (print "\nprocessing links...")
  (each page pages
    (process-links pages page))
  (printf "\tprocessed %d links" (sum (map |(length ($ :links-to)) pages)))
  (printf "\tprocessed %d backlinks" (sum (map |(length ($ :linked-from)) pages)))

  (print "\nrendering pages...")
  (each page pages
    (def output-path (get-output-path output-dir page))
    (printf "\t%s -> %s" (page :path) output-path)
    (->> page
      (render/render)
      (write-file output-path)))

  (def duration-ms (math/floor (* 1000 (- (os/clock) start-time))))

  (printf "\ndone. built %d pages in %dms" (length (keys pages)) duration-ms))

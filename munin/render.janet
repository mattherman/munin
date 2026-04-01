(import ./markdown :as md)

(defn render [frontmatter page]
  (def html (md/markdown->html page))
  html)


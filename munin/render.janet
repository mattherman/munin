(import ./markdown :as md)

(defn escape-html [b]
  b)

(defn render-attrs [attrs]
  (string/join
    (map
      (fn [attr]
        (let [[name value] attr]
          (string (string name) "=\"" value "\"")))
      (pairs attrs))
    " "))


(defn html [node]
  (cond
    (string? node)
      (escape-html node)
    (tuple? node)
      (let [[tag & rest] node]
        (let [
              attrs (if (struct? (first rest)) (first rest) nil)
              children (if (struct? (first rest)) (slice rest 1) rest)
              ]
          (string
            "<"
            (string tag)
            (when (not (nil? attrs))
              (string " " (render-attrs attrs)))
            ">"
            (string/join (map html children))
            "</"
            (string tag)
            ">")))
      (string node)))

(defn render [frontmatter page]
  (def html (md/markdown->html page))
  html)

(html [:html
       [:body
        [:div { :class "container" }
         [:h1 "Title"]
         [:p "This is the content"]
         [:a { :href "http://google.com" :alt "something" } "My Link"]]]])


(->> "hello & <world>"
    (string/replace-all "&" "&amp;")
    (string/replace-all "<" "&lt;")
    (string/replace-all ">" "&gt;"))

(pp (->> "hello & <world>"
     (string/replace-all "&" "&amp;")
     (string/replace-all "<" "&lt;")
     (string/replace-all ">" "&gt;")))


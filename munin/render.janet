(def void-elements
  "Returns nil if a tag is not self-closing."
  @{
   :area true
   :base true
   :br true
   :col true
   :embed true
   :hr true
   :img true
   :input true
   :link true
   :meta true
   :param true
   :source true
   :track true
   :wb true
   })

(defn escape-html
  :private
  "Simple HTML escaping of strings. Handles `&`, `<`, and `>` only. Returns the escaped HTML."
  [str]
  (->> str
      (string/replace-all "&" "&amp;")
      (string/replace-all "<" "&lt;")
      (string/replace-all ">" "&gt;")))

(defn render-attrs 
  :private
  "Accepts a table of HTML attribute pairs, renders them as `key='value'`, and returns a single joined string."
  [attrs]
  (string/join
    (map
      (fn [attr]
        (let [[name value] attr]
          (string (string name) "=\"" (escape-html value) "\"")))
      (pairs attrs))
    " "))


(defn html
  "Render a Hiccup-style DOM node to HTML. Generated HTML is automatically escaped. Returns the rendered HTML for the node."
  [node]
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
            (if (void-elements tag)
              " />"
              (string
                ">"
                (string/join (map html children))
                "</" (string tag) ">")))))
      (string node)))


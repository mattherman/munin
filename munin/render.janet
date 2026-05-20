(import ./markdown :as md)

(def void-elements
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

(defn escape-html [str]
  (->> str
      (string/replace-all "&" "&amp;")
      (string/replace-all "<" "&lt;")
      (string/replace-all ">" "&gt;")))

(defn render-attrs [attrs]
  (string/join
    (map
      (fn [attr]
        (let [[name value] attr]
          (string (string name) "=\"" (escape-html value) "\"")))
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
            (if (void-elements tag)
              " />"
              (string
                ">"
                (string/join (map html children))
                "</" (string tag) ">")))))
      (string node)))

(defn render [page]
  (md/markdown->html (page :markdown)))


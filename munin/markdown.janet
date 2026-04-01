(defn markdown->html [markdown-str]
  (let [proc (os/spawn ["cmark" "--smart"] :p {:in :pipe :out :pipe})
        stdin (proc :in)
        stdout (proc :out)]
    (:write stdin markdown-str)
    (:close stdin)
    (let [html (:read stdout :all)]
      (:wait proc)
      html)))


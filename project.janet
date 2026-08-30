(declare-project
  :name "munin"
  :description ```A knowledge base and wiki static site generator.```
  :version "0.0.1"
  :dependencies ["spork"])

(declare-executable
  :name "munin"
  :entry "munin/init.janet"
  :install true)

(defn link
  :private
  "Creates a link node. Expects a table containing an `:href` and `:text`."
  [link]
  (let
    [href (link :href)
     text (link :text)]
    [:a { :href href } text]))

(defn backlinks
  :private
  "Creates a collection of backlinks for a page."
  [page]
  (let [backlinks (page :linked-from)]
    (tuple/slice (map link backlinks))))

(defn article
  "Template for a wiki article page. Expects the page to include `:title`, `:created-date`, `:updated-date`, and `:backlinks`."
  [page]
  [:html
   [:head
    [:meta { :charset "UTF-8"}]
    [:meta { :name "viewport" :content "width=device-width, initial-scale=1.0" }]
    [:title (page :title)]]
   [:body
    [:header]
    [:nav]
    [:main
      [:article
        [:header
          [:h1 (page :title)]
          [:div (string/format "Page created: %s" (page :created-date))]
          [:div (string/format "Page updated: %s" (page :updated-date))]]
        [:hr]
        [:section (page :html)]]
      [:aside ;(backlinks page)]
      ]
    [:footer]]])

#<!DOCTYPE html>
#<html lang="en">
#<head>
#  <!-- Character encoding -->
#  <meta charset="UTF-8">
#
#  <!-- Responsive viewport -->
#  <meta name="viewport" content="width=device-width, initial-scale=1.0">
#
#  <!-- Page title (shown in browser tab & search results) -->
#  <title>Page Title</title>
#
#  <!-- SEO meta tags -->
#  <meta name="description" content="A brief description of the page (150–160 chars ideal).">
#  <meta name="author" content="Your Name">
#
#  <!-- Open Graph (social sharing previews) -->
#  <meta property="og:title" content="Page Title">
#  <meta property="og:description" content="Description for social previews.">
#  <meta property="og:image" content="https://example.com/preview-image.jpg">
#  <meta property="og:url" content="https://example.com/this-page">
#  <meta property="og:type" content="website">
#
#  <!-- Favicon -->
#  <link rel="icon" href="/favicon.ico" type="image/x-icon">
#  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
#
#  <!-- Canonical URL (prevents duplicate content issues) -->
#  <link rel="canonical" href="https://example.com/this-page">
#
#  <!-- Stylesheets -->
#  <link rel="stylesheet" href="/styles/main.css">
#
#  <!-- Preconnect to external origins (performance) -->
#  <link rel="preconnect" href="https://fonts.googleapis.com">
#</head>
#<!-- <body> goes here -->

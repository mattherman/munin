(defn article [page]
  [:html
   [:head
    [:meta { :charset "UTF-8"}]
    [:meta { :name "viewport" :content "width=device-width, initial-scale=1.0" }]
    [:title (page :title)]]
   [:body (page :html)]]
  )

(pp (article { :title "Home" :html "<h1>Home</h1><p>This is the homepage</p>"}))

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

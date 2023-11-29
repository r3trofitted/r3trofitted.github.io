$LOAD_PATH.unshift __dir__ # so that local plugins from /zenweb/plugins are also found

require "zenweb/tasks"

task :extra_wirings do
  site = $website
  html = site.pages.reject { |k,p| p.url_path !~ /\.html/ }
  
  # generate virtual index pages for the article series; they can be used to create links to articles in each series
  Zenweb::SeriesPage.generate_all(site, "articles", site.categories.articles)
  Zenweb::SeriesPage.generate_all(site, "blog", site.categories.blog)
  
  site.pages["sitemap.xml.erb"].depends_on html
  site.pages["feed.xml.erb"].depends_on site.categories.values_at("blog", "articles").flatten
  
  # site.pages["articles/feed.xml.erb"].  depends_on site.categories.articles
  site.pages["articles/index.html.erb"].depends_on site.categories.articles

  # site.pages["blog/feed.xml.erb"].  depends_on site.categories.blog
  site.pages["blog/index.html.erb"].depends_on site.categories.blog
end

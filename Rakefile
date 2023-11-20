$LOAD_PATH.unshift __dir__ # so that local plugins from /zenweb/plugins are also found

require "zenweb/tasks"

task :extra_wirings do
  site = $website
  
  site.pages["articles/feed.xml.erb"].  depends_on site.categories.articles
  site.pages["articles/index.html.erb"].depends_on site.categories.articles

  site.pages["blog/feed.xml.erb"].  depends_on site.categories.blog
  site.pages["blog/index.html.erb"].depends_on site.categories.blog
end

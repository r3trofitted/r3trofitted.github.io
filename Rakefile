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
  
  # 301s - a bit hackish but that will do for now, it's only temporary (meaning it will still be here in 10 years).
  # These are the 2 pages visited in the last 30 days – no need to do the whole blog.
  %w(
    2023-11-06-you-don-t-need-services-whatever-this-word-means
    2023-11-14-better-practices-by-example-rspec
  ).each { |p| site.pages["#{p}.html.erb"].depends_on site.pages["articles/#{p}.html.md"] }
  
  %w(
    2023-11-05-humility-check
  ).each { |p| site.pages["#{p}.html.erb"].depends_on site.pages["blog/#{p}.html.md"] }
end

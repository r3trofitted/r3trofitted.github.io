module Plugins
  module Site
    def regular_posts
      categories.blog - dashes_of_milk
    end
    
    def dashes_of_milk
      categories
        .blog
        .select { |p| p.path.include? "a-dash-of-milk/" }
        .sort_by { |p| [-p.date.to_i, p.title] }
    end
    
    def regular_articles
      categories.articles - Zenweb::SeriesPage.all.flat_map { _2.pages }
    end
  end
end

Zenweb::Site.include Plugins::Site

module Plugins
  module Page
    def series
      config[:series] if config.key? :series
    end
    
    def part
      config[:part].to_i if config.key? :part
    end
    
    def previous_part
      return unless part && series_page
      
      series_page.pages.find { |p| p.part == part.pred }
    end
    alias_method :previous_page, :previous_part
    
    def next_part
      return unless part && series_page
      
      series_page.pages.find { |p| p.part == part.next }
    end
    alias_method :next_page, :next_part
    
    def dash_of_milk?
      path.include? "/a-dash-of-milk/"
    end
    
    def canonical_url
      root_url + clean_url
    end
    
    def icon_style_attribute
      %Q{style="--category-icon: url(/assets/icons/#{config["icon"]}.svg)"} if config.key? "icon"
    end
    
    # Not to be confused with +Zenweb::Site.categories+!
    def categories
      cs = []
      cs.concat Array(config[:categories].split) if config.key? :categories
      cs.append config[:category] if config.key? :category
      cs
    end
    
    def canonical_category
      if categories.one?
        categories.first
      elsif config.key? "icon"
        config["icon"]
      elsif series_page
        "series"
      else
        "miscellanea"
      end
    end
  end
  
  # Hack to prevent crashes when going through all the pages, e.g. when generating sitemaps
  module SeriesPage
    def content
      ""
    end
  end
end

Zenweb::Page.include Plugins::Page
Zenweb::SeriesPage.include Plugins::SeriesPage

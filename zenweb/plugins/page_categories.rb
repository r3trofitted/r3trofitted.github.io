class Zenweb::Page
  def series
    config[:series] if config.key? :series
  end
  
  def part
    config[:part].to_i if config.key? :part
  end
  
  def next_part
    series_page.pages.find { |p| p.part == part.next } if series_page
  end
  
  def dash_of_milk?
    path.include? "/a-dash-of-milk/"
  end
  
  def icon_style_attribute
    %Q{style="--category-icon: url(/assets/icons/#{config["icon"]}.svg)"} if config.key? "icon"
  end
  
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

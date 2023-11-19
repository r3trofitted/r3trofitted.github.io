class Zenweb::Page
  def series
    config[:series] if config.key? :series
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
    else
      "miscellanea"
    end
  end
end

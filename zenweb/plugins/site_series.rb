class Zenweb::Site
  def regular_posts
    categories.blog - dashes_of_milk
  end
  
  def dashes_of_milk
    categories
      .blog
      .select { |p| p.path.include? "a-dash-of-milk/" }
      .sort_by { |p| [-p.date.to_i, p.title] }
  end
end

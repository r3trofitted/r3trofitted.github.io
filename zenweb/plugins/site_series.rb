class Zenweb::Site
  def regular_posts
    categories.blog - dashes_of_milk
  end
  
  def dashes_of_milk
    categories
      .blog
      .select { |p| p.config["series"] == "dash_of_milk" }
      .sort_by { |p| [-p.date.to_i, p.title] }
  end
end

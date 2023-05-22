module Jekyll
  module CanonicalCategoryFilter
    def canonical_category(input)
      if input.categories.one?
        input.categories.first
      else
        "miscellanea"
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::CanonicalCategoryFilter)

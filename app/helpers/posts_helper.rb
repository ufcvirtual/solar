module PostsHelper

  def get_page_posts(posts, current_page = 1)
    items_per_page = Rails.application.config.items_per_page
    # limita o array, ele passa a pegar e exibir apenas os elementos específicos daquela página
    return posts[((current_page.to_i-1) * items_per_page)..((items_per_page*current_page.to_i)-1)]
  end

end

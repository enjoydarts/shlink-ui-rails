module ApplicationHelper
  def nav_link_class(page)
    current_page = case
                   when request.path.include?('/mypage')
                     'mypage'
                   when request.path.include?('/dashboard') || request.path == '/' || request.path.include?('/short_urls')
                     'dashboard'
                   else
                     nil
                   end
    
    base_classes = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
    
    if current_page == page
      "#{base_classes} bg-white text-blue-600 shadow-sm"
    else
      "#{base_classes} text-gray-600 hover:text-blue-600 hover:bg-white/50"
    end
  end
end

require 'will_paginate/view_helpers/action_view'

module PaginationHelper
     class DailyReportsRenderer < WillPaginate::ActionView::LinkRenderer
       def container_attributes
         { class: "pagination" }
       end
   
       def page_number(page)
         if page == current_page
           tag(:span, page, class: "current")
         else
           link(page, page, class: "page")
         end
       end
   
       def previous_or_next_page(page, text, classname, aria_label = nil)
         text = classname.include?('previous') ? previous_arrow : next_arrow
         if page
           link(text.html_safe, page, class: classname, aria: { label: aria_label })
         else
           tag(:span, text.html_safe, class: "#{classname} disabled", aria: { label: aria_label })
         end
       end
   
       def html_container(html)
         tag(:div, html, container_attributes)
       end
   
       private
   
       def previous_arrow
         '<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="7" width="2.82843" height="9.89952" rx="1.41422" transform="rotate(45 7 0)" fill="#C4C4C4"/>
          <rect x="8.9999" y="12" width="2.82843" height="9.89952" rx="1.41422" transform="rotate(135 8.9999 12)" fill="#C4C4C4"/>
          </svg>'
       end
   
       def next_arrow
          '<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect width="2.82843" height="9.89952" rx="1.41422" transform="matrix(-0.707107 0.707107 0.707107 0.707107 6.99998 0)" fill="#C4C4C4"/>
          <rect width="2.82843" height="9.89952" rx="1.41422" transform="matrix(0.707107 0.707107 0.707107 -0.707107 5.00009 12)" fill="#C4C4C4"/>
          </svg>'
       end
     end
   end
   
module ApplicationHelper

     def flash_class(key)
          case key
          when 'success'
          'alert-success'
          when 'error'
          'alert-danger'
          when 'alert'
          'alert-warning'
          when 'notice'
          'alert-info'
          else
          key.to_s
          end
     end
        
end

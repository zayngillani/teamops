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

     def truncate_with_ellipsis(text, length = 50)
        if text.length > length
          "#{text[0...length]}..."
        else
          text
        end
     end

     def get_action_header_text
      if request.path == new_admin_job_post_path
        "Create Job"
      elsif request.path == admin_job_applications_path
        "Applicants"
      elsif request.path.include?(admin_job_application_path(''))
        "Applicant's Details"
      elsif request.path.include?('/admin/job_posts') && request.path.include?('/edit')
        "Edit Job"
      else
        ""
      end
    end
        
        
end

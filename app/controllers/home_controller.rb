class HomeController < ApplicationController
     def index
          # allowed_ip = ENV["IP_ADDRESS"]
          # client_ip = request.remote_ip
          # unless allowed_ip.split(',').include?(client_ip)
          #      file_path = Rails.root.join('app', 'views', 'devise', 'invalid_ip.html.erb')
          #      html_content = File.read(file_path)
          #      render html: html_content.html_safe
          # else
               if current_user.admin?
                    redirect_to admin_users_path
               else
                    if current_user.password_expired?
                         flash[:alert] = "Your password has expired. Please reset your password."
                         redirect_to change_password_path
                    else
                         redirect_to attendance_index_path
                    end
               end
          # end
     end

     def change_password
          unless current_user.user? && current_user.password_expired?
               redirect_to root_path
          end
     end

     def update_password
          new_password = params[:user][:password]
          if new_password == params[:user][:password_confirmation]
            if current_user.valid_password?(new_password)
              flash[:error] = "New password cannot be the same as the current password"
              redirect_to change_password_path
            else
              if current_user.update(user_params)
                current_user.update(password_changed_at: DateTime.now)
                bypass_sign_in(current_user)
                flash[:success] = "Password Successfully Changed"
                redirect_to root_path
              else
                flash[:error] = "Failed to update password"
                redirect_to change_password_path
              end
            end
          else
            flash[:error] = "Passwords don't match"
            redirect_to change_password_path
          end
     end

     def view_resume
          @job_application = JobApplication.find(params[:format])
          resume_link = @job_application.resume_link
          if resume_link.present?
            begin
              file_path = fetch_resume_from_ftp(resume_link)
              send_file(file_path, filename: File.basename(file_path), type: 'application/pdf', disposition: 'inline')
            rescue StandardError => e
              Rails.logger.error "FTP download failed: #{e.message}"
              flash[:error] = "FTP download failed: #{e.message}"
              redirect_to admin_job_application_path(@job_application)
            end
          else
            flash[:error] = 'Resume not found.'
            redirect_to admin_job_application_path(@job_application)
          end
     end

     private
     
     def user_params
          params.require(:user).permit(:password, :password_confirmation)
     end

     def fetch_resume_from_ftp(resume_link)
          ftp = Net::FTP.new
          ftp.connect(ENV['FTP_HOST'], ENV['FTP_PORT'].to_i)
          ftp.login(ENV['FTP_USERNAME'], ENV['FTP_PASSWORD'])
          ftp.passive = true
      
          local_file_path = Rails.root.join('tmp', File.basename(resume_link))
      
          File.open(local_file_path, 'wb') do |file|
            ftp.getbinaryfile(resume_link, file.path)
          end
      
          ftp.close
      
          local_file_path
        rescue StandardError => e
          Rails.logger.error "FTP download failed: #{e.message}"
          raise "FTP download failed: #{e.message}"
        end
end

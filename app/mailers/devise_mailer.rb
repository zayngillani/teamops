class DeviseMailer < Devise::Mailer
     def confirmation_instructions(record, token, opts={})
       unless record.deleted?
         super
       end
     end
end
   
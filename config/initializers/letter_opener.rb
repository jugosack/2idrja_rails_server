# Configure letter_opener to not auto-open browser on Windows
# This prevents Launchy errors - emails are still saved to tmp/letter_opener/
if Rails.env.development?
  require 'letter_opener'
  
  module LetterOpener
    class DeliveryMethod
      alias_method :original_deliver!, :deliver!
      
      def deliver!(mail)
        validate_mail!(mail)
        location = File.join(settings[:location], "#{Time.now.to_f.to_s.tr('.', '_')}_#{Digest::SHA1.hexdigest(mail.encoded)[0..6]}")
        
        messages = Message.rendered_messages(mail, location: location, message_template: settings[:message_template])
        
        # Don't try to open browser - just save the email preview
        # Email previews are available in tmp/letter_opener/ directory
        Rails.logger.info "LetterOpener: Email preview saved to #{location}"
      end
    end
  end
end


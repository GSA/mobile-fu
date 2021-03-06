module ActionController
  module MobileFu
    # These are various strings that can be found in mobile devices.  Please feel free
    # to add on to this list.
    MOBILE_USER_AGENTS =  'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
                          'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
                          'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android*mobile|mmp|' +
                          'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
                          'webos|amoi|novarra|cdm|alcatel|pocket|iphone|mobileexplorer|' +
                          'mobile'
    USER_AGENTS_WHITELIST = 'ipad'
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      
      # Add this to one of your controllers to use MobileFu.  
      #
      #    class ApplicationController < ActionController::Base 
      #      has_mobile_fu
      #    end
      #
      # You can also force mobile mode by passing in 'true'
      #
      #    class ApplicationController < ActionController::Base 
      #      has_mobile_fu(true)
      #    end
        
      def has_mobile_fu(test_mode = false)
        include ActionController::MobileFu::InstanceMethods

        if test_mode 
          before_filter :force_mobile_format
        else
          before_filter :check_mobile_param
          before_filter :set_mobile_format
          after_filter :clear_mobile_session        
        end

        helper_method :is_mobile_device?
        helper_method :in_mobile_view?
        helper_method :is_device?
      end
      
      def is_mobile_device?
        @@is_mobile_device
      end

      def in_mobile_view?
        @@in_mobile_view
      end

      def is_device?(type)
        @@is_device
      end
    end
    
    module InstanceMethods
      
      # Forces the request format to be :mobile
      
      def force_mobile_format
        request.format = :mobile
        session[:mobile_view] = true if session[:mobile_view].nil?
      end
      
      # allow for 'm' parameter with override mode.
  
      def check_mobile_param
        mobile_param = request.params[:m]
        if is_mobile_device? and !request.xhr?
          if mobile_param == "override" or mobile_param == "false"
            session[:mobile_view] = false
          end
        else
          if mobile_param == "true"
            force_mobile_format
          end
        end
      end
      
      # Determines the request format based on whether the device is mobile or if
      # the user has opted to use either the 'Standard' view or 'Mobile' view.
      
      def set_mobile_format
        if is_mobile_device? && !request.xhr?
          request.format = session[:mobile_view] == false ? :html : :mobile
          session[:mobile_view] = true if session[:mobile_view].nil?
        end
      end
      
      # clear the session after each request
      
      def clear_mobile_session
        session[:mobile_view] = nil
      end
      
      # Returns either true or false depending on whether or not the format of the
      # request is either :mobile or not.
      
      def in_mobile_view?
        request.format.present? and request.format.to_sym == :mobile
      end
      
      # Returns either true or false depending on whether or not the user agent of
      # the device making the request is matched to a device in our regex.
      
      def is_mobile_device?
        user_agent = request.user_agent.to_s.downcase
        (user_agent !~ Regexp.new(ActionController::MobileFu::USER_AGENTS_WHITELIST)) and user_agent =~ Regexp.new(ActionController::MobileFu::MOBILE_USER_AGENTS)
      end

      # Can check for a specific user agent
      # e.g., is_device?('iphone') or is_device?('mobileexplorer')
      
      def is_device?(type)
        request.user_agent.to_s.downcase.include?(type.to_s.downcase)
      end
    end
    
  end
  
end

ActionController::Base.send(:include, ActionController::MobileFu)

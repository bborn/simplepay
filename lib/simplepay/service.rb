module Simplepay
  
  ##
  # This is a base class from which to inherit functionality for all Amazon
  # Simple Pay services (Subscriptions, Marketplace Buttons, etc.)
  # 
  class Service
    
    # Fully-qualified URL for the production endpoint for the service.
    ENDPOINT_URL  = 'https://authorize.payments.amazon.com/pba/paypipeline'
    
    # Fully-qualified URL for the sandbox (test) endpoint for the service.
    SANDBOX_URL   = 'https://authorize.payments-sandbox.amazon.com/pba/paypipeline'
    
    class << self
      
      ##
      # Defines a field for the service.
      # 
      # === Usage
      # 
      #     class Foo < Service
      #       field :access_key
      #       field :amount,    :class => Amount, :map_to => :value
      #     end
      # 
      def field(name, options = {})
        field = Support::Field.new(self, name, options)
        define_method("#{name.to_s.underscore}=", Proc.new { |value| self.fields.detect { |f| f.name == name }.value = value })
        self.fields << field
        field
      end
      
      ##
      # Optional convenience method for:
      # 
      #     field :field_name, :required => true
      # 
      # Any other +options+ given will be still be passed through.
      # 
      def required_field(name, options = {})
        field(name, options.merge(:required => true))
      end
      
      ##
      # Returns the collection of fields defined by the service class.
      # 
      def fields
        @fields ||= []
      end
      
      def set_submit_tag(value)
        @submit_tag = value
      end
      
      def submit_tag
        @submit_tag
      end
      
    end
    
    
    ##
    # Returns the fields for the service instance.
    # 
    def fields
      @fields ||= self.class.fields.collect { |f| f.clone_for(self) }
    end
    
    ##
    # Returns the URL for the service endpoint to use.  If +sandbox+ is true,
    # the SANDBOX_URL will be used.  Otherwise, the ENDPOINT_URL will be used.
    # 
    def url(sandbox = Simplepay.use_sandbox?)
      sandbox ? self.class.const_get(:SANDBOX_URL) : self.class.const_get(:ENDPOINT_URL)
    end
    
    def form(attributes = {}, submit = nil)
      set_accessor_fields
      set_fields(attributes)
      set_signature
      content = generate_input_fields + generate_submit_field(submit)
      Simplepay::Helpers::FormHelper.content_tag(:form, content, {:method => 'post', :action => url})
    end
    
    
    private
    
    
    def generate_input_fields
      self.fields.collect { |f| f.to_input }.join
    end
    
    def generate_submit_field(submit)
      options = {:type => 'submit'}
      options.merge!(:value => self.class.submit_tag) if self.class.submit_tag
      submit ? submit.to_s : Simplepay::Helpers::FormHelper.tag(:input, options)
    end
    
    def set_accessor_fields
      self.access_key = Simplepay.aws_access_key_id if self.respond_to?(:access_key=)
      self.account_id = Simplepay.account_id if self.respond_to?(:account_id=)
    end
    
    def set_fields(hash)
      hash.each_pair do |key, value|
        self.send("#{key}=", value) if self.respond_to?("#{key}=")
      end
    end
    
    def set_signature
      fields = {}
      self.fields.each { |f| fields[f.service_name] = f.value unless f.service_name == 'signature' }
      self.signature = Authentication.generate(fields) if self.respond_to?(:signature=)
    end
    
  end
  
end

require 'simplepay/services/subscription'
require 'simplepay/services/standard'
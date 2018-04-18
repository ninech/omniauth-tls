require 'omniauth'
require 'openssl'

module OmniAuth
  module Strategies
    class TLS
      include OmniAuth::Strategy

      class UnknownValueSource < StandardError
      end
      class ClientCertificateValidationFailed < StandardError
      end

      # source of value, :env or :http
      option :value_source, :env

      option :validity_end_variable, 'SSL_CLIENT_V_END'

      option :dn_variable, 'SSL_CLIENT_S_DN'
      option :dn_email_field, 'emailAddress'
      option :dn_name_field, 'CN'

      ##
      # Exact value or regular expression
      # Apache: https://httpd.apache.org/docs/2.4/mod/mod_ssl.html#sslverifyclient
      # Nginx: http://nginx.org/en/docs/http/ngx_http_ssl_module.html#var_ssl_client_verify
      option :validation_success_value, 'SUCCESS'
      option :validation_success_variable, 'SSL_CLIENT_VERIFY'
      option :verify_validation_success_state, true

      option :use_email_as_uid, false

      uid do
        if options.use_email_as_uid
          email
        else
          dn
        end
      end

      info do
        {
          name: dn_name,
          email: dn_email,
        }
      end

      extra do
        {
          dn: dn,
          v_end: v_end,
        }
      end

      def request_phase
        redirect callback_url
      end

      def callback_phase
        unless ssl?
          log :debug, 'No TLS request.'
          return
        end

        unless options.verify_validation_success_state
          log :debug, 'TLS client certificate validation is disabled.'
          return
        end

        if check_validation_success
          super
        else
          fail!(:validation_failed,
                ClientCertificateValidationFailed.new("The client certificate could not be validated.")
          )
        end
      end

      private

      def check_validation_success
        expected_state = options.validation_success_value
        state = value_of options.validation_success_variable

        log :debug, "TLS client certificate validation. Expected: '#{options.validation_success_value}', Received: '#{state}'"

        state == expected_state
      end

      def dn_email
        @dn_email ||= dn_field(options.dn_email_field)
      end

      def dn_name
        @dn_name ||= dn_field(options.dn_name_field)
      end

      def dn_field(field)
        @dn_field_pairs ||= OpenSSL::X509::Name.parse(dn).to_a

        dn_field_pair = @dn_field_pairs.select { |dn_pair| dn_pair.first == field }.first
        return nil unless dn_field_pair
        dn_field_pair[1]
      end

      def v_end
        @v_end ||= value_of options.validity_end_variable
      end

      def dn
        @dn ||= value_of options.dn_variable
      end

      def value_of(name)
        case options.value_source
        when :http
          log :debug, "Looking for the value of 'HTTP_X_#{name}'"
          request.env["HTTP_X_#{name}"]
        when :env
          log :debug, "Looking for the value of '#{name}'"
          request.env[name]
        else
          raise UnknownValueSource,
                "'#{options.value_source}' is no recognized source for values. Use ':http' or ':env'."
        end
      end
    end
  end
end

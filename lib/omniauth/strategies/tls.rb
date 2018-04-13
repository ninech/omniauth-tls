require 'omniauth'

module OmniAuth
  module Strategies
    class TLS
      include OmniAuth::Strategy

      class UnknownInformationSource < StandardError
      end
      class ClientCertificateValidationFailed < StandardError
      end

      option :validity_end_variable, 'SSL_CLIENT_V_END'

      option :dn_variable, 'SSL_CLIENT_S_DN'
      option :dn_email_field, 'CN'
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
          raw_info: {
            dn: dn,
            v_end: end_date,
          }
        }
      end

      def redirect_phase
        redirect callback_url
      end

      def callback_phase
        super unless options.verify_validation_success_state

        expected_state = options.validation_success_value
        state = value_of options.validation_success_variable

        return fail!(:validation_failed,
              ClientCertificateValidationFailed.new(
                "The validation state is '#{state}', but the expected state is '#{expected_state}'.")
        ) if state != expected_state

        super
      end

      private

      def dn_email
        parsed_dn.to_a.select do |dn_pair|
          dn_pair[0] == options.dn_email_field
        end
      end

      def dn_name
        dn_field(options.dn_name_field)
      end

      def dn_field(field)
        @dn_field_pairs ||= OpenSSL::X509::Name.parse(dn).to_a

        dn_field_pair = @dn_field_pairs.select { |dn_pair| dn_pair.first == field }.first
        dn_field_pair.second
      end

      def v_end
        value_of options.validity_end_variable
      end

      def dn
        value_of options.dn_variable
      end

      def value_of(name)
        request.env[name]
      end
    end
  end
end

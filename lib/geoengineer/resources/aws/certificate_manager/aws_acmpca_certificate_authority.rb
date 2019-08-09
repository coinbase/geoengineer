########################################################################
# AwsAcmpcaCertificateAuthority is the +aws_acmpca_certificate_authority+
# terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/acmpca_certificate_authority.html}
########################################################################
class GeoEngineer::Resources::AwsAcmpcaCertificateAuthority < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  validate -> { validate_required_attributes([:type]) }
  validate -> { validate_required_attributes([:tags]) }
  validate -> { validate_required_attributes([:certificate_authority_configuration]) }
  validate -> { validate_subresource_required_attributes(:certificate_authority_configuration, [:subject]) }
  validate -> { validate_subresource_required_attributes(:certificate_authority_configuration, [:key_algorithm]) }
  validate -> { validate_subresource_required_attributes(:certificate_authority_configuration, [:signing_algorithm]) }
  validate -> { validate_subresource_required_attributes(:subject, [:common_name]) }

  after :initialize, -> { _geo_id -> { [type, common_name].join("::") } }
  def common_name
    if !self.certificate_authority_configuration.nil? &&
       !self.certificate_authority_configuration.subject.nil? &&
       !self.certificate_authority_configuration.subject.common_name.nil?

      return self.certificate_authority_configuration.subject.common_name
    end
    NullObject.new()
  end

  def self._fetch_remote_resources(provider)
    AwsClients.acmpca(provider)
              .list_certificate_authorities["certificate_authorities"]
              .map(&:to_h)
              .reject { |ca| ca[:status] == "DELETED" }
              .map { |ca|
      ca[:_terraform_id] = ca[:arn]
      ca[:_geo_id] = "#{ca[:type]}::#{ca[:certificate_authority_configuration][:subject][:common_name]}"
      ca
    }
  end
end

########################################################################
# AwsAcmpcaCertificate resource issued by AWS Private CA
#
# Creating a private CA issued certificate
# domain_name - (Required) A domain name for which the certificate should be issued
# certificate_authority_arn - (Required) ARN of an ACMPCA
# subject_alternative_names - (Optional) A list of domains that should be SANs in the issued certificate
#
# {https://www.terraform.io/docs/providers/aws/r/acmpca_certificate_authority.html}
########################################################################
class GeoEngineer::Resources::AwsAcmCertificatePrivateCa < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  validate -> { validate_required_attributes([:domain_name]) }
  validate -> { validate_required_attributes([:certificate_authority_arn]) }
  validate -> { validate_required_attributes([:options]) }
  validate -> { validate_subresource_required_attributes(:options, [:certificate_transparency_logging_preference]) }
  validate -> { validate_has_tag(:Name) }
  validate -> { validate_ctlp_disabled }

  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def validate_ctlp_disabled
    !options&.certificate_transparency_logging_preference
  end

  # The ACM certificate resource  does not wait for a certificate to be issued.
  # Always create a new Certificate for now, no need to fetch exisiting resources
  # The resource will be used in conjunction with aws_acm_certificate_validation resource
  # at which point we need to fetch_remote_resources
  def self._fetch_remote_resources(provider)
    []
  end

  def support_tags?
    true
  end
end

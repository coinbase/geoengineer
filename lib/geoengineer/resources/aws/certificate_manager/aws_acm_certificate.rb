########################################################################
# AwsAcmCertificate resource issued by AWS Private CA
#
# Creating a private CA issued certificate
# domain_name - (Required) A domain name for which the certificate should be issued
# certificate_authority_arn - (Required) ARN of an ACMPCA
# subject_alternative_names - (Optional) A list of domains that should be SANs in the issued certificate
#
# {https://www.terraform.io/docs/providers/aws/r/acmpca_certificate_authority.html}
########################################################################
class GeoEngineer::Resources::AwsAcmCertificate < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  validate -> { validate_required_attributes([:domain_name]) }
  ## Note: The certificate_authority_arn is a required attribute which implies
  ## we are only requesting private ca issued certificates at this time
  validate -> { validate_required_attributes([:certificate_authority_arn]) }
  validate -> { validate_required_attributes([:options]) }
  validate -> { validate_has_tag(:Name) }

  def self._fetch_remote_resources(provider)
    AwsClients.acm(provider)
              .list_certificates({ certificate_statuses: ["ISSUED"] })["certificate_summary_list"]
              .map(&:to_h)
              .each { |cert|
                cert[:_terraform_id] = cert[:certificate_arn]
                AwsClients.acm(provider)
                          .list_tags_for_certificate({ certificate_arn: cert[:certificate_arn] })["tags"]
                          .each { |tag|
                  cert[:_geo_id] = tag.value if tag.key == "Name"
                }
              }
  end

  def support_tags?
    true
  end
end

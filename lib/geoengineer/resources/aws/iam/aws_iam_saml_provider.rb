########################################################################
# AwsIamSamlProvider is the +aws_iam_saml_provider+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_saml_provider.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamSamlProvider < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :saml_metadata_document]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    idp_reg = %r{^arn:aws:iam::[0-9]{12}:saml-provider/(.+)$}
    AwsClients.iam(provider)
              .list_saml_providers
              .saml_provider_list
              .map do |idp|
                name = idp.arn[idp_reg, 1]
                {
                  _terraform_id: idp.arn,
                  _geo_id: name
                }
              end
  end
end

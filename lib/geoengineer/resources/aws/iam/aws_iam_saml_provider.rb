########################################################################
# AwsIamSamlProvider is the +aws_iam_saml_provider+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_saml_provider.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamSamlProvider < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :saml_metadata_document]) }

  after :initialize, -> { _terraform_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.iam(provider)
              .list_saml_providers
              .saml_provider_list
              .map do |idp|
                {
                  _terraform_id: idp.arn,
                  _geo_id: idp.arn
                }
              end
  end
end

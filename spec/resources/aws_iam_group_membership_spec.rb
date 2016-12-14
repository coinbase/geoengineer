require_relative '../spec_helper'

describe "GeoEngineer::Resources::AwsIamGroupMembership" do
  let(:aws_client) { AwsClients.iam }

  let!(:iam_user) do
    GeoEngineer::Resources::AwsIamUser.new('aws_iam_user', 'fake-iam-user') {
      name 'fake-iam-user'
    }
  end

  let!(:iam_group) do
    GeoEngineer::Resources::AwsIamGroup.new('aws_iam_group', 'fake-iam-group') {
      name 'fake-iam-group'
    }
  end

  let(:iam_group_membership) do
    group = iam_group
    user = iam_user

    GeoEngineer::Resources::AwsIamGroupMembership
      .new('aws_iam_group_membership', 'fake-iam-group-membership') {
        name 'fake-iam-group-membership'
        _group group
        users [user]
      }
  end

  common_resource_tests(
    GeoEngineer::Resources::AwsIamGroupMembership,
    'aws_iam_group_membership',
    false
  )

  before do
    aws_client.stub_responses(
      :list_groups, {
        'groups': [
          {
            group_name: 'fake-iam-group',
            path: '/',
            arn: 'arn:aws:iam::aws:iam-group/xyv/FakeAwsARN',
            create_date: Time.parse("2016-12-13 11:54:59 -0800"),
            group_id: '12345'
          }
        ]
      }
    )

    aws_client.stub_responses(
      :get_group, {
        'group': {
          group_name: 'fake-iam-group',
          path: '/',
          arn: 'arn:aws:iam::aws:iam-group/xyv/FakeAwsARN',
          create_date: Time.parse("2016-12-13 11:54:59 -0800"),
          group_id: '12345'
        },
        'users': [
          {
            path: '/',
            user_name: 'fake-iam-user',
            user_id: '1234',
            arn: 'arn:aws:iam::aws:iam-user/xyv/FakeAwsARN',
            create_date: Time.parse("2016-12-14 11:54:59 -0800")
          }
        ]
      }
    )
  end

  describe '#remote_resource_params' do
    it 'should create a hash of params for the remote resources' do
      remote_resource_params = iam_group_membership.remote_resource_params

      expect(remote_resource_params[:name]).to eql("fake-iam-group")
      expect(remote_resource_params[:_terraform_id]).to eql("fake-iam-group-membership")
      expect(remote_resource_params[:_geo_id]).to eql("fake-iam-group-membership")
      expect(remote_resource_params[:users]).to eql(["fake-iam-user"])
    end
  end
end

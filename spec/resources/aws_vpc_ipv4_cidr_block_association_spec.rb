require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsVpcIpv4CidrBlockAssociation) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#validate_cidr_restrictions" do
    [
      ["10.100.0.0/24", "10.150.0.0/13", "should not allow a cidr range bigger than /16"],
      ["10.100.0.0/24", "10.150.0.0/29", "should not allow a cidr range smaller than /28"],
      ["10.100.0.0/24", "10.100.0.0/25", "should not allow a cidr to overlap the primary vpc range"],
      ["10.0.0.0/20", "10.0.0.0/17", "should not allow a cidr in 10.0.0.0/16 if the primary vpc range "\
        "is in 10.0.0.0/15"],
      ["172.16.0.0/14", "172.31.0.0/18", "should not allow a cidr in 172.31.0.0/16 if the primary vpc "\
        "range is in 172.16.0.0/12"],
      ["10.0.0.0/20", "172.31.0.0/18", "should not allow a cidr from a different restricted ranges than "\
        "the range the VPC is in"],
      ["172.17.0.0/24", "192.168.0.0/24", "should not allow a cidr from a different restricted range ranges "\
        "than the range the VPC is in"],
      ["192.168.0.0/16", "172.31.0.0/18", "should not allow a cidr from a different restricted range than "\
        "the range the VPC is in"],
      ["198.19.0.0/16", "172.31.0.0/18", "should not allow a cidr from a different restricted range than "\
        "the range the VPC is in"]
    ].each do |test|
      it test[2] do
        res = GeoEngineer::Resources::AwsVpcIpv4CidrBlockAssociation.allocate()
        errs = res.validate_cidr_restrictions(test[0], test[1])
        expect(errs.length).to eq(1)
      end
    end

    it 'should allow cidr blocks in the 100.64.0.0/10 range' do
      res = GeoEngineer::Resources::AwsVpcIpv4CidrBlockAssociation.allocate()
      errs = res.validate_cidr_restrictions("10.100.0.0/24", "100.96.0.0/16")
      expect(errs.length).to eq(0)
    end
  end

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_vpcs,
        {
          vpcs: [
            {
              vpc_id: 'name1',
              cidr_block: "10.10.0.0/24",
              tags: [{ key: 'Name', value: 'one' }],
              cidr_block_association_set: [
                {
                  association_id: 'cidr_assoc_1',
                  cidr_block: '10.100.240.0/22'
                },
                {
                  association_id: 'cidr_assoc_2',
                  cidr_block: '100.96.0.0/16'
                }
              ]
            },
            {
              vpc_id: 'name2',
              cidr_block: "10.10.1.0/24",
              tags: [{ key: 'Name', value: 'two' }],
              cidr_block_association_set: [
                {
                  association_id: 'cidr_assoc_3',
                  cidr_block: '10.100.184.0/22'
                }
              ]
            }
          ]
        }
      )
      ec2.stub_responses(:describe_vpcs, stub)
    end

    after do
      ec2.stub_responses(:describe_vpcs, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsVpcIpv4CidrBlockAssociation._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(3)
    end
  end
end

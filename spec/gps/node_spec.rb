require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS::Node do
  def build_test_node(name: "tn", attrs: {})
    GeoEngineer::GPS::Nodes::TestNode.new("p1", "e1", "c1", name, attrs)
  end

  let(:test_node) { build_test_node }

  describe '#build_node_type' do
    it 'returns the node type based on class name' do
      expect(test_node.build_node_type).to eq "test_node"
    end
  end

  describe '#validate' do
    it 'validates agains the json schema' do
      expect(build_test_node({ attrs: { "name" => "value" } }).validate()).to eq true
    end

    it 'raises an error on bad validation' do
      expect {
        build_test_node({ attrs: { "unknwon" => "value" } }).validate()
      }.to raise_error(GeoEngineer::GPS::Node::NodeError)
    end

    it "sets the default values" do
      test_node = build_test_node()
      test_node.validate()
      expect(test_node.attributes["name"]).to eq "default"
    end
  end

  describe '#define_resource' do
    it 'can create the resources' do
      expect(test_node).to respond_to(:create_elb)
    end

    it 'can get the geo resource' do
      expect(test_node).to respond_to(:elb)
    end

    it 'can get a reference to the resource' do
      expect(test_node).to respond_to(:elb_ref)
    end
  end

  describe '#where_all' do
    it 'returns all nodes with list of queries' do
      t1 = build_test_node({ name: "t1" })
      t2 = build_test_node({ name: "t2" })
      t1.all_nodes = [t1, t2]

      res = t1.where_all(["*:*:*:test_node:t1", "*:*:*:test_node:t2"])
      expect(res.length).to eq 2
      expect(res).to include(t1)
      expect(res).to include(t2)
    end
  end

  describe '#where' do
    it 'returns with defaults' do
      t1 = build_test_node({ name: "t1" })
      t2 = build_test_node({ name: "t2" })
      t1.all_nodes = [t1, t2]
      res = t1.where("*:*:*:test_node:*")
      expect(res.length).to eq 2
      expect(res).to include(t1)
      expect(res).to include(t2)

      res = t1.where("*:*:*:test_node:t1")
      expect(res.length).to eq 1
      expect(res).to include(t1)
    end
  end

  describe '#find' do
    it 'returns a single node' do
      t1 = build_test_node({ name: "t1" })
      t2 = build_test_node({ name: "t2" })
      t1.all_nodes = [t1, t2]

      expect(t1.find("*:*:*:test_node:t2")).to eq t2

      expect {
        t1.find("*:*:*:test_node:*")
      }.to raise_error(GeoEngineer::GPS::Finder::NotUniqueError)

      expect {
        t1.find("*:*:*:test_node:3")
      }.to raise_error(GeoEngineer::GPS::Finder::NotFoundError)
    end
  end
end

require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS do
  let(:n0) { GeoEngineer::GPS::Node.new("p0", "e1", "c1", "n1", {}) }
  let(:n1) { GeoEngineer::GPS::Node.new("p1", "e1", "c1", "n1", {}) }
  let(:n2) { GeoEngineer::GPS::Node.new("p1", "e2", "c1", "n1", {}) }
  let(:n3) { GeoEngineer::GPS::Node.new("p1", "e2", "c2", "n1", {}) }
  let(:n4) { GeoEngineer::GPS::Node.new("p1", "e2", "c2", "n2", {}) }
  let(:nodes) { [n0, n1, n2, n3, n4] }

  describe "class methods" do
    describe '#remove_' do
      it 'removes keys from a hash that start with _' do
        expect(GeoEngineer::GPS.remove_({ "_asd" => :value })).to eq({})
      end
    end

    describe 'deep_dup' do
      it 'returns a hash that is deep duped' do
        a = {}
        b = { "a" => a }
        x = GeoEngineer::GPS.deep_dup(b)
        expect(x.object_id).to_not eq b.object_id
        expect(x["a"]).to_not eq a.object_id
      end
    end

    describe 'where' do
      it 'returns nodes from project' do
        expect(GeoEngineer::GPS.where(nodes, "p0:*:*:*:*")).to eq [n0]
      end

      it 'returns nodes from environment' do
        expect(GeoEngineer::GPS.where(nodes, "p1:e1:*:*:*")).to eq [n1]
      end

      it 'returns nodes from config' do
        expect(GeoEngineer::GPS.where(nodes, "p1:e2:c1:*:*")).to eq [n2]
      end

      it 'returns nodes of type' do
        expect(GeoEngineer::GPS.where(nodes, "p1:e2:c2:node:*")).to eq [n3, n4]
      end

      it 'returns nodes of name' do
        expect(GeoEngineer::GPS.where(nodes, "p1:e2:c2:node:n2")).to eq [n4]
      end

      it 'returns multiple nodes' do
        expect(GeoEngineer::GPS.where(nodes, "*:e1:*:*:*")).to eq [n0, n1]
      end
    end

    describe 'find' do
      it 'errors if no node is found' do
        expect { GeoEngineer::GPS.find(nodes, "p3:e1:*:*:*") }.to raise_error GeoEngineer::GPS::NotFoundError
      end

      it 'error if multiple nodes are found' do
        expect { GeoEngineer::GPS.find(nodes, "p1:*:*:*:*") }.to raise_error GeoEngineer::GPS::NotUniqueError
      end

      it 'returns a single node' do
        expect(GeoEngineer::GPS.find(nodes, "p1:e2:c2:node:n2")).to eq n4
      end
    end
  end

  describe '#initialize' do
    it 'works with no input' do
      GeoEngineer::GPS.new({})
    end

    it 'should init and build nodes' do
      g = GeoEngineer::GPS.new({
                                 "p1" => { "e1" => { "c1" => { "test_node" => { "n1" => {} } } } }
                               })
      expect(g.nodes.first.node_id).to eq "p1:e1:c1:test_node:n1"
    end

    it 'should expand meta_nodes' do
      g = GeoEngineer::GPS.new({
                                 "p1" => { "e1" => { "c1" => { "test_meta_node" => { "n1" => {} } } } }
                               })
      expect(g.nodes.length).to eq 2
      expect(g.where("p1:e1:c1:test_meta_node:n1").length).to eq 1
      expect(g.where("p1:e1:c1:test_node:n1").length).to eq 1
    end
  end

  describe '#expanded_hash' do
    it 'builds a hash of all nodes' do
      h = { "p1" => { "e1" => { "c1" => { "test_node" => { "n1" => {} } } } } }
      g = GeoEngineer::GPS.new(h)

      # includes default values
      eh = { "p1" => { "e1" => { "c1" => { "test_node" => { "n1" => { "name" => "default" } } } } } }
      expect(g.expanded_hash).to eq(eh)
    end
  end

  describe '#create_project' do
    it 'creates node resources' do
      h = { "org/p1" => { "e1" => { "c1" => { "test_node" => { "n1" => { "name" => "asd" } } } } } }
      g = GeoEngineer::GPS.new(h)

      called = false
      g.create_project("org", "p1", GeoEngineer::Environment.new("e1")) do |project, config, nodes|
        called = true
        expect(config).to eq "c1"
        expect(project.full_name).to eq "org/p1"
        expect(nodes.find(":::test_node:n1").attributes["name"]).to eq "asd"
      end

      expect(called).to eq true
    end
  end
end

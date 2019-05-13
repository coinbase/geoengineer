require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS::Finder do
  let(:n0) { GeoEngineer::GPS::Node.new("p0", "e1", "c1", "n1", {}) }
  let(:n1) { GeoEngineer::GPS::Node.new("p1", "e1", "c1", "n1", {}) }
  let(:n2) { GeoEngineer::GPS::Node.new("p1", "e2", "c1", "n1", {}) }
  let(:n3) { GeoEngineer::GPS::Node.new("p1", "e2", "c2", "n1", {}) }
  let(:n4) { GeoEngineer::GPS::Node.new("p1", "e2", "c2", "n2", {}) }
  let(:nodes) { [n0, n1, n2, n3, n4] }

  let(:finder) { described_class.new(nodes, nil) }

  describe 'where' do
    it 'returns nodes from project' do
      expect(finder.where("p0:*:*:*:*")).to eq [n0]
    end

    it 'returns nodes from environment' do
      expect(finder.where("p1:e1:*:*:*")).to eq [n1]
    end

    it 'returns nodes from config' do
      expect(finder.where("p1:e2:c1:*:*")).to eq [n2]
    end

    it 'returns nodes of type' do
      expect(finder.where("p1:e2:c2:node:*")).to eq [n3, n4]
    end

    it 'returns nodes of name' do
      expect(finder.where("p1:e2:c2:node:n2")).to eq [n4]
    end

    it 'returns multiple nodes' do
      expect(finder.where("*:e1:*:*:*")).to eq [n0, n1]
    end
  end

  describe 'find' do
    it 'errors if no node is found' do
      expect { finder.find("p3:e1:*:*:*") }.to raise_error GeoEngineer::GPS::Finder::NotFoundError
    end

    it 'error if multiple nodes are found' do
      expect { finder.find("p1:*:*:*:*") }.to raise_error GeoEngineer::GPS::Finder::NotUniqueError
    end

    it 'returns a single node' do
      expect(finder.find("p1:e2:c2:node:n2")).to eq n4
    end
  end

  describe "with context" do
    it 'replaces project' do
      finder = described_class.new(nodes, nil, { project: "p0" })
      expect(finder.where(":*:*:*:*")).to eq [n0]
    end

    it 'replaces environment' do
      finder = described_class.new(nodes, nil, { environment: "e1" })
      expect(finder.where("*::*:*:*")).to eq [n0, n1]
    end

    it 'replaces configuration' do
      finder = described_class.new(nodes, nil, { configuration: "c2" })
      expect(finder.where("*:*::*:*")).to eq [n3, n4]
    end

    it 'replaces node_name' do
      finder = described_class.new(nodes, nil, { node_name: "n2" })
      expect(finder.where("*:*:*:*:")).to eq [n4]
    end
  end

  describe 'NODE_REFERENCE_SYNTAX' do
    describe 'enforces the reference syntax' do
      nonvalid_references = [
        "valid:valid:valid:valid:valid",
        ":::type:name",
        "project:environment:configuration:type:*",
        "*:*:*:type:*",
        "arn:aws:s3:::app-access-logs",                     # An actual ARN
        "arn:aws:for:bar:baz",                              # Something that looks like an ARN
        "::::",                                             # no name or type
        "project:environment:configuration::name",          # No type
        "project:environment:configuration:*:*",            # * for type
        "project:environment:configuration:type:",          # No name
        "foobarbaz",                                        # Random non matching string
        "valid:valid:valid:valid:valid#",                   # # with no resource
        "valid:valid:valid:valid:valid#valid.",             # . with no attribute
        "valid:valid:valid:valid:valid#.valid",             # no resource
        "valid:valid:valid:valid:valid#valid.valid.invalid" # Nested attribute
      ]

      valid_references = [
        ":::node_type:node-name#resource_name.attribute_name",
        "org/project:env:config:node_type:node-name.blah#resource_name.attribute_name",
        "valid:valid:valid:valid:valid#valid",
        "valid:valid:valid:valid:valid#valid.valid"
      ]

      nonvalid_references.each do |ref|
        it "be invalid for #{ref}" do
          expect(ref =~ GeoEngineer::GPS::Finder::NODE_REFERENCE_SYNTAX).to be_nil
        end
      end

      valid_references.each do |ref|
        it "be valid for #{ref}" do
          expect(ref =~ GeoEngineer::GPS::Finder::NODE_REFERENCE_SYNTAX).to eq(0)
        end
      end
    end

    it 'sets named capture group to nil if not found' do
      components = "valid:valid:valid:valid:valid#valid".match(GeoEngineer::GPS::Finder::NODE_REFERENCE_SYNTAX)
      expect(components["resource"]).to_not be_nil
      expect(components["attribute"]).to be_nil
    end
  end

  describe 'CONSTANT_REFERENCE_SYNTAX' do
    describe 'enforces the reference syntax' do
      nonvalid_references = [
        "constants:::",
        ":::type:name"
      ]

      valid_references = [
        "constant:development:private_api"
      ]

      nonvalid_references.each do |ref|
        it "be invalid for #{ref}" do
          expect(ref =~ GeoEngineer::GPS::Finder::CONSTANT_REFERENCE_SYNTAX).to be_nil
        end
      end

      valid_references.each do |ref|
        it "be valid for #{ref}" do
          expect(ref =~ GeoEngineer::GPS::Finder::CONSTANT_REFERENCE_SYNTAX).to eq(0)
        end
      end
    end
  end

  describe 'CONTEXT_REFERENCE_SYNTAX' do
    describe 'enforces the reference syntax' do
      nonvalid_references = [
        "context::",
        ":project",
        "context:",
        "context:project:"
      ]

      valid_references = [
        "context:project",
        "context:environment",
        "context:configuration",
        "context:node_type",
        "context:node_name"
      ]

      nonvalid_references.each do |ref|
        it "be invalid for #{ref}" do
          expect(ref =~ GeoEngineer::GPS::Finder::CONTEXT_REFERENCE_SYNTAX).to be_nil
        end
      end

      valid_references.each do |ref|
        it "be valid for #{ref}" do
          expect(ref =~ GeoEngineer::GPS::Finder::CONTEXT_REFERENCE_SYNTAX).to eq(0)
        end
      end
    end
  end

  describe 'searching' do
    let(:n1) { GeoEngineer::GPS::Nodes::TestNode.new("p1", "e1", "c1", "n1", {}) }
    let(:n2) { GeoEngineer::GPS::Nodes::TestNode.new("p2", "e1", "c1", "n1", {}) }
    let(:n3) { GeoEngineer::GPS::Nodes::TestNode.new("p2", "e2", "c2", "n1", {}) }
    let(:n4) { GeoEngineer::GPS::Nodes::TestNode.new("p2", "e2", "c2", "n2", {}) }
    let(:nodes) { [n1, n2, n3, n4] }
    let(:constants) {
      GeoEngineer::GPS::Constants.new({
                                        "e1": { "override": "no" }, "_global": { "test": "hello", "override": "yes" }
                                      }) }
    let(:context) { { project: "p1", environment: "e1", configuration: "c1", node_type: "test_node" } }
    let(:finder) { described_class.new(nodes, constants, context) }

    context 'dereference' do
      it 'returns the designated resource ref' do
        expect(finder.dereference("*:*:*:test_node:*#elb")).to eq(nodes.map(&:elb_ref))
        expect(finder.dereference("p1:*:*:test_node:*#elb")).to eq([n1.elb_ref])
        expect(finder.dereference("p2:*:*:test_node:*#elb")).to eq([n2, n3, n4].map(&:elb_ref))
        expect(finder.dereference("p2:e2:c2:test_node:n2#elb")).to eq([n4.elb_ref])
      end

      it 'returns the designated relative resource ref' do
        expect(finder.dereference(":::test_node:*#elb")).to eq([n1.elb_ref])
      end

      it 'returns correct constants' do
        expect(finder.dereference("constant:e1:test")).to eq(["hello"])
        expect(finder.dereference("constant:e1:override")).to eq(["no"])
      end

      it 'returns the correct context' do
        expect(finder.dereference("context:project")).to eq(["p1"])
        expect(finder.dereference("context:environment")).to eq(["e1"])
        expect(finder.dereference("context:configuration")).to eq(["c1"])
        expect(finder.dereference("context:node_type")).to eq(["test_node"])
      end

      it 'returns the designated resource attribute ref' do
        expect(finder.dereference("*:*:*:test_node:*#elb.arn"))
          .to eq(nodes.map { |n| n.elb_ref("arn") })
        expect(finder.dereference("p1:*:*:test_node:*#elb.arn"))
          .to eq([n1.elb_ref("arn")])
        expect(finder.dereference("p2:*:*:test_node:*#elb.arn"))
          .to eq([n2, n3, n4].map { |n| n.elb_ref("arn") })
        expect(finder.dereference("p2:e2:c2:test_node:n2#elb.arn"))
          .to eq([n4.elb_ref("arn")])
      end

      it 'returns an empty array if no matching nodes are found' do
        expect(finder.dereference("p3:*:*:test_node:*#elb.arn")).to eq([])
      end

      it 'errors if the resource does not exist' do
        expect { finder.dereference("p2:*:*:test_node:*#security_group.arn") }
          .to raise_error(GeoEngineer::GPS::Finder::BadReferenceError)
      end

      it 'errors if the context is unavailable or incorrect' do
        expect { finder.dereference("context:node_name") }
          .to raise_error(GeoEngineer::GPS::Finder::NotFoundError)

        expect { finder.dereference("context:asd") }
          .to raise_error(GeoEngineer::GPS::Finder::BadReferenceError)
      end
    end

    describe 'dereference!' do
      it 'raises error if nothing found' do
        expect { finder.dereference!("constant:e1:nope") }
          .to raise_error(GeoEngineer::GPS::Finder::NotFoundError)
      end

      it 'raises error if more than one thing found' do
        expect { finder.dereference!("p2:*:*:test_node:*#elb") }
          .to raise_error(GeoEngineer::GPS::Finder::NotUniqueError)
      end
    end
  end
end

require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS::YamlTag do
  let(:n0) { GeoEngineer::GPS::Nodes::TestNode.new("p", "e", "c", "n", {}) }
  let(:nodes) { [n0] }
  let(:constants) { GeoEngineer::GPS::Constants.new({ "e": { "here": "hello" } }) }

  context '!ref' do
    it 'replaces constant' do
      yaml = YAML.load('test: !ref constant:e:here')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "hello"
    end

    it 'replaces node with terraform id or arn' do
      yaml = YAML.load('test: !ref p:e:c:test_node:n#elb')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.id}"

      yaml = YAML.load('test: !ref p:e:c:test_node:n#elb.arn')
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { nodes: nodes, constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
    end

    context 'context' do
      it 'replaces project' do
        yaml = YAML.load('test: !ref :e:c:test_node:n#elb.arn')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { project: "p" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
      end

      it 'replaces env for constant' do
        yaml = YAML.load('test: !ref constant::here')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { environment: "e" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "hello"
      end

      it 'replaces env for node' do
        yaml = YAML.load('test: !ref p::c:test_node:n#elb.arn')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { environment: "e" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
      end

      it 'replaces config' do
        yaml = YAML.load('test: !ref p:e::test_node:n#elb.arn')
        GeoEngineer::GPS::YamlTag.add_tag_context(yaml, {
                                                    nodes: nodes, constants: constants, context: { configuration: "c" }
                                                  })
        expect(HashUtils.json_dup(yaml)["test"]).to eq "${aws_elb.elb_p_c_test_node_n.arn}"
      end
    end
  end

  context '!flatten' do
    it 'flattens a list' do
      yaml = YAML.load("test: !flatten
        - 1
        - - 2
      ")
      expect(HashUtils.json_dup(yaml)["test"]).to eq [1, 2]
    end

    it 'replaces internal refs first' do
      yaml = YAML.load("test: !flatten
        - !ref constant:e:here
        - - !ref constant:e:here
        - !ref constant:e:here
      ")
      GeoEngineer::GPS::YamlTag.add_tag_context(yaml, { constants: constants })
      expect(HashUtils.json_dup(yaml)["test"]).to eq ["hello", "hello", "hello"]
    end
  end
end

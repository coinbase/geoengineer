require_relative '../spec_helper'

describe("HasValidations") do
  it "should work" do
    class InValid
      include HasValidations
      validate -> { "ERROR MESSAGE" }
    end

    class Valid
      include HasValidations
      validate -> { nil }
    end

    valid   = Valid.new().errors
    invalid = InValid.new().errors
    expect(valid.length).to eq 0
    expect(invalid.length).to eq 1
  end

  it "should include suberclass validations" do
    class Super
      include HasValidations
      validate -> { "super" }
    end

    class Sub < Super
      validate -> { "sub" }
    end

    errs = Sub.new().errors
    expect(errs).to include('sub')
    expect(errs).to include('super')
  end

  describe "#validate_at_least_one_present" do
    it "checks that at least of the specified attributes is defined" do
      class Subject < GeoEngineer::Resource
        include HasValidations
        validate -> {
          validate_at_least_one_present([:foo, :bar, :baz])
        }

        def _terraform_id
          'id'
        end
      end

      valid = Subject.new('subject', 'id') { foo("quack") }
      expect(valid.errors).to be_empty

      invalid = Subject.new('subject', 'id') { qux("quack") }
      expect(invalid.errors).to_not be_empty
    end
  end

  describe "#validate_at_least_one_present" do
    it "checks that at least of the specified attributes is defined" do
      class Subject2 < GeoEngineer::Resource
        include HasValidations
        validate -> {
          validate_only_one_present([:foo, :bar, :baz])
        }

        def _terraform_id
          'id'
        end
      end

      valid = Subject2.new('subject', 'id') { foo("quack") }
      expect(valid.errors).to be_empty

      invalid = Subject2.new('subject', 'id') {
        foo("quack")
        bar("meow")
      }
      expect(invalid.errors).to_not be_empty
    end
  end

  describe "#validate_policy_length" do
    it "enforces AWS policy size limits" do
      class Subject3 < GeoEngineer::Resource
        include HasValidations
        validate -> {
          validate_policy_length(self.policy)
        }

        def _terraform_id
          'id'
        end
      end
      invalid = Subject3.new('subject', 'id') { policy("abcdefgh" * 64 * 11) }
      expect(invalid.errors).to_not be_empty

      valid = Subject3.new('subject', 'id') { policy("abcdefgh" * 64 * 9) }
      expect(valid.errors).to be_empty
    end
  end
end

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
end

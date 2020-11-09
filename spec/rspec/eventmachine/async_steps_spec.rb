require "spec_helper"

describe RSpec::EM::AsyncSteps do
  StepModule = RSpec::EM.async_steps do
    def multiply(x, y, &resume)
      EM.add_timer(0.1) do
        @result = x * y
        resume.call
      end
    end
    
    def subtract(n, &resume)
      EM.add_timer(0.1) do
        @result -= n
        resume.call
      end
    end
    
    def check_result(n, &resume)
      @result.should == n
      @checked = true
      resume.call
    end
  end
  
  before do
    @steps = Class.new { include StepModule }.new
  end
  
  def result
    @steps.instance_eval { @result }
  end
  
  describe :sync do
    describe "with no steps pending" do
      it "does not block" do
        result.should == nil
      end
    end
    
    describe "with a pending step" do
      before { EM.run { @steps.multiply 7, 8 } }
      
      it "waits for the step to complete" do
        result.should == 56
      end
    end
    
    describe "with many pending steps" do
      before do
        EM.run {
          @steps.multiply 7, 8
          @steps.subtract 5
        }
      end
      
      it "waits for all the steps to complete" do
        result.should == 51
      end
    end
    
    describe "with FakeClock activated" do
      include RSpec::EM::FakeClock
      after { clock.reset }
      
      it "waits for all the steps to complete" do
        @steps.instance_eval { @result = 11 }
        EM.run {
          clock.stub
          @steps.check_result(11)
        }
        @steps.instance_eval { @checked }.should == true
      end
    end
  end
  
  describe "RSpec example" do
    include StepModule
    
    it "passes" do
      multiply 6, 3
      subtract 7
      check_result 11
    end

    it "raises if spec is interrupted" do
      multiply 6, 3
      subtract 7
      check_result 25 # wrong value
      EM.stop
    end

    it "do not raise if interrupted with no queue" do
      EM.stop
    end
  end
end


module EM
  module RSpec
    
    ROOT = File.expand_path(File.dirname(__FILE__))
    autoload :FakeClock, ROOT + '/em-rspec/fake_clock'
    
  end
end


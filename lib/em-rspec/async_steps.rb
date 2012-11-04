module EM::RSpec
  class AsyncSteps < Module
    
    def included(klass)
      klass.__send__(:include, Scheduler)
    end
    
    def method_added(method_name)
      async_method_name = "async_#{method_name}"
      return if instance_methods(false).map { |m| m.to_s }.include?(async_method_name) or
                method_name.to_s =~ /^async_/
      
      module_eval <<-RUBY
        alias :#{async_method_name} :#{method_name}
        def #{method_name}(*args)
          __enqueue__([#{async_method_name.inspect}] + args)
        end
      RUBY
    end
    
    module Scheduler
      def __enqueue__(args)
        @__step_queue__ ||= []
        @__step_queue__ << args
        return if @__running_steps__
        @__running_steps__ = true
        EM.next_tick { __run_next_step__ }
      end
      
      def __run_next_step__
        step = @__step_queue__.shift
        return EM.stop unless step
        
        method_name, args = step.shift, step
        begin
          method(method_name).call(*args) { __run_next_step__ }
        rescue Object => e
          @example.set_exception(e) if @example
          __end_steps__
        end
      end
      
      def __end_steps__
        @__step_queue__ = []
        __run_next_step__
      end
    end
    
  end
end

class RSpec::Core::Example
  hook_method = %w[with_around_hooks with_around_each_hooks].find { |m| instance_method(m) rescue nil }
  
  class_eval %Q{
    alias :synchronous_run :#{hook_method}
    
    def #{hook_method}(*args, &block)
      if @example_group_instance.is_a?(EM::RSpec::AsyncSteps::Scheduler)
        EM.run { synchronous_run(*args, &block) }
      else
        synchronous_run(*args, &block)
      end
    end
  }
end


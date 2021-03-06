require File.expand_path('../../test_helper.rb', __FILE__)
require File.expand_path('../memory_profiler.rb', __FILE__)

class MemoryProfilerTest < Test::Unit::TestCase
    # Stub the plugin instance where necessary and run
    # @plugin=PluginName.new(last_run, memory, options)
    #                        date      hash    hash
    def test_success_linux
      @plugin=MemoryProfiler.new(nil,{},{})
      @plugin.expects(:`).with("cat /proc/meminfo").returns(File.read(File.dirname(__FILE__)+'/fixtures/proc_meminfo.txt')).once
      @plugin.expects(:`).with("uname").returns('Linux').once

      res = @plugin.run()
      
      assert res[:errors].empty?
      assert !res[:memory][:solaris]
      assert_equal 6, res[:reports].first.keys.size
      
      r = res[:reports].first
      assert_equal 0, r["Swap Used"]
      assert_equal 255, r["Swap Total"]
      assert_equal 25, r["% Memory Used"]
      assert_equal 0, r["% Swap Used"]
      assert_equal 264, r["Memory Used"]
      assert_equal 1024, r["Memory Total"]
    end
    
    def test_success_linux_second_run
      # shouldn't run uname again as it is stored in memory
      @plugin=MemoryProfiler.new(Time.now-60*10,{:solaris=>false},{})
      @plugin.expects(:`).with("cat /proc/meminfo").returns(File.read(File.dirname(__FILE__)+'/fixtures/proc_meminfo.txt')).once
      @plugin.expects(:`).with("uname").returns('Linux').never

      res = @plugin.run()
      assert_equal false,res[:memory][:solaris]
    end
    
    def test_success_solaris
      @plugin=MemoryProfiler.new(nil,{},{})
      @plugin.expects(:`).with("prstat -c -Z 1 1").returns(File.read(File.dirname(__FILE__)+'/fixtures/prstat.txt')).once
      @plugin.expects(:`).with("/usr/sbin/prtconf | grep Memory").returns(File.read(File.dirname(__FILE__)+'/fixtures/prtconf.txt')).once
      @plugin.expects(:`).with("swap -s").returns(File.read(File.dirname(__FILE__)+'/fixtures/swap.txt')).once
      @plugin.expects(:`).with("uname").returns('SunOS').once

      res = @plugin.run()
      
      assert res[:errors].empty?
      assert res[:memory][:solaris]
      
      assert_equal 6, res[:reports].first.keys.size

      r = res[:reports].first
      assert_equal 1388, r["Swap Used"]
      assert_equal 2124.1, r["Swap Total"]
      assert_equal (1388/2124.to_f*100).to_i, r["% Swap Used"]
      assert_equal 2, r["% Memory Used"]
      assert_equal 872, r["Memory Used"]
      assert_equal 32763, r["Memory Total"]
    end
    
    def test_success_solaris_second_run
      @plugin=MemoryProfiler.new(Time.now-60*10,{:solaris=>true},{})
      @plugin.expects(:`).with("prstat -c -Z 1 1").returns(File.read(File.dirname(__FILE__)+'/fixtures/prstat.txt')).once
      @plugin.expects(:`).with("/usr/sbin/prtconf | grep Memory").returns(File.read(File.dirname(__FILE__)+'/fixtures/prtconf.txt')).once
      @plugin.expects(:`).with("swap -s").returns(File.read(File.dirname(__FILE__)+'/fixtures/swap.txt')).once
      @plugin.expects(:`).with("uname").returns('SunOS').never

      res = @plugin.run()
      assert_equal true,res[:memory][:solaris]
    end
    
    def test_success_solaris_with_gb_swap_units
      @plugin=MemoryProfiler.new(nil,{},{})
      @plugin.expects(:`).with("prstat -c -Z 1 1").returns(File.read(File.dirname(__FILE__)+'/fixtures/prstat.txt')).once
      @plugin.expects(:`).with("/usr/sbin/prtconf | grep Memory").returns(File.read(File.dirname(__FILE__)+'/fixtures/prtconf.txt')).once
      @plugin.expects(:`).with("swap -s").returns(File.read(File.dirname(__FILE__)+'/fixtures/swap_gb.txt')).once
      @plugin.expects(:`).with("uname").returns('SunOS').once

      res = @plugin.run()
      
      assert res[:errors].empty?
      assert res[:memory][:solaris]
      
      r = res[:reports].first      
      assert_equal 6, r.keys.size

      assert_equal 1388, r["Swap Used"]
      assert_equal 86016, r["Swap Total"]
      assert_equal (1388/86016.to_f*100).to_i, r["% Swap Used"]
      assert_equal 2, r["% Memory Used"]
      assert_equal 872, r["Memory Used"]
      assert_equal 32763, r["Memory Total"]
    end
end
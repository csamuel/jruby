require 'rbconfig'
require 'jruby' if defined?(JRUBY_VERSION)
require 'tempfile'

module TestHelper
  # TODO: Consider how this should work if we have --windows or similiar
  WINDOWS = Config::CONFIG['host_os'] =~ /Windows|mswin/
  SEPARATOR = WINDOWS ? '\\' : '/'
  RUBY = '"' + File.join([Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name']]) << Config::CONFIG['EXEEXT'] + '"'

  if (WINDOWS)
    RUBY.gsub!('/', '\\')
    DEVNULL = 'NUL:'
  else
    DEVNULL = '/dev/null'
  end

  if defined? JRUBY_VERSION
    arch = java.lang.System.getProperty('sun.arch.data.model')
    WINDOWS_JVM_64 = (WINDOWS && arch == '64')
  end

  IBM_JVM = Config::CONFIG['host_vendor'] =~ /IBM Corporation/

  def q
    WINDOWS ? '"' : '\''
  end

  def jruby(*args)
    with_jruby_shell_spawning { `#{RUBY} #{args.join(' ')}` }
  end

  def jruby_with_pipe(pipe, *args)
    with_jruby_shell_spawning { `#{pipe} | #{RUBY} #{args.join(' ')}` }
  end

  def with_temp_script(script, filename="test-script")
    Tempfile.open([filename, ".rb"]) do |f|
      begin
        # we ignore errors writing to the tempfile to ensure the test tries to run
        f.syswrite(script) rescue 1
        return yield f
      ensure
        f.close!
      end
    end
  end

  def with_jruby_shell_spawning
    prev_in_process = JRuby.runtime.instance_config.run_ruby_in_process
    JRuby.runtime.instance_config.run_ruby_in_process = false
    yield
  ensure
    JRuby.runtime.instance_config.run_ruby_in_process = prev_in_process
  end

  def quiet(&block)
    io = [STDOUT.dup, STDERR.dup]
    STDOUT.reopen DEVNULL
    STDERR.reopen DEVNULL
    block.call
  ensure
    STDOUT.reopen io.first
    STDERR.reopen io.last
  end
end

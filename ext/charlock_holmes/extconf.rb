require 'mkmf'

CWD = File.expand_path(File.dirname(__FILE__))
def sys(cmd)
  puts "  -- #{cmd}"
  unless ret = xsystem(cmd)
    raise "#{cmd} failed, please report issue on https://github.com/brianmario/charlock_holmes"
  end
  ret
end

if `which make`.strip.empty?
  STDERR.puts "\n\n"
  STDERR.puts "***************************************************************************************"
  STDERR.puts "*************** make required (apt-get install make build-essential) =( ***************"
  STDERR.puts "***************************************************************************************"
  exit(1)
end

##
# ICU dependency
#

def show_variables()
  puts "Variables de entorno:"
  ENV.each do |key, value|
    puts "#{key} = #{value}"
  end
  puts "Variables de instancia:"
  instance_variables.each do |var|
    puts "#{var}: #{instance_variable_get(var)}"
  end
end

puts("paso 1")
dir_config 'icu'

rubyopt = ENV.delete("RUBYOPT")

icuconfig = ""
icu4c = "/usr"
# detect homebrew installs

puts("paso 2")
if !have_library 'icui18n'
  puts("paso 3")
  base = if !`which brew`.empty?
    `brew --cellar`.strip
  elsif File.exists?("/usr/local/Cellar/icu4c")
    '/usr/local/Cellar'
  end
  puts("paso 4")
  show_variables()
  if base and icu4c = Dir[File.join(base, 'icu4c/*')].sort.last
    puts("paso 5")
    $INCFLAGS << " -I#{icu4c}/include "
    $LDFLAGS  << " -L#{icu4c}/lib "
    icuconfig = "#{icu4c}/bin/icu-config"
  end
end
puts("paso 6")
unless have_library 'icui18n' and have_header 'unicode/ucnv.h'
  STDERR.puts "\n\n"
  STDERR.puts "***************************************************************************************"
  STDERR.puts "*********** icu required (brew install icu4c or apt-get install libicu-dev) ***********"
  STDERR.puts "***************************************************************************************"
  exit(1)
end
puts("paso 7")
have_library 'z' or abort 'libz missing'
have_library 'icuuc' or abort 'libicuuc missing'
have_library 'icudata' or abort 'libicudata missing'
puts("paso 8")
# icu4c might be built in C++11 mode, but it also might not have been
icuconfig = `which icu-config`.chomp if icuconfig.empty?
if File.exist?(icuconfig) && `#{icuconfig} --cxxflags`.include?("c++11")
  $CXXFLAGS << ' -std=c++11'
end
puts("paso 9")
$CFLAGS << ' -Wall -funroll-loops'
$CFLAGS << ' -Wextra -O0 -ggdb3' if ENV['DEBUG']
puts("paso 10")
ENV['RUBYOPT'] = rubyopt
create_makefile 'charlock_holmes/charlock_holmes'

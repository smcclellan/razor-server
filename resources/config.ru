# -*- ruby -*-
# rack.version: ~>1.6.1
# The comment above fails because that version of rack is not present
# in the jruby-rack JAR file. Need some way to add the application's
# gem to the path used by jruby-rack.
# See https://github.com/jruby/jruby-rack#initialization
require File::join(File::dirname(__FILE__), '../src/ruby/app')

run Razor::App.new

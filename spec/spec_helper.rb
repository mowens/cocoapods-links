ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)

require 'cocoapods'
require 'cocoapods_plugin'

require 'mocha'
require 'mocha-on-bacon'

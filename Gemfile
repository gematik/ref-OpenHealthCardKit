source "https://rubygems.org"

ruby "4.0.6"

gem "fastlane", "~>2.213"
gem "jazzy", "~>0.13"
gem "mustache", "1.1.1" # jazzy theme_directory= breaks on mustache >=1.1.2 (Pathname#map)
gem "xcodeproj", "~>1.7"
gem "xcode-install", "~> 2.6.6"
gem "asciidoctor-reducer" 

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

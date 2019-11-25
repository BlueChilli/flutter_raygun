#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'raygun'
  s.version          = '0.0.1'
  s.summary          = 'raygun plugin'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://www.bluechilli.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BlueChilli' => 'hello@bluechilli.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'Raygun4iOS'

  s.ios.deployment_target = '8.0'
  s.swift_versions = ['4.0', '4.2', '5.0'] 
end


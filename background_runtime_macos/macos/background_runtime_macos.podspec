Pod::Spec.new do |s|
  s.name             = 'background_runtime_macos'
  s.version          = '0.1.0'
  s.summary          = 'macOS implementation of the background_runtime plugin.'
  s.description      = <<-DESC
  macOS implementation of the background_runtime plugin for long-running background execution.
                       DESC
  s.homepage         = 'https://github.com/mixin27/background_runtime'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'mixin27' => 'hello@mixin27.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'background_runtime_macos/Sources/background_runtime_macos/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'
end

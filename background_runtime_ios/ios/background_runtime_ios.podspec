Pod::Spec.new do |s|
  s.name             = 'background_runtime_ios'
  s.version          = '0.1.0'
  s.summary          = 'iOS implementation of the background_runtime plugin.'
  s.description      = <<-DESC
  iOS implementation of the background_runtime plugin for long-running background execution.
                       DESC
  s.homepage         = 'https://github.com/mixin27/background_runtime'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'mixin27' => 'hello@mixin27.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'background_runtime_ios/Sources/background_runtime_ios/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end

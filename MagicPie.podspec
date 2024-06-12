Pod::Spec.new do |s|
  s.name         = "MagicPie"
  s.version      = "1.1.3"
  s.summary      = "Powerfull pie layer for creating your own pie view"
  s.homepage     = "https://github.com/AlexandrGraschenkov/MagicPie"
  s.license      = "MIT"
  s.author       = { "Alexandr Graschenkov" => "alexandr.graschenkov91@gmail.com" }
  s.platform     = :ios, '12.0'
  s.source       = { :git => "https://github.com/AlexandrGraschenkov/MagicPie.git", :tag => "1.1.3" }
  s.source_files  = 'MagicPieLayer', 'MagicPieLayer/**/*.{h,m}'
  s.resource_bundles = {"MagicPieLayer" => ["MagicPieLayer/PrivacyInfo.xcprivacy"]}
  s.requires_arc = true
end

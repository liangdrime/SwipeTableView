Pod::Spec.new do |s|

  s.name         = "SwipeTableView"
  s.version      = "0.2.6"
  s.summary      = "A swipe view with tableview oc iOS."
  s.description  = <<-DESC
It is a swipe view with tableview items,so it support scroll vertical and horizontal.It's used just like a tableview to set header or swithcbar. 
                   DESC

  s.homepage     = "https://github.com/Roylee-ML/SwipeTableView"
  # s.screenshots  = "https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShot/screenshot.gif"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "Roylee-ML" => "roylee.stillway@gmail.com" }
  # Or just: s.author    = "Roylee-ML"
  # s.authors            = { "Roylee-ML" => "roylee.stillway@gmail.com" }
  # s.social_media_url   = "http://twitter.com/Roylee-ML"
  # s.platform     = :ios
  s.platform     = :ios, "7.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/Roylee-ML/SwipeTableView.git", :tag => s.version.to_s }


  s.source_files  = "SwipeTableView/SwipeTableView/*.{h,m}"
  # s.public_header_files = "Classes/**/*.h"

  # s.framework  = "UIKit"
  s.frameworks = "Foundation", "UIKit"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"

  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end

EXPORT_DIRECTORY = .

framework:
	swift package generate-xcodeproj --skip-extra-files
	xcodebuild -project UnityVideoCreator.xcodeproj -scheme UnityVideoCreator-Package -configuration Release -sdk iphoneos CONFIGURATION_BUILD_DIR=Build

package:
	cd unitypackage-exporter && $(MAKE) package EXPORT_DIRECTORY=$(abspath $(EXPORT_DIRECTORY))

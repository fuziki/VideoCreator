EXPORT_DIRECTORY = .

framework:
	swift package generate-xcodeproj --skip-extra-files
	xcodebuild \
	'ENABLE_BITCODE=YES' \
	'BITCODE_GENERATION_MODE=bitcode' \
	'OTHER_CFLAGS=-fembed-bitcode' \
	'CONFIGURATION_BUILD_DIR=Build' \
	-project UnityVideoCreator.xcodeproj \
	-scheme UnityVideoCreator-Package \
	-configuration Release \
	-sdk iphoneos 

package:
	cd unitypackage-exporter && $(MAKE) package EXPORT_DIRECTORY=$(abspath $(EXPORT_DIRECTORY))

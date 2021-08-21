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

lint:
	swift run --package-path ./tools swiftlint autocorrect --format
	swift run --package-path ./tools swiftlint

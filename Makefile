BUILD_DIR=Build

framework:
	rm -rf ${BUILD_DIR}
	swift package generate-xcodeproj --skip-extra-files
	xcodebuild \
		'ENABLE_BITCODE=YES' \
		'BITCODE_GENERATION_MODE=bitcode' \
		'OTHER_CFLAGS=-fembed-bitcode' \
		'BUILD_LIBRARY_FOR_DISTRIBUTION=YES' \
		'CONFIGURATION_BUILD_DIR=${BUILD_DIR}' \
		-project UnityVideoCreator.xcodeproj \
		-scheme UnityVideoCreator-Package \
		-configuration Release \
		-sdk iphoneos

xcframework: framework
	xcodebuild -create-xcframework \
		-framework ${BUILD_DIR}/UnityVideoCreator.framework \
		-debug-symbols $(CURDIR)/${BUILD_DIR}/UnityVideoCreator.framework.dSYM \
		-debug-symbols $(CURDIR)/${BUILD_DIR}/*.bcsymbolmap \
		-output ${BUILD_DIR}/UnityVideoCreator.xcframework

lint:
	xcrun --sdk macosx \
		swift run --package-path ./tools swiftlint \
		--config tools/.swiftlint.yml \
		autocorrect --format
	pwd
	xcrun --sdk macosx \
		swift run --package-path ./tools swiftlint \
		--config tools/.swiftlint.yml

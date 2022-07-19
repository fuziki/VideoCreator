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
	xcrun --sdk macosx \
		swift run --package-path ./tools swiftlint \
		--config tools/.swiftlint.yml \
		autocorrect --format
	pwd
	xcrun --sdk macosx \
		swift run --package-path ./tools swiftlint \
		--config tools/.swiftlint.yml

XCODEBUILD := xcodebuild
BUILD_FLAGS = -scheme $(TARGET) -destination $(DESTINATION)

TARGET ?= ZShop-Framework
IOS_VERSION ?= 15.4
IPHONE_NAME ?= iPhone 13 mini
FABRIC_SDK_VERSION ?= 3.12.0
DESTINATION ?= 'platform=iOS Simulator,name=$(IPHONE_NAME),OS=$(IOS_VERSION)'

XCPRETTY :=
ifneq ($(shell type -p xcpretty),)
	XCPRETTY += | xcpretty -c && exit $${PIPESTATUS[0]}
endif

build: dependencies
	$(XCODEBUILD) $(BUILD_FLAGS) $(XCPRETTY)

test:
	$(XCODEBUILD) test $(BUILD_FLAGS) $(XCPRETTY)

test-all:
	TARGET=ZSLib "$(MAKE)" test
	TARGET=ZSAPI "$(MAKE)" test
	TARGET=ZSPrelude "$(MAKE)" test

clean:
	$(XCODEBUILD) clean $(BUILD_FLAGS) $(XCPRETTY)

dependencies: submodules fabric

bootstrap: dependencies
	brew update || brew update
	brew unlink swiftlint || true
	brew unlink bartycrouch || true
	brew unlink fastlane || true
	brew install swiftlint
	brew install bartycrouch
	brew install fastlane
	brew link --overwrite swiftlint
	brew link --overwrite bartycrouch
	brew link --overwrite fastlane

submodules:
	git submodule sync --recursive || true
	git submodule update --init --recursive || true

lint:
	swiftlint lint --reporter json --strict

fabric:
	@if [ ! -d Frameworks/Fabric ]; then \
		echo "Downloading Fabric v$(FABRIC_SDK_VERSION)"; \
		mkdir -p Frameworks/Fabric; \
		curl -N -L -o fabric.zip https://s3.amazonaws.com/kits-crashlytics-com/ios/com.twitter.crashlytics.ios/$(FABRIC_SDK_VERSION)/com.crashlytics.ios-manual.zip; \
		unzip fabric.zip -d Frameworks/Fabric || true; \
		rm fabric.zip; \
	fi
	@if [ -e Frameworks/Fabric/Fabric.framework ]; then \
		echo "Fabric v$(FABRIC_SDK_VERSION) downloaded"; \
	else \
		echo "Failed to download Fabric SDK"; \
		rm -rf Frameworks/Fabric; \
	fi

increment-build:
	agvtool bump -all
	git commit -am "increment build number"
	git push

beta: test-all increment-build
	fastlane beta

.PHONY: build test test-all clean dependencies bootstrap submodules lint fabric increment-build

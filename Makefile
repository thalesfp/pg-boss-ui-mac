PROJECT = BossDesk.xcodeproj
SCHEME = BossDesk
BUILD_DIR = build
DIST_DIR = dist

.PHONY: build release run clean kill dist dmg

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug build

release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release build

run: kill build
	@open "$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -showBuildSettings | grep -m 1 'BUILT_PRODUCTS_DIR' | sed 's/.*= //')/BossDesk.app"

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)

kill:
	@pkill -x BossDesk || true

dist:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		ONLY_ACTIVE_ARCH=NO \
		build
	@mkdir -p $(DIST_DIR)
	@rm -rf "$(DIST_DIR)/BossDesk.app"
	@cp -R "$(BUILD_DIR)/Build/Products/Release/BossDesk.app" "$(DIST_DIR)/"
	@echo "App bundle created at $(DIST_DIR)/BossDesk.app"

dmg: dist
	@rm -f "$(DIST_DIR)/BossDesk.dmg"
	hdiutil create -volname "BossDesk" -srcfolder "$(DIST_DIR)/BossDesk.app" \
		-ov -format UDZO "$(DIST_DIR)/BossDesk.dmg"
	@echo "DMG created at $(DIST_DIR)/BossDesk.dmg"

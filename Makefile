PROJECT = pgboss-ui.xcodeproj
SCHEME = pgboss-ui
BUILD_DIR = build
DIST_DIR = dist

.PHONY: build release run clean kill dist dmg

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug build

release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release build

run: kill build
	@open "$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -showBuildSettings | grep -m 1 'BUILT_PRODUCTS_DIR' | sed 's/.*= //')/pgboss-ui.app"

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)

kill:
	@pkill -x pgboss-ui || true

dist:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		ONLY_ACTIVE_ARCH=NO \
		build
	@mkdir -p $(DIST_DIR)
	@rm -rf "$(DIST_DIR)/pgboss-ui.app"
	@cp -R "$(BUILD_DIR)/Build/Products/Release/pgboss-ui.app" "$(DIST_DIR)/"
	@echo "App bundle created at $(DIST_DIR)/pgboss-ui.app"

dmg: dist
	@rm -f "$(DIST_DIR)/pgboss-ui.dmg"
	hdiutil create -volname "pgboss-ui" -srcfolder "$(DIST_DIR)/pgboss-ui.app" \
		-ov -format UDZO "$(DIST_DIR)/pgboss-ui.dmg"
	@echo "DMG created at $(DIST_DIR)/pgboss-ui.dmg"

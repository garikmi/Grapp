APPLE_ID := $(shell cat ./ids/APPLE_ID)
TEAM_ID := $(shell cat ./ids/TEAM_ID)
APP_SPECIFIC_PASSWORD := $(shell cat ./ids/APP_SPECIFIC_PASSWORD)

exe = Grapp

$(exe).app:
	$(MAKE) -C src FLAGS=-O CFLAGS=-O3 default

container:
	ditto -c -k --keepParent ./src/$(exe).app ./build/$(exe).zip

notarize:
	xcrun notarytool submit ./build/$(exe).zip \
		--apple-id "$(APPLE_ID)" --team-id "$(TEAM_ID)" \
		--password "$(APP_SPECIFIC_PASSWORD)" --wait

staple:
	cd build && \
	ditto -xk $(exe).zip . && \
	rm $(exe).zip && \
	xcrun stapler staple $(exe).app

zip:
	cd build && \
	ditto -c -k --keepParent $(exe).app $(exe).zip

dmg:
	cp background.png build && cd build && \
	create-dmg --volname "$(exe) Installer" --window-size 600 400 \
		--background "background.png" --icon "$(exe).app" 200 170 \
		--app-drop-link 400 170 --icon-size 100 "$(exe).dmg" "$(exe)"
	rm build/background.png

all: $(exe).app container notarize staple zip dmg

status:
	@echo 'xcrun notarytool log "" --apple-id "$(APPLE_ID)" --team-id "$(TEAM_ID)" --password "$(APP_SPECIFIC_PASSWORD)" developer_log.json'

clean:
	rm -rf build

clean-all: clean
	mkdir build
	@$(MAKE) -C src clean-all

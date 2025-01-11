FLAGS = -g
CFLAGS = -g
#-O
MACOS_VERSION = 13.0
SDK = $(shell xcrun --show-sdk-path)
XCODE_PATH = $(shell xcode-select --print-path)

EXEC = Grapp

SRCMODULES = Helpers.swift EditableNSTextField.swift EventMonitor.swift \
	GlobalEventTap.swift PopoverPanel.swift SearchViewController.swift \
	SettingsViewController.swift HotKeyManager.swift \
	KeyDetectorButton.swift PathManager.swift PathsTableCellView.swift \
	ProgramTableViewCell.swift ProgramsTableView.swift ShadowView.swift \
	AppDelegate.swift main.swift
ARMOBJMODULES = $(addprefix ./arm64/,$(SRCMODULES:.swift=.o))
X86OBJMODULES = $(addprefix ./x86_64/,$(SRCMODULES:.swift=.o))

LIBS = 

FRAMEWORKS = -framework AppKit -framework ServiceManagement

# HACK: Target is getting touched because timestamps of the generated
#       object file don't change unless there's an actual change in the
#       outputted object code. This results in this target running every
#       single time. I'm not sure whether that's the exact reason, but
#       I can't imagine why timestamps wouldn't change. When clang
#       generates same exact executable, timestamps do change.
./arm64/%.o: %.swift
	swift -frontend -c -target arm64-apple-macos$(MACOS_VERSION) $(FLAGS) \
		-primary-file $< $(filter-out $<, $(SRCMODULES)) $(LIBS) \
		$(FRAMEWORKS) -sdk $(SDK) -module-name $(EXEC) -o $@ \
		-emit-module && touch $@

ifdef UNIVERSAL
./x86_64/%.o: %.swift
	@swift -frontend -c -target x86_64-apple-macos$(MACOS_VERSION) \
		$(FLAGS) -primary-file $< $(filter-out $<, $(SRCMODULES)) \
		$(LIBS) $(FRAMEWORKS) -sdk $(SDK) -module-name $(EXEC) -o $@ \
		-emit-module && touch $@
endif

./arm64/$(EXEC): $(ARMOBJMODULES)
	@ld -syslibroot $(SDK) -lSystem $(FRAMEWORKS) -arch arm64 \
		-macos_version_min $(MACOS_VERSION).0 \
		/Library/Developer/CommandLineTools/usr/lib/swift/macosx/libswiftCompatibilityPacks.a \
		-sectcreate __TEXT __info_plist Info.plist \
		-L /Library/Developer/CommandLineTools/usr/lib/swift/macosx -L \
		/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/swift \
		-no_objc_category_merging -L $(XCODE_PATH) -rpath \
		Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx \
		./arm64/main.o $(filter-out ./arm64/main.o, $(ARMOBJMODULES)) \
		-o $@

ifdef UNIVERSAL
./x86_64/$(EXEC): $(X86OBJMODULES)
	@ld -syslibroot $(SDK) -lSystem $(FRAMEWORKS) -arch x86_64 \
		-macos_version_min $(MACOS_VERSION).0 \
		/Library/Developer/CommandLineTools/usr/lib/swift/macosx/libswiftCompatibilityPacks.a \
		-sectcreate __TEXT __info_plist Info.plist \
		-L /Library/Developer/CommandLineTools/usr/lib/swift/macosx -L \
		/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/swift \
		-no_objc_category_merging -L $(XCODE_PATH) -rpath \
		Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx \
		./x86_64/main.o $(filter-out ./x86_64/main.o, $(X86OBJMODULES)) \
		-o $@
endif

ifdef UNIVERSAL
$(EXEC): ./arm64/$(EXEC) ./x86_64/$(EXEC)
	@lipo -create -output $(EXEC) $^
else
$(EXEC): ./arm64/$(EXEC)
	@lipo -create -output $(EXEC) $^
endif

$(EXEC).app: $(EXEC)
	@rm -rf $@
	@mkdir -p $@/Contents/MacOS/ && \
	mkdir -p $@/Contents/Resources/ && \
	cp Info.plist $@/Contents/ && \
	cp resources/AppIcon.icns $@/Contents/Resources/ && \
	cp $(EXEC) $@/Contents/MacOS/ && \
	codesign -s ${DEVELOPER_ID} -f --timestamp -o runtime $(EXEC).app

all: $(EXEC).app

run: all
	@open $(EXEC).app

clean:
	rm -rf $(EXEC) $(EXEC).app arm64 x86_64
	mkdir arm64 x86_64

clean-all: clean

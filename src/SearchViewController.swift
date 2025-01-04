import AppKit
import OSLog

fileprivate enum ViewConstants {
    static let spacing2: CGFloat = 2
    static let spacing10: CGFloat = 10
    static let spacing20: CGFloat = 20
    static let spacing40: CGFloat = 40
}

class SearchViewController: NSViewController, NSTextFieldDelegate,
    NSPopoverDelegate
{
    fileprivate static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: SearchViewController.self)
    )

    var foundProgram: Program? = nil

    private var settingsPopover: NSPopover = {
        let popover = NSPopover()
        popover.contentViewController = SettingsViewController()
        popover.behavior = .transient
        return popover
    }()

    private var appIconImage: NSImageView = {
        let image = NSImageView()
        image.image = 
            NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        image.imageScaling = .scaleAxesIndependently
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    private var searchInput: EditableNSTextField = {
        let textField = EditableNSTextField()
        textField.placeholderString = "Search programs . . ."
        textField.bezelStyle = .roundedBezel
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var programsLabel: NSTextField = {
        let textField = NSTextField()
        textField.stringValue = ""
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.alignment = .left
        textField.font = NSFont.systemFont(
            ofSize: NSFontDescriptor.preferredFontDescriptor(
                forTextStyle: .body).pointSize, weight: .bold)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var settingsButton: NSButton = {
        let button = NSButton()
        button.image = systemImage("gearshape.fill", .title2, .large,
            .init(paletteColors: [.white, .systemRed]))
        button.isBordered = false
        button.action = #selector(openSettings)
        button.sizeToFit()
        button.toolTip = "Quit"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private func addSubviews() {
        view.addSubview(appIconImage)
        view.addSubview(searchInput)
        view.addSubview(programsLabel)
        view.addSubview(settingsButton)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            appIconImage.widthAnchor.constraint(equalToConstant: 70),
            appIconImage.heightAnchor.constraint(
                equalTo: appIconImage.widthAnchor, multiplier: 1),

            appIconImage.topAnchor.constraint(equalTo: view.topAnchor,
                constant: ViewConstants.spacing20),
            appIconImage.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -ViewConstants.spacing10),
            appIconImage.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: ViewConstants.spacing10),

            searchInput.widthAnchor.constraint(equalToConstant: 300),
            searchInput.topAnchor.constraint(
                equalTo: appIconImage.topAnchor),
            searchInput.leadingAnchor.constraint(
                equalTo: appIconImage.trailingAnchor,
                constant: ViewConstants.spacing10),

            settingsButton.firstBaselineAnchor.constraint(
                equalTo: searchInput.firstBaselineAnchor),
            settingsButton.leadingAnchor.constraint(
                equalTo: searchInput.trailingAnchor,
                constant: ViewConstants.spacing10),
            settingsButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -ViewConstants.spacing10),

            programsLabel.topAnchor.constraint(
                equalTo: searchInput.bottomAnchor,
                constant: ViewConstants.spacing10),
            programsLabel.leadingAnchor.constraint(
                equalTo: appIconImage.trailingAnchor,
                constant: ViewConstants.spacing10),
            programsLabel.trailingAnchor.constraint(
                equalTo: searchInput.trailingAnchor),

        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        settingsPopover.delegate = self

        searchInput.delegate = self

        addSubviews()
        setConstraints()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        self.view.window?.center()

        // searchInput should select all text whenever window appears.
        NSApp.sendAction(#selector(NSResponder.selectAll(_:)),
            to: nil, from: self)
    }

    override func loadView() {
        self.view = NSView()
    }

    @objc
    func openSettings() {
        // HACK: This is an interseting behavior. When NSPopover appears 
        //       the first time, it always displays in the wrong location;
        //       however, showing it twice does result in the right
        //       location.
        settingsPopover.show(relativeTo: settingsButton.bounds,
            of: settingsButton, preferredEdge: .maxY)
        settingsPopover.show(relativeTo: settingsButton.bounds,
            of: settingsButton, preferredEdge: .maxY)
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let searchInput = obj.object as? EditableNSTextField
        else { return }

        var list = ""

        let programs = PathManager.shared.programs
        for program in programs {
            if program.name.lowercased().contains(
                searchInput.stringValue.lowercased())
            {
                if !list.isEmpty {
                    list += ", "
                }
                list += program.name + program.ext
                foundProgram = program
                break
            } else {
                foundProgram = nil
            }
        }
        
        if let program = foundProgram {
            programsLabel.stringValue =
                program.name + program.ext + " (\(program.path))"

            let url = URL(fileURLWithPath: program.path)
                .appendingPathComponent(program.name+program.ext)
            appIconImage.image = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            programsLabel.stringValue = ""

            appIconImage.image =
                NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        }
    }

    func control(_ control: NSControl, textView: NSTextView,
        doCommandBy commandSelector: Selector) -> Bool
    {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if let program = foundProgram {
                let url = URL(fileURLWithPath: program.path)
                    .appendingPathComponent(program.name+program.ext)
                let config = NSWorkspace.OpenConfiguration()

                NSWorkspace.shared.openApplication(at: url,
                    configuration: config)
                { [weak self] application, error in
                    if let error = error {
                        Self.logger.debug("\(error.localizedDescription)")
                    } else {
                        Self.logger.debug("Program opened successfully")
                        DispatchQueue.main.async {
                            if let window = self?.view.window {
                                window.resignKey()
                            }
                        }
                    }
                }
            }
            NSApp.sendAction(#selector(NSResponder.selectAll(_:)),
                to: nil, from: self)

            return true
        } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
            return true
        }

        return false
    }

    func popoverWillShow(_ notification: Notification) {
        searchInput.abortEditing()
    }

    func popoverWillClose(_ notification: Notification) {
        searchInput.becomeFirstResponder()
    }
}

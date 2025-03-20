import AppKit

// TODO: Change to appropriate links.
fileprivate enum AboutLinks {
    // static let website = "https://cmdbar.app"
    // static let documentation = "https://cmdbar.app/documentation"
    // static let privacy = "https://cmdbar.app/#privacy-policy"
    static let author = "https://kolokolnikov.org"
}

enum Strings {
    static let copyright = "Copyright © 2024\nGarikMI. All rights reserved."
    static let evaluationTitle = "License - Evaluation"
    static let evaluationMessage = "You are currently using evaluation license. CmdBar will quit after 20 minutes. If you already own a license, enter it below or purchase a license."
    static let activate = "Activate"
    static let proTitle = "License - Activated"
    static let proMessage = "Thank you for purchasing CmdBar! Enjoy!"
    static let deactivate = "Deactivate"
    static let activating = "Activating..."
}

class AboutViewController: NSViewController, NSTextFieldDelegate {
    private var appIconImage: NSImageView = {
        //let image = NSImageView(image: NSApp.applicationIconImage)
        let image = NSImageView()
        image.image =
            NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        image.imageScaling = .scaleAxesIndependently
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    private var appNameLabel: NSTextField = {
        let textField = NSTextField()
        textField.stringValue =
            (Bundle.main.infoDictionary?["CFBundleName"] as? String)
            ??
            "NOT FOUND"
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.font =
            NSFont.systemFont(ofSize: NSFontDescriptor
                .preferredFontDescriptor(forTextStyle: .title1).pointSize,
                                         weight: .bold)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var versionLabel: NSTextField = {
        let textField = NSTextField()
        textField.stringValue =
            "Version \((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "-.--")"
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.textColor = NSColor.systemGray
        textField.font =
            NSFont.systemFont(ofSize: NSFontDescriptor
                .preferredFontDescriptor(forTextStyle: .subheadline).pointSize,
                                         weight: .regular)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var copyrightLabel: NSTextField = {
        let textField = NSTextField()
        textField.stringValue = Strings.copyright
        textField.maximumNumberOfLines = 4
        textField.cell?.truncatesLastVisibleLine = true
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.textColor = NSColor.systemGray
        textField.font =
            NSFont.systemFont(ofSize: NSFontDescriptor
                .preferredFontDescriptor(forTextStyle: .subheadline).pointSize,
                                         weight: .regular)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var authorButton: NSButton = {
        let button = NSButton()
        button.title = "Author"
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.action = #selector(author)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // private var privacyButton: NSButton = {
    //     let button = NSButton()
    //     button.title = "Privacy Policy"
    //     button.sizeToFit()
    //     button.bezelStyle = .rounded
    //     button.action = #selector(privacy)
    //     button.translatesAutoresizingMaskIntoConstraints = false
    //     return button
    // }()

    // private var documentationButton: NSButton = {
    //     let button = NSButton()
    //     button.title = "Docs"
    //     button.sizeToFit()
    //     button.bezelStyle = .rounded
    //     button.action = #selector(documentation)
    //     button.translatesAutoresizingMaskIntoConstraints = false
    //     return button
    // }()
    //
    // private var websiteButton: NSButton = {
    //     let button = NSButton()
    //     button.title = "CmdBar.app"
    //     button.sizeToFit()
    //     button.bezelStyle = .rounded
    //     button.action = #selector(website)
    //     button.translatesAutoresizingMaskIntoConstraints = false
    //     return button
    // }()

    private var buttonsContainer: NSLayoutGuide = {
        let container = NSLayoutGuide()
        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Program info
        view.addSubview(appIconImage)
        view.addSubview(appNameLabel)
        view.addSubview(versionLabel)
        view.addSubview(copyrightLabel)

        // Buttons
        view.addLayoutGuide(buttonsContainer)
        // view.addSubview(privacyButton)
        // view.addSubview(documentationButton)
        // view.addSubview(websiteButton)
        view.addSubview(authorButton)

        setupConstraints()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.center()
    }

    override func loadView() {
        self.view = NSView()
    }

    private func setupConstraints() {
        // View.
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 300),
            view.heightAnchor.constraint(lessThanOrEqualToConstant: 500),
        ])

        // App image.
        NSLayoutConstraint.activate([
            appIconImage.widthAnchor.constraint(equalToConstant: 100),
            appIconImage.heightAnchor
                .constraint(equalTo: appIconImage.widthAnchor,
                            multiplier: 1),
            appIconImage.topAnchor
                .constraint(equalTo: view.topAnchor,
                            constant: ViewConstants.spacing20),
            appIconImage.centerXAnchor
                .constraint(equalTo: view.centerXAnchor),
        ])

        // Title
        NSLayoutConstraint.activate([
            appNameLabel.topAnchor
                .constraint(equalTo: appIconImage.bottomAnchor,
                            constant: ViewConstants.spacing20),
            appNameLabel.centerXAnchor
                .constraint(equalTo: view.centerXAnchor),

            versionLabel.topAnchor
                .constraint(equalTo: appNameLabel.bottomAnchor,
                            constant: ViewConstants.spacing2),
            versionLabel.centerXAnchor
                .constraint(equalTo: view.centerXAnchor),

            copyrightLabel.topAnchor
                .constraint(equalTo: versionLabel.bottomAnchor,
                            constant: ViewConstants.spacing10),
            copyrightLabel.centerXAnchor
                .constraint(equalTo: view.centerXAnchor),
        ])

        // Buttons
        NSLayoutConstraint.activate([
            buttonsContainer.topAnchor
                .constraint(equalTo: copyrightLabel.bottomAnchor,
                            constant: ViewConstants.spacing20),
            buttonsContainer.bottomAnchor
                .constraint(equalTo: view.bottomAnchor,
                            constant: -ViewConstants.spacing20),
            buttonsContainer.centerXAnchor
                .constraint(equalTo: view.centerXAnchor),

            authorButton.topAnchor
                .constraint(equalTo: buttonsContainer.topAnchor),
            authorButton.bottomAnchor
                .constraint(equalTo: buttonsContainer.bottomAnchor),
            authorButton.leadingAnchor
                .constraint(equalTo: buttonsContainer.leadingAnchor),
            authorButton.trailingAnchor
                .constraint(equalTo: buttonsContainer.trailingAnchor),

            // privacyButton.topAnchor
            //     .constraint(equalTo: buttonsContainer.topAnchor),
            // privacyButton.bottomAnchor
            //     .constraint(equalTo: buttonsContainer.bottomAnchor),
            // privacyButton.leadingAnchor
            //     .constraint(equalTo: buttonsContainer.leadingAnchor),
            //
            // documentationButton.firstBaselineAnchor
            //     .constraint(equalTo: privacyButton.firstBaselineAnchor),
            // documentationButton.leadingAnchor
            //     .constraint(equalTo: privacyButton.trailingAnchor,
            //                 constant: ViewConstants.spacing10),
            //
            // websiteButton.firstBaselineAnchor
            //     .constraint(equalTo: privacyButton.firstBaselineAnchor),
            // websiteButton.leadingAnchor
            //     .constraint(equalTo: documentationButton.trailingAnchor,
            //                 constant: ViewConstants.spacing10),
            // websiteButton.trailingAnchor
            //     .constraint(equalTo: buttonsContainer.trailingAnchor),
        ])
    }

    @objc private func author() {
        NSWorkspace.shared.open(URL(string: AboutLinks.author)!)
    }

    // @objc private func privacy() {
    //     NSWorkspace.shared.open(URL(string: AboutLinks.privacy)!)
    // }
    //
    // @objc private func documentation() {
    //     NSWorkspace.shared.open(URL(string: AboutLinks.documentation)!)
    // }
    //
    // @objc private func website() {
    //     NSWorkspace.shared.open(URL(string: AboutLinks.website)!)
    // }
}

import AppKit
import Carbon

class SearchViewController: NSViewController, NSTextFieldDelegate,
    NSPopoverDelegate, NSTableViewDataSource, NSTableViewDelegate
{
    private var keyboardEvents: EventMonitor?

    private var foundProgram: Program? = nil
    private var programsList: [Program] = []

    private var programsTableViewSelection = 0

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
        textField.usesSingleLineMode = false
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.systemFont(
            ofSize: NSFontDescriptor.preferredFontDescriptor(
                forTextStyle: .title3).pointSize, weight: .medium)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var settingsButton: NSButton = {
        let button = NSButton()
        button.image = systemImage("gearshape.fill", .title2, .large,
            .init(paletteColors: [.labelColor, .systemRed]))
        button.isBordered = false
        button.action = #selector(openSettings)
        button.sizeToFit()
        button.toolTip = "Quit"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var tableScrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private var programsTableView: ProgramsTableView = {
        let table = ProgramsTableView()

        table.style = NSTableView.Style.plain
        table.backgroundColor = .clear
        table.usesAutomaticRowHeights = true

        table.headerView = nil
        table.allowsMultipleSelection = false
        table.allowsColumnReordering = false
        table.allowsColumnResizing = false
        table.allowsColumnSelection = false
        table.addTableColumn(NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("Program")))

        table.doubleAction = #selector(tableDoubleClick)

        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private func addSubviews() {
        view.addSubview(appIconImage)
        view.addSubview(searchInput)
        view.addSubview(settingsButton)
        view.addSubview(tableScrollView)
    }

    var viewBottomAnchorTable: NSLayoutConstraint?
    var viewBottomAnchorImage: NSLayoutConstraint?

    private func setConstraints() {
        viewBottomAnchorTable = tableScrollView.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -ViewConstants.spacing10)
        viewBottomAnchorImage = appIconImage.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -ViewConstants.spacing10)

        viewBottomAnchorTable?.isActive = false
        viewBottomAnchorImage?.isActive = true

        NSLayoutConstraint.activate([
            appIconImage.widthAnchor.constraint(equalToConstant: 60),
            appIconImage.heightAnchor.constraint(
                equalTo: appIconImage.widthAnchor, multiplier: 1),

            appIconImage.topAnchor.constraint(equalTo: view.topAnchor,
                constant: ViewConstants.spacing10),
            appIconImage.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: ViewConstants.spacing10),

            searchInput.widthAnchor.constraint(equalToConstant: 300),
            searchInput.centerYAnchor.constraint(
                equalTo: appIconImage.centerYAnchor),
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

            tableScrollView.heightAnchor.constraint(equalToConstant: 210),
            tableScrollView.topAnchor.constraint(
                equalTo: appIconImage.bottomAnchor,
                constant: ViewConstants.spacing10),
            tableScrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor),
            tableScrollView.trailingAnchor.constraint(
               equalTo: view.trailingAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardEvents = LocalEventMonitor(mask: [.keyDown], handler:
        { [weak self] event in
            let key = event.keyCode
            let modifiers = event.modifierFlags.rawValue

            // TODO: Implement helper functions for modifiers.
            if let controller = self {
                if modsContains(keys: OSCtrl, in: modifiers) &&
                        key == kVK_ANSI_P ||
                    modsContainsNone(in: modifiers) &&
                        key == kVK_UpArrow
                {
                    controller.programsTableViewSelection -= 1
                    
                } else if modsContains(keys: OSCtrl, in: modifiers) &&
                        key == kVK_ANSI_N ||
                    modsContainsNone(in: modifiers) &&
                        (key == kVK_DownArrow)
                {
                    controller.programsTableViewSelection += 1
                }

                if controller.programsTableViewSelection >
                    controller.programsList.count-1
                {
                    controller.programsTableViewSelection =
                        controller.programsList.count-1
                } else if controller.programsTableViewSelection < 0 {
                    controller.programsTableViewSelection = 0
                }

                let select = controller.programsTableViewSelection
                    self?.programsTableView.selectRowIndexes(
                        IndexSet(integer: select),
                        byExtendingSelection: false)
                    self?.programsTableView.scrollRowToVisible(select)
            }

            return event
        })

        settingsPopover.delegate = self

        searchInput.delegate = self

        tableScrollView.documentView = programsTableView
        programsTableView.dataSource = self
        programsTableView.delegate = self

        addSubviews()
        setConstraints()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        keyboardEvents?.start()

        view.window?.center()

        view.window?.makeFirstResponder(searchInput)
        // searchInput should select all text whenever window appears.
        NSApp.sendAction(#selector(NSResponder.selectAll(_:)),
            to: nil, from: self)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        keyboardEvents?.stop()
    }

    override func loadView() {
        self.view = NSView()
    }

    private func reloadProgramsTableViewData() {
        if programsList.count > 0 {
            viewBottomAnchorTable?.isActive = true
            viewBottomAnchorImage?.isActive = false
        } else {
            viewBottomAnchorTable?.isActive = false
            viewBottomAnchorImage?.isActive = true
        }
        programsTableView.reloadData()
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

    @objc
    private func tableDoubleClick() {
        let program = programsList[programsTableView.clickedRow]
        openProgram(program)
    }

    private func openProgram(_ program: Program) {
        let url = URL(fileURLWithPath: program.path)
            .appendingPathComponent(program.name+program.ext)
        let config = NSWorkspace.OpenConfiguration()

        NSWorkspace.shared.openApplication(at: url,
            configuration: config)
        { [weak self] application, error in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                print("Program opened successfully")
                // NOTE: This needs a window! Do not just copy-paste
                //       this block elsewhere.
                DispatchQueue.main.async {
                    if let window = self?.view.window {
                        window.resignKey()
                    }
                }
            }
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let searchInput = obj.object as? EditableNSTextField
        else { return }

        let programs = PathManager.shared.programs

        programsList = []
        for i in programs.indices {
            var program = programs[i]
            if programsList.count >= 10 {
                break
            }
            if program.name.lowercased().contains(
                searchInput.stringValue.lowercased())
            {
                let url = URL(fileURLWithPath: program.path)
                    .appendingPathComponent(program.name+program.ext)
                let image = NSWorkspace.shared.icon(forFile: url.path)
                program.img = image
                programsList.append(program)
            }
        }
        reloadProgramsTableViewData()

        programsTableViewSelection = 0
        programsTableView.selectRowIndexes(
            IndexSet(integer: programsTableViewSelection),
            byExtendingSelection: false)
        programsTableView.scrollRowToVisible(programsTableViewSelection)

        if programsList.count > 0 {
            appIconImage.image = programsList[0].img
        } else {
            appIconImage.image =
                NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        }
    }

    func control(_ control: NSControl, textView: NSTextView,
        doCommandBy commandSelector: Selector) -> Bool
    {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if programsList.count > 0 {
                let program = programsList[programsTableViewSelection]
                openProgram(program)
                NSApp.sendAction(#selector(NSResponder.selectAll(_:)),
                    to: nil, from: self)
            }
            return true
        } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
            return true
        } else if commandSelector == #selector(NSResponder.moveUp(_:)) ||
            commandSelector == #selector(NSResponder.moveDown(_:))
        {
            // Ignore arrows keys up or down because we use those to
            // navigate the programs list.
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

    func numberOfRows(in tableView: NSTableView) -> Int {
        return programsList.count
    }

    func tableView(_ tableView: NSTableView,
        rowViewForRow row: Int) -> NSTableRowView?
    {
        return ProgramTableRowView()
    }

    func tableView(_ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        let cell = ProgramTableViewCell()
        let program = programsList[row]

        // PERF: This is very slow, even with 10 items on the list! It has
        //       to be the image of concern. UIKit has reusable cells,
        //       is that possible? Or is fetching an image is slow?
        // searchInput.stringValue

        let app = program.name + program.ext
        let rangeToHighlight = 
            (app.lowercased() as NSString)
                .range(of: searchInput.stringValue.lowercased())
        let attributedString = NSMutableAttributedString(string: app)
        attributedString.addAttributes(
            [.foregroundColor: NSColor.labelColor],
            range: rangeToHighlight)

        cell.titleField.attributedStringValue = attributedString
        cell.progPathLabel.stringValue = program.path
        cell.appIconImage.image = program.img
        cell.id = row

        return cell
    }
}

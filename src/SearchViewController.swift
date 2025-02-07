import AppKit
import Carbon

// NOTE: This is the corner radius of the backgrounView view that acts as
//       a window frame and an NSViewController's view that clips all
//       elements inside of it.
fileprivate let windowCornerRadius = 15.0

struct ProgramWeighted {
    let program: Program
    let weight: Int
}

class SearchViewController: NSViewController, NSTextFieldDelegate,
    NSPopoverDelegate, NSTableViewDataSource, NSTableViewDelegate
{
    private var keyboardEvents: EventMonitor?

    private var programsList: [Program] = Array(repeating: Program(), count: 10)
    private var listIndex = 0

    private var programsTableViewSelection = 0

    private var settingsPopover: NSPopover = {
        let popover = NSPopover()
        popover.contentViewController = SettingsViewController()
        popover.behavior = .transient
        return popover
    }()

    private var shadowView: ShadowView = {
        let view = ShadowView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var backgroundView: NSVisualEffectView = {
        let effect = NSVisualEffectView()
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.material = .popover

        effect.wantsLayer = true
        effect.layer?.masksToBounds = true

        effect.layer?.borderColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
        effect.layer?.borderWidth = 1
        effect.layer?.cornerRadius = windowCornerRadius

        effect.translatesAutoresizingMaskIntoConstraints = false
        return effect
    }()

    private var contentView: NSView = {
        let view = NSView()
        // Clip all content to window's rounded frame emulated by
        // backgroundView.
        view.wantsLayer = true
        view.layer?.masksToBounds = true
        view.layer?.cornerRadius = windowCornerRadius

        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var searchInput: EditableNSTextField = {
        let textField = EditableNSTextField()
        textField.isBezeled = false
        textField.maximumNumberOfLines = 1
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byTruncatingHead
        textField.focusRingType = .none
        textField.placeholderString = "Program Search"
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.systemFont(ofSize: NSFontDescriptor.preferredFontDescriptor(forTextStyle: .largeTitle).pointSize, weight: .medium)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var settingsButton: NSButton = {
        let button = NSButton()
        button.image = systemImage("gear.circle.fill", .title1, .large, .init(paletteColors: [.labelColor, .systemGray]))
        button.isBordered = false
        button.action = #selector(openSettings)
        button.sizeToFit()
        button.toolTip = "Quit"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var tableScrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.automaticallyAdjustsContentInsets = false
        scroll.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: ViewConstants.spacing10, right: 0)
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
        view.addSubview(shadowView)
        view.addSubview(backgroundView)
        view.addSubview(contentView)

        contentView.addSubview(searchInput)
        contentView.addSubview(settingsButton)
        contentView.addSubview(tableScrollView)
    }

    var tableViewHeightAnchor: NSLayoutConstraint?

    private func setConstraints() {
        tableViewHeightAnchor = tableScrollView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightAnchor?.isActive = true

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -100),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 100),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -100),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 100),

            shadowView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            shadowView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            shadowView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),

            backgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            searchInput.widthAnchor.constraint(equalToConstant: 350),
            searchInput.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ViewConstants.spacing10),
            searchInput.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ViewConstants.spacing15),

            settingsButton.centerYAnchor.constraint(equalTo: searchInput.centerYAnchor),
            settingsButton.leadingAnchor.constraint(equalTo: searchInput.trailingAnchor, constant: ViewConstants.spacing5),
            settingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ViewConstants.spacing10),

            tableScrollView.topAnchor.constraint(equalTo: searchInput.bottomAnchor, constant: ViewConstants.spacing10),
            tableScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tableScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        keyboardEvents = LocalEventMonitor(mask: [.keyDown]) { [weak self] event in
            let key = event.keyCode
            let modifiers = event.modifierFlags.rawValue

            if let controller = self {
                if modsContains(keys: OSCtrl, in: modifiers) && key == kVK_ANSI_P ||
                   modsContainsNone(in: modifiers) && key == kVK_UpArrow
                {
                    controller.programsTableViewSelection -= 1
                } else if modsContains(keys: OSCtrl, in: modifiers) && key == kVK_ANSI_N ||
                          modsContainsNone(in: modifiers) && key == kVK_DownArrow
                {
                    controller.programsTableViewSelection += 1
                }

                if controller.programsTableViewSelection > controller.listIndex-1 {
                    controller.programsTableViewSelection = controller.listIndex-1
                } else if controller.programsTableViewSelection < 0 {
                    controller.programsTableViewSelection = 0
                }

                let select = controller.programsTableViewSelection
                    self?.programsTableView.selectRowIndexes(IndexSet(integer: select), byExtendingSelection: false)
                    self?.programsTableView.scrollRowToVisible(select)
            }

            return event
        }

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

        if let win = view.window, let scrn = NSScreen.main {
            let x = (scrn.visibleFrame.size.width / 2) - (win.frame.size.width / 2)
            let y = (scrn.visibleFrame.size.height * 0.9) - win.frame.size.height
            view.window?.setFrameOrigin(NSPoint(x: x, y: y))
        }

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
        if listIndex > 0 {
            tableViewHeightAnchor?.constant = 210
        } else {
            tableViewHeightAnchor?.constant = 0
        }
        programsTableView.reloadData()
    }

    @objc
    func openSettings() {
        // HACK: This is an interesting behavior. When NSPopover appears
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
        let url = URL(fileURLWithPath: program.path).appendingPathComponent(program.name+program.ext)
        let config = NSWorkspace.OpenConfiguration()

        // NOTE: This needs a window! Do not just copy-paste
        //       this block elsewhere.
        NSWorkspace.shared.openApplication(at: url, configuration: config) { [weak self] application, error in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                print("Program opened successfully")
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

        listIndex = 0
        if !searchInput.stringValue.isEmpty {
            outerloop: for path in PathManager.shared.paths {
                for i in path.value.indices {
                    var prog = path.value[i]
                    if listIndex >= 10 { break outerloop }

                    if prog.name.lowercased().contains(searchInput.stringValue.lowercased()) {
                        programsList[listIndex].path = prog.path
                        programsList[listIndex].name = prog.name
                        programsList[listIndex].ext = prog.ext
                        programsList[listIndex].img = NSWorkspace.shared.icon(forFile: URL(fileURLWithPath: prog.path).appendingPathComponent(prog.name+prog.ext).path)
                        listIndex += 1
                    }
                }
            }
        }
        reloadProgramsTableViewData()

        programsTableViewSelection = 0
        programsTableView.selectRowIndexes(IndexSet(integer: programsTableViewSelection), byExtendingSelection: false)
        programsTableView.scrollRowToVisible(programsTableViewSelection)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if listIndex > 0 {
                let program = programsList[programsTableViewSelection]
                openProgram(program)
                NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self)
            }
            return true
        } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
            return true
        } else if commandSelector == #selector(NSResponder.moveUp(_:)) || commandSelector == #selector(NSResponder.moveDown(_:)) {
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
        return listIndex
    }

    func tableView(_ tableView: NSTableView,
        rowViewForRow row: Int) -> NSTableRowView?
    {
        return ProgramsTableRowView()
    }

    func tableView(_ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        let cell = ProgramsTableViewCell()
        let program = programsList[row]

        // PERF: This is very slow, even with 10 items on the list! It has
        //       to be the image of concern. UIKit has reusable cells,
        //       is that possible? Or is fetching an image is slow?
        // searchInput.stringValue

        let app = program.name + program.ext
        let rangeToHighlight = (app.lowercased() as NSString).range(of: searchInput.stringValue.lowercased())
        let attributedString = NSMutableAttributedString(string: app)
        attributedString.addAttributes([.foregroundColor: NSColor.labelColor], range: rangeToHighlight)

        cell.titleField.attributedStringValue = attributedString
        cell.progPathLabel.stringValue = program.path
        cell.appIconImage.image = program.img
        cell.id = row

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if programsTableView.selectedRow != programsTableViewSelection {
            programsTableViewSelection = programsTableView.selectedRow
        }
    }
}

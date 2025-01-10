import AppKit
import Carbon
import ServiceManagement

class SettingsViewController: NSViewController, NSTextFieldDelegate,
    KeyDetectorButtonDelegate, NSTableViewDataSource, NSTableViewDelegate,
    PathsTableCellViewDelegate
{
    private var recording = false

    // NOTE: This is the default shortcut. If you were to change it, don't
    //       forget to change other places in this file and delegate, too.
    private var keyCode = Int(kVK_Space)
    private var modifiers = Int(optionKey)

    // NOTE:  PERF: This is very slow to initialize because it creates a
    //             a new process. This also cannot be done on a separate
    //             thread. This sucks because the program now takes
    //             considerably longer to launch.
    private let dirPicker: NSOpenPanel = {
        let panel = NSOpenPanel()
        panel.message = "Select a directory to search applications in . . ."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        return panel
    }()

    private var shortcutsLabel: NSTextField = {
        let textField = NSTextField(labelWithString: "Shortcut")
        textField.font = NSFont.systemFont(
            ofSize: NSFontDescriptor.preferredFontDescriptor(
                forTextStyle: .title2).pointSize, weight: .bold)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var ctrlButton: NSButton = {
        let button = NSButton()
        button.title = "⌃"
        button.action = #selector(handleModifiers)
        button.setButtonType(.pushOnPushOff)
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var cmdButton: NSButton = {
        let button = NSButton()
        button.title = "⌘"
        button.action = #selector(handleModifiers)
        button.setButtonType(.pushOnPushOff)
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var optButton: NSButton = {
        let button = NSButton()
        button.title = "⌥"
        button.action = #selector(handleModifiers)
        button.setButtonType(.pushOnPushOff)
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var shiftButton: NSButton = {
        let button = NSButton()
        button.title = "⇧"
        button.action = #selector(handleModifiers)
        button.setButtonType(.pushOnPushOff)
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var plusLabel: NSTextField = {
        let textField = NSTextField()
        textField.stringValue = "+"
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.font = NSFont.systemFont(
            ofSize: NSFontDescriptor.preferredFontDescriptor(
                forTextStyle: .body).pointSize, weight: .bold)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var recordButton: KeyDetectorButton = {
        let button = KeyDetectorButton()
        button.title = "Record"
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var pathsLabel: NSTextField = {
        let textField =
            NSTextField(labelWithString: "Application Directories")
        textField.font = NSFont.systemFont(
            ofSize: NSFontDescriptor.preferredFontDescriptor(
                forTextStyle: .title2).pointSize, weight: .bold)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private var tableScrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private var pathsTableView: NSTableView = {
        let table = NSTableView()

        table.backgroundColor = .clear

        table.doubleAction = #selector(editItem)

        table.headerView = nil
        table.allowsMultipleSelection = false
        table.allowsColumnReordering = false
        table.allowsColumnResizing = false
        table.allowsColumnSelection = false
        table.addTableColumn(NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("Paths")))

        //rowHeight cgfloat must see doc

        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private var pathsControl: NSSegmentedControl = {
        let control = NSSegmentedControl()
        control.segmentCount = 2
        control.segmentStyle = .roundRect

        control.setImage(
            NSImage(systemSymbolName: "plus",
            accessibilityDescription: nil), forSegment: 0)
        control.setImage(
            NSImage(systemSymbolName: "minus",
            accessibilityDescription: nil), forSegment: 1)

        control.setToolTip("Add Path", forSegment: 0)
        control.setToolTip("Remove Path", forSegment: 1)
        control.trackingMode = .momentary

        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private var launchAtLoginButton: NSButton = {
        let button = NSButton()
        button.title = "Launch at login - OFF"
        button.action = #selector(launchAtLogin)
        button.setButtonType(.toggle)
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.isBordered = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var resetAllButton: NSButton = {
        let button = NSButton()
        button.title = "Reset"
        button.action = #selector(reset)
        button.setButtonType(.momentaryLight)
        button.sizeToFit()
        button.bezelStyle = .rounded
        button.isBordered = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private func addSubviews() {
        view.addSubview(shortcutsLabel)
        view.addSubview(ctrlButton)
        view.addSubview(cmdButton)
        view.addSubview(optButton)
        view.addSubview(shiftButton)
        view.addSubview(plusLabel)
        view.addSubview(recordButton)

        view.addSubview(pathsLabel)
        view.addSubview(tableScrollView)
        view.addSubview(pathsControl)

        view.addSubview(launchAtLoginButton)
        view.addSubview(resetAllButton)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            shortcutsLabel.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: ViewConstants.spacing10),
            shortcutsLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: ViewConstants.spacing10),

            ctrlButton.topAnchor.constraint(
                equalTo: shortcutsLabel.bottomAnchor,
                constant: ViewConstants.spacing10),
            ctrlButton.leadingAnchor.constraint(
                equalTo: shortcutsLabel.leadingAnchor),

            cmdButton.centerYAnchor.constraint(
                equalTo: ctrlButton.centerYAnchor),
            cmdButton.leadingAnchor.constraint(
                equalTo: ctrlButton.trailingAnchor,
                constant: ViewConstants.spacing5),

            optButton.centerYAnchor.constraint(
                equalTo: ctrlButton.centerYAnchor),
            optButton.leadingAnchor.constraint(
                equalTo: cmdButton.trailingAnchor,
                constant: ViewConstants.spacing5),

            shiftButton.centerYAnchor.constraint(
                equalTo: ctrlButton.centerYAnchor),
            shiftButton.leadingAnchor.constraint(
                equalTo: optButton.trailingAnchor,
                constant: ViewConstants.spacing5),

            plusLabel.centerYAnchor.constraint(
                equalTo: ctrlButton.centerYAnchor),
            plusLabel.leadingAnchor.constraint(
                equalTo: shiftButton.trailingAnchor,
                constant: ViewConstants.spacing5),

            recordButton.widthAnchor.constraint(equalToConstant: 40),
            recordButton.centerYAnchor.constraint(
                equalTo: ctrlButton.centerYAnchor),
            recordButton.leadingAnchor.constraint(
                equalTo: plusLabel.trailingAnchor,
                constant: ViewConstants.spacing5),

            pathsLabel.topAnchor.constraint(
                equalTo: ctrlButton.bottomAnchor,
                constant: ViewConstants.spacing20),
            pathsLabel.leadingAnchor.constraint(
                equalTo: shortcutsLabel.leadingAnchor),

            tableScrollView.widthAnchor.constraint(equalToConstant: 350),
            tableScrollView.heightAnchor.constraint(equalToConstant: 150),
            tableScrollView.topAnchor.constraint(
                equalTo: pathsLabel.bottomAnchor),
            tableScrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor),
            tableScrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor),

            pathsControl.topAnchor.constraint(
                equalTo: tableScrollView.bottomAnchor,
                constant: ViewConstants.spacing10),
            pathsControl.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: ViewConstants.spacing10),

            launchAtLoginButton.topAnchor.constraint(
                equalTo: pathsControl.bottomAnchor,
                constant: ViewConstants.spacing10),
            launchAtLoginButton.trailingAnchor.constraint(
                equalTo: resetAllButton.leadingAnchor,
                constant: -ViewConstants.spacing10),

            resetAllButton.centerYAnchor.constraint(
                equalTo: launchAtLoginButton.centerYAnchor),
            resetAllButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -ViewConstants.spacing10),
            resetAllButton.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -ViewConstants.spacing10),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableScrollView.documentView = pathsTableView

        cmdButton.target = self
        optButton.target = self
        ctrlButton.target = self
        shiftButton.target = self
        recordButton.delegate = self
        launchAtLoginButton.target = self
        resetAllButton.target = self

        recordButton.defaultKey = kVK_Space

        recordButton.target = self

        pathsTableView.dataSource = self
        pathsTableView.delegate = self

        pathsControl.target = self
        pathsControl.action = #selector(affectPaths(_:))

        addSubviews()
        setConstraints()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // PERF: Maybe we shouldn't fetch it on every appearance?
        //       Only do it in AppDelegate?
        if let code =
            UserDefaults.standard.object(forKey: "keyCode") as? Int
        {
            keyCode = code
        }
        if let mods =
            UserDefaults.standard.object(forKey: "keyModifiers") as? Int
        {
            modifiers = mods
        }

        pathsTableView.reloadData()
        syncModifierButtons()
        launchAtLoginStatus()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        self.view.window?.center()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        HotKeyManager.shared.registerHotKey(key: keyCode,
            modifiers: modifiers)

        UserDefaults.standard.set(keyCode, forKey: "keyCode")
        UserDefaults.standard.set(modifiers, forKey: "keyModifiers")

        PathManager.shared.removeEmpty()
        PathManager.shared.savePaths()
        PathManager.shared.rebuildIndex()
    }

    override func loadView() {
        self.view = NSView()
    }

    @objc
    private func handleModifiers() {
        // NOTE: Revert to default modifier if none of the modifier
        //       buttons are on.
        if cmdButton.state != .on, optButton.state != .on,
           ctrlButton.state != .on, shiftButton.state != .on
        {
            optButton.state = .on
        }

        detectModifers()
    }

    @objc
    private func launchAtLogin() {
        delegate.toggleLaunchAtLogin()
        launchAtLoginStatus()
    }

    private func launchAtLoginStatus() {
        if delegate.willLaunchAtLogin() {
            launchAtLoginButton.title = "Launch at login - ON"
            launchAtLoginButton.state = .on
        } else {
            launchAtLoginButton.title = "Launch at login - OFF"
            launchAtLoginButton.state = .off
        }
    }

    @objc
    private func reset() {
        keyCode = Int(kVK_Space)
        modifiers = Int(optionKey)
        HotKeyManager.shared.registerHotKey(key: keyCode, modifiers: modifiers)
        UserDefaults.standard.set(keyCode, forKey: "keyCode")
        UserDefaults.standard.set(modifiers, forKey: "keyModifiers")
        syncModifierButtons()

        PathManager.shared.reset()
        pathsTableView.reloadData()
    }

    private func detectModifers() {
        var mods = 0

        if cmdButton.state == .on {
            mods |= cmdKey
        }
        if optButton.state == .on {
            mods |= optionKey
        }
        if ctrlButton.state == .on {
            mods |= controlKey
        }
        if shiftButton.state == .on {
            mods |= shiftKey
        }

        if mods == 0 {
            mods |= optionKey
        } else {
            modifiers = mods
        }
    }

    private func syncModifierButtons() {
        ctrlButton.state  = .off
        cmdButton.state   = .off
        optButton.state   = .off
        shiftButton.state = .off

        if modifiers & controlKey != 0 {
            ctrlButton.state = .on
        }
        if modifiers & cmdKey != 0 {
            cmdButton.state = .on
        }
        if modifiers & optionKey != 0 {
            optButton.state = .on
        }
        if modifiers & shiftKey != 0 {
            shiftButton.state = .on
        }

        if let character = keyName(virtualKeyCode: UInt16(keyCode)) {
            recordButton.title = character
        }
    }

    @objc
    private func affectPaths(_ sender: NSSegmentedControl) {
        let selectedSegment = sender.selectedSegment
        switch selectedSegment {
        case 0:
            // NOTE: Seems a bit error prone.
            var row = PathManager.shared.userPaths.count-1
            if !PathManager.shared.userPaths[row].isEmpty {
                row += 1
                PathManager.shared.addPath("")
                pathsTableView.insertRows(at: IndexSet(integer: row),
                    withAnimation: [])
            }
            pathsTableView.scrollRowToVisible(row)
            pathsTableView.selectRowIndexes(IndexSet(integer: row),
                byExtendingSelection: false)
            (pathsTableView.view(atColumn: 0, row: row,
                makeIfNecessary: false) as? PathsTableCellView)?
                    .startEditing()
            break
        case 1:
            if pathsTableView.selectedRow > -1 {
                PathManager.shared.userPaths
                    .remove(at: pathsTableView.selectedRow)
                pathsTableView.reloadData()
            }
            break
        default:
            break
        }
    }

    @objc
    private func editItem(_ sender: NSTableView) {
        pathsTableView.deselectAll(nil)
        pathsTableView.selectRowIndexes(
            IndexSet(integer: pathsTableView.clickedRow),
            byExtendingSelection: false)

        if let cell = pathsTableView.view(atColumn: 0,
            row: pathsTableView.clickedRow,
            makeIfNecessary: false) as? PathsTableCellView
        {
            cell.startEditing()
        }
    }

    func titleFieldFinishedEditing(tag: Int, text: String) {
        if text.isEmpty {
            PathManager.shared.userPaths.remove(at: tag)
        } else {
            PathManager.shared.userPaths[tag] = text
        }
        pathsTableView.reloadData()
    }

    func titleFieldTextChanged(tag: Int, text: String) {
    }

    func keyWasSet(to keyCode: Int) {
        self.keyCode = Int(keyCode)
    }

    func selectionButtonClicked(tag: Int) {
        NSRunningApplication.current.activate(options: .activateAllWindows)
        delegate.window.level = .normal

        if dirPicker.runModal() == .OK {
            if let url = dirPicker.url {
                PathManager.shared.userPaths[tag] = url.path
                pathsTableView.reloadData()
            }
        }

        delegate.window.level = .statusBar
        delegate.window.makeKeyAndOrderFront(nil)
        if let controller =
            delegate.window.contentViewController as?  SearchViewController
        {
            controller.openSettings()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return PathManager.shared.userPaths.count
    }

    func tableView(_ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        let rect = NSRect(x: 0, y: 0,
            width: tableColumn!.width, height: 20)
        let cell = PathsTableCellView(frame: rect)
        cell.titleField.stringValue = PathManager.shared.userPaths[row]
        cell.delegate = self
        cell.id = row
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
    }
}

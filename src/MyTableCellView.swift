import AppKit

protocol MyTableCellViewDelegate: AnyObject {
    func selectionButtonClicked(tag: Int)
    func titleFieldTextChanged(tag: Int, text: String)
    func titleFieldFinishedEditing(tag: Int, text: String)
}

class MyTableCellView: NSTableCellView, NSTextFieldDelegate {
    var id: Int = -1
    weak var delegate: MyTableCellViewDelegate?

    private(set) var isEditing = false

    public var titleField: NSTextField = {
        let field = NSTextField()
        field.isEditable = false
        field.maximumNumberOfLines = 1
        field.lineBreakMode = .byTruncatingTail
        field.isBezeled = false
        field.drawsBackground = false
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    var selectionButton: NSButton = {
        let button = NSButton()
        button.image = systemImage("hand.point.up.fill", .headline, .large,
            .init(paletteColors: [.white, .systemRed]))
        button.isBordered = false
        button.sizeToFit()
        button.toolTip = "Select Path"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        titleField.delegate = self

        selectionButton.target = self
        selectionButton.action = #selector(makeSelection)

        addSubview(titleField)
        addSubview(selectionButton)

        titleField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleField.setContentCompressionResistancePriority(.defaultLow,
            for: .horizontal)

        NSLayoutConstraint.activate([
            //titleField.topAnchor.constraint(equalTo: topAnchor),
            //titleField.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleField.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleField.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleField.trailingAnchor.constraint(
                equalTo: selectionButton.leadingAnchor),

            selectionButton.centerYAnchor.constraint(
                equalTo: centerYAnchor),
            selectionButton.trailingAnchor.constraint(
                equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func makeSelection() {
        delegate?.selectionButtonClicked(tag: id)
    }

    public func startEditing() {
        isEditing = true
        titleField.isEditable = true
        window?.makeFirstResponder(titleField)
    }

    public func stopEditing() {
        isEditing = false
        titleField.isEditable = false
        window?.makeFirstResponder(nil)
    }

    func controlTextDidChange(_ obj: Notification) {
        delegate?.titleFieldTextChanged(tag: id,
            text: titleField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView,
        doCommandBy commandSelector: Selector) -> Bool
    {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            stopEditing()
            delegate?.titleFieldFinishedEditing(tag: id,
                text: titleField.stringValue)
            return true
        } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
            return true
        }

        return false
    }
}

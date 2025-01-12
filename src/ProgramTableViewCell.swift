import AppKit

class ProgramTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionColor = NSColor.controlAccentColor
                .withAlphaComponent(0.8)
            selectionColor.setFill()
            self.bounds.fill()
        }
    }
}

class ProgramTableViewCell: NSTableCellView {
    var id: Int = -1

    private(set) var isEditing = false

    public var appIconImage: NSImageView = {
        let image = NSImageView()
        image.image = 
            NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        image.imageScaling = .scaleAxesIndependently
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    public var titleField: NSTextField = {
        let field = NSTextField(labelWithString: "")
        field.textColor = NSColor.secondaryLabelColor
        field.lineBreakMode = .byTruncatingTail
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    public var progPathLabel: NSTextField = {
        let textField = NSTextField(labelWithString: "")
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.font = NSFont.systemFont(
            ofSize: NSFontDescriptor.preferredFontDescriptor(
                forTextStyle: .caption1).pointSize, weight: .medium)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        addSubview(appIconImage)
        addSubview(titleField)
        addSubview(progPathLabel)

        NSLayoutConstraint.activate([
            appIconImage.widthAnchor.constraint(equalToConstant: 40),
            appIconImage.heightAnchor.constraint(equalToConstant: 40),
            appIconImage.topAnchor.constraint(equalTo: topAnchor),
            appIconImage.bottomAnchor.constraint(equalTo: bottomAnchor),
            appIconImage.leadingAnchor.constraint(equalTo: leadingAnchor,
                constant: ViewConstants.spacing5),

            titleField.topAnchor.constraint(
                equalTo: appIconImage.topAnchor,
                constant: ViewConstants.spacing2),
            titleField.leadingAnchor.constraint(
                equalTo: appIconImage.trailingAnchor,
                constant: ViewConstants.spacing5),
            titleField.trailingAnchor.constraint(equalTo: trailingAnchor),

            progPathLabel.topAnchor.constraint(
                equalTo: titleField.bottomAnchor),
            progPathLabel.leadingAnchor.constraint(
                equalTo: titleField.leadingAnchor),
            progPathLabel.trailingAnchor.constraint(
                equalTo: titleField.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

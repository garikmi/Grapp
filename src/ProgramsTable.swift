import AppKit

final class ProgramsTableView: NSTableView {
    override var acceptsFirstResponder: Bool { false }
}

class ProgramsTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionColor =
                NSColor.controlAccentColor.withAlphaComponent(0.8)
            selectionColor.setFill()
            self.bounds.fill()
        }
    }
}

class ProgramsTableViewCell: NSTableCellView {
    var id: Int = -1

    private(set) var isEditing = false

    public var indexLabel: NSTextField = {
        let field = NSTextField(labelWithString: "-")
        field.isEditable = false
        field.alignment = .center

        // field.drawsBackground = true
        // field.backgroundColor = NSColor.green.withAlphaComponent(0.2)

        field.textColor = NSColor.secondaryLabelColor
        field.cell?.lineBreakMode = .byTruncatingTail
        field.font = NSFont
            .systemFont(ofSize: NSFontDescriptor
                .preferredFontDescriptor(forTextStyle: .caption1).pointSize,
                                         weight: .bold)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()


    public var appIconImage: NSImageView = {
        let image = NSImageView()
        image.image =
            NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        image.imageScaling = .scaleAxesIndependently
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    public var titleField: NSTextField = {
        let field = NSTextField()
        field.isEditable = false
        field.isBordered = false
        field.drawsBackground = false
        field.lineBreakMode = .byTruncatingTail
        field.textColor = NSColor.textColor
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    public var progPathLabel: NSTextField = {
        let field = NSTextField()
        field.isEditable = false
        field.isBordered = false
        field.drawsBackground = false
        field.lineBreakMode = .byTruncatingTail
        field.font = NSFont
            .systemFont(ofSize: NSFontDescriptor
                .preferredFontDescriptor(forTextStyle: .caption1).pointSize,
                                         weight: .medium)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        // wantsLayer = true
        // layer?.backgroundColor =
        //     NSColor.yellow.withAlphaComponent(0.2).cgColor

        addSubview(indexLabel)
        addSubview(appIconImage)
        addSubview(titleField)
        addSubview(progPathLabel)

        // indexLabel.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            indexLabel.widthAnchor.constraint(equalToConstant: 25),
            indexLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            indexLabel.leadingAnchor
                .constraint(equalTo: leadingAnchor,
                            constant: ViewConstants.spacing5),

            appIconImage.widthAnchor.constraint(equalToConstant: 40),
            appIconImage.heightAnchor.constraint(equalToConstant: 40),
            appIconImage.topAnchor.constraint(equalTo: topAnchor),
            appIconImage.bottomAnchor.constraint(equalTo: bottomAnchor),
            appIconImage.leadingAnchor
                .constraint(equalTo: indexLabel.trailingAnchor),

            titleField.topAnchor
                .constraint(equalTo: appIconImage.topAnchor,
                            constant: ViewConstants.spacing2),
            titleField.leadingAnchor
                .constraint(equalTo: appIconImage.trailingAnchor,
                            constant: ViewConstants.spacing5),
            titleField.trailingAnchor
                .constraint(equalTo: trailingAnchor,
                            constant: -ViewConstants.spacing5),

            progPathLabel.topAnchor
                .constraint(equalTo: titleField.bottomAnchor),
            progPathLabel.leadingAnchor
                .constraint(equalTo: titleField.leadingAnchor),
            progPathLabel.trailingAnchor
                .constraint(equalTo: titleField.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

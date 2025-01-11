import AppKit

class ShadowView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        wantsLayer = true

        guard let layer = layer else { return }

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowBlurRadius = 20.0
        shadow.shadowOffset = CGSize(width: 0, height: -10)
        shadow.set()
        layer.shadowPath = CGPath(rect: bounds, transform: nil)
        self.shadow = shadow
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        setupView()
    }
}

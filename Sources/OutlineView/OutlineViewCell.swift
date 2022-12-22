
import AppKit

public class OutlineViewCell: NSTableCellView, NSTextFieldDelegate {
        
    var onCommit: ((String) -> Void)?
    var textColor: NSColor?
    let spacingConstraint: NSLayoutConstraint
    
    public init() {
        let textField = NSTextField(string: "")
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.usesSingleLineMode = false
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        
        let imgView = NSImageView()
        spacingConstraint = textField.leadingAnchor.constraint(equalTo: imgView.trailingAnchor)
        
        super.init(frame: .zero)
        textField.delegate = self

        addSubview(textField)
        addSubview(imgView)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let constraints: [NSLayoutConstraint] = [
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            imgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imgView.widthAnchor.constraint(equalTo: imgView.heightAnchor),
            imgView.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            spacingConstraint,
        ]
        
        NSLayoutConstraint.activate(constraints)
        self.textField = textField
        self.imageView = imgView
        
        textField.backgroundColor = .green
        imgView.layer?.borderColor = .black
        imgView.layer?.borderWidth = 2.0
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        configure(image: nil, text: "DemoText")
        onEditingCommit(nil)
    }
    
    public func setTextFont(_ font: NSFont) {
        textField?.font = font
    }
    
    public func onEditingCommit(_ action: ((String) -> Void)?) {
        textField?.isSelectable = action != nil
        textField?.isEditable = action != nil
        self.onCommit = action
    }
    
    public func configure(image: NSImage?, text: String) {
        imageView?.image = image
        textField?.stringValue = text
        
        spacingConstraint.constant = image == nil ? 0.0 : 5.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

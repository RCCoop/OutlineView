
import AppKit

/// A standard `NSTableCellView`-based cell with an optional image on the left,
/// and a required string-displaying text field on the right. Provided functions
/// are available for configuring the image and text, as well as basic formatting
/// of the UI.
public class OutlineViewCell: NSTableCellView, NSTextFieldDelegate {

    var onCommit: ((String) -> String)?
    let spacingConstraint: NSLayoutConstraint
    
    // MARK: - Initializer
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    /// Sets the font of the text label.
    /// - Returns: self, for use in chaining modifiers
    @discardableResult
    public func textFont(_ font: NSFont) -> Self {
        textField?.font = font
        return self
    }
    
    /// Sets the text color of the text label.
    /// - Returns: self, for use in chaining modifiers
    @discardableResult
    public func textColor(_ color: NSColor?) -> Self {
        textField?.textColor = color
        return self
    }
    
    /// Adds a modifier to the cell that allows for text editing.
    ///
    /// - Parameter action: An optional closure that takes the newly edited
    ///   string value, and returns a string value that the text label should
    ///   be set to after completion (in case validation fails and the text
    ///   should be modified immediately). If no closure is provided, the
    ///   text cell will not be editable.
    /// - Returns: self, for use in chaining modifiers
    @discardableResult
    public func onEditingCommit(_ action: ((String) -> String)?) -> Self {
        textField?.isSelectable = action != nil
        textField?.isEditable = action != nil
        self.onCommit = action
        return self
    }
    
    /// The basic configuration function for `OutlineViewCell`, which
    /// sets the image and text to display.
    /// - Parameters:
    ///   - image: An optional image to display on the left-hand edge
    ///     of the cell.
    ///   - text: The text to be displayed in the cell's label.
    /// - Returns: self, for use in chaining modifiers
    @discardableResult
    public func configure(image: NSImage?, text: String) -> Self {
        imageView?.image = image
        textField?.stringValue = text
        spacingConstraint.constant = image == nil ? 0.0 : 5.0
        return self
    }
    
    // MARK: - Internal-use Functions
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        configure(image: nil, text: "")
        onEditingCommit(nil)
    }
    

    public func controlTextDidEndEditing(_ note: Notification) {
        guard let textField,
              textField.isEqual(note.object),
              onCommit != nil
        else { return }
        
        textField.stringValue = onCommit!(textField.stringValue)
    }
        
}

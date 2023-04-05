import Foundation

/// Make an `OutlineView`'s Data.Elements implement this
/// protocol if you want the underlying `NSOutlineView`'s
/// delegate to return `true` from its `outlineView(_:shouldEdit:item:)`
public protocol EditableOutlineData {
    /// This is the return value this item will give to the
    /// containing `OutlineView`'s delegate for `outlineView(_:shouldEdit:item:)`
    var outlineViewShouldEdit: Bool { get }
}

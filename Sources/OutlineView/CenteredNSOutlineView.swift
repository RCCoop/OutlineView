import AppKit
import Foundation

/// Subclass of `NSOutlineView` that fixes a bug in horizontal
/// centering of rows. See https://stackoverflow.com/a/74894605/1275947
internal class CenteredNSOutlineView: NSOutlineView {
    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
        super.frameOfOutlineCell(atRow: row)
    }
}

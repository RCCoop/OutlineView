import AppKit
import Foundation

@available(macOS 10.15, *)
internal class RCOutlineView<Data>: NSOutlineView
where
Data: Sequence,
Data.Element: Identifiable
{
    var menuProvider: ContextMenuHandlerInternal<Data.Element>? = nil
    
    // Fixes a bug in horizontal centering of rows.
    // See https://stackoverflow.com/a/74894605/1275947
    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
        super.frameOfOutlineCell(atRow: row)
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        guard let menuProvider else { return nil }
        
        // Use `menuProvider` to produce a possible NSMenu
        let windowLocation = event.locationInWindow
        let selfLocation = self.convert(windowLocation, from: nil)
        let clickedRow = row(at: selfLocation)
        
        let clickedItem = (item(atRow: clickedRow) as? OutlineViewItem<Data>)?.value
        if let menuItems = menuProvider(event, clickedItem),
           !menuItems.isEmpty
        {
            let menu = NSMenu()
            menuItems.forEach { menu.addItem($0.menuItem()) }
            return menu
        } else {
            return nil
        }
    }
}

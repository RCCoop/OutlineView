import AppKit
import ContextMenuBuilder
import Foundation

internal typealias ContextMenuHandlerInternal<T> = (NSEvent, T?) -> [ContextMenuBuilder]?

@available(macOS 10.15, *)
internal class RCOutlineView<Data>: NSOutlineView
where
Data: Sequence,
Data.Element: OutlineViewData
{
    var menuProvider: ContextMenuHandlerInternal<Data.Element>? = nil
    
    private var menuIdentifier: NSUserInterfaceItemIdentifier { .init(String(describing: self)) }
    private(set) var menuIsOpen = false
    var menuVisibleHandler: ((Bool) -> Void)?
    
    // Fixes a bug in horizontal centering of rows.
    // See https://stackoverflow.com/a/74894605/1275947
    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
        super.frameOfOutlineCell(atRow: row)
    }
    
    // Use `menuProvider` to determine the menu to display
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
            let res = NSMenu(menuItems)
            res.identifier = menuIdentifier
            return res
        } else {
            return nil
        }
    }
    
    // MARK: - First-Responder Validation
    
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        if menu.identifier == menuIdentifier {
            menuIsOpen = true
            menuVisibleHandler?(true)
        }
    }

    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        super.didCloseMenu(menu, with: event)
        if menu.identifier == menuIdentifier {
            menuIsOpen = false
            menuVisibleHandler?(false)
        }
    }
}

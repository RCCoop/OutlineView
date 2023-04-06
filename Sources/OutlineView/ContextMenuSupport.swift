import AppKit
import Foundation

public typealias ContextMenuHandler<T> = (NSEvent, T?) -> ([MenuBuilder]?, T?)
internal typealias ContextMenuHandlerInternal<T> = (NSEvent, T?) -> [MenuBuilder]?

public enum MenuBuilder {
    case separator
    case submenu(title: String, image: NSImage?, items: [MenuBuilder])
    case button(title: String, image: NSImage?, action: (() -> Void)?)
    case systemImageButton(title: String, systemImage: String, action: (() -> Void)?)
    
    func menuItem() -> NSMenuItem {
        switch self {
        case .separator:
            return .separator()
        case let .submenu(title, image, items):
            let mainItem = NSMenuItem()
            mainItem.title = title
            mainItem.image = image
            let subMenu = NSMenu()
            items.forEach {
                subMenu.addItem($0.menuItem())
            }
            mainItem.submenu = subMenu
            return mainItem
        case let .button(title, image, action):
            let buttonItem = NSMenuItemActioned(title: title, action: action)
            buttonItem.image = image
            return buttonItem
        case let .systemImageButton(title, systemImage, action):
            let buttonItem = NSMenuItemActioned(title: title, action: action)
            if #available(macOS 11, *) {
                buttonItem.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
            } else {
                print("buttonSystemImage not available before MacOS 11")
            }
            return buttonItem
        }
    }
}

internal final class NSMenuItemActioned: NSMenuItem {
    var actionHandler: (() -> Void)?
    
    init(title: String, action: (() -> Void)?) {
        self.actionHandler = action
        let cAction = action != nil ? #selector(performAction(_:)) : nil
        super.init(title: title, action: cAction, keyEquivalent: "")
        
        self.target = self
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc private func performAction(_ sender: Any?) {
        actionHandler?()
    }
}

import Cocoa
import Combine

@available(macOS 10.15, *)
public class OutlineViewController<Data: Sequence, Drop: DropReceiver>: NSViewController
where
Drop.DataElement == Data.Element,
Data.Element: OutlineViewData
{
    let outlineView = RCOutlineView<Data>()
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
    
    let dataSource: OutlineViewDataSource<Data, Drop>
    let delegate: OutlineViewDelegate<Data>
    let updater = OutlineViewUpdater<Data>()

    let childrenSource: ChildSource<Data>
    
    /// Simple boolean to tell the notification listeners for `itemDidExpand` and `itemDidCollapse`
    /// to stay silent so that model-initiated changes to expansion state won't interfere with UI-initiated
    /// changes.
    var blockExpansionListener = false
    var expansionListeners = Set<AnyCancellable>()
    let expandedStateChanged: (Set<Data.Element.ID>) -> Void

    init(
        data: Data,
        childrenSource: ChildSource<Data>,
        content: @escaping (Data.Element) -> NSView,
        selectionChanged: @escaping (Data.Element?) -> Void,
        expandedStateChanged: @escaping (Set<Data.Element.ID>) -> Void,
        separatorInsets: ((Data.Element) -> NSEdgeInsets)?
    ) {
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = true
        scrollView.drawsBackground = false

        outlineView.autoresizesOutlineColumn = false
        outlineView.headerView = nil
        outlineView.usesAutomaticRowHeights = true
        outlineView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        let onlyColumn = NSTableColumn()
        onlyColumn.resizingMask = .autoresizingMask
        outlineView.addTableColumn(onlyColumn)

        dataSource = OutlineViewDataSource(
            items: data.map { OutlineViewItem(value: $0, children: childrenSource) },
            childSource: childrenSource
        )
        delegate = OutlineViewDelegate(
            content: content,
            selectionChanged: selectionChanged,
            separatorInsets: separatorInsets)
        outlineView.dataSource = dataSource
        outlineView.delegate = delegate

        self.childrenSource = childrenSource
        self.expandedStateChanged = expandedStateChanged
        
        super.init(nibName: nil, bundle: nil)

        // Listen for expand/collapse notifications in order to keep expandedItems up to date
        NotificationCenter.default.publisher(for: NSOutlineView.itemDidExpandNotification)
            .compactMap(NSOutlineView.expansionNotificationInfo(_:))
            .sink { [weak self] in
                self?.expandedItemsStateDidChange(outlineView: $0.outlineView, changedItem: $0.object)
            }
            .store(in: &expansionListeners)
        NotificationCenter.default.publisher(for: NSOutlineView.itemDidCollapseNotification)
            .compactMap(NSOutlineView.expansionNotificationInfo(_:))
            .sink { [weak self] in
                self?.expandedItemsStateDidChange(outlineView: $0.outlineView, changedItem: $0.object)
            }
            .store(in: &expansionListeners)
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    public override func loadView() {
        view = NSView()
    }

    public override func viewWillAppear() {
        // Size the column to take the full width. This combined with
        // the uniform column autoresizing style allows the column to
        // adjust its width with a change in width of the outline view.
        outlineView.sizeLastColumnToFit()
        super.viewWillAppear()
    }
}

// MARK: - Performing updates
@available(macOS 10.15, *)
extension OutlineViewController {
    func updateData(newValue: Data) {
        let newState = newValue.map { OutlineViewItem(value: $0, children: childrenSource) }
        let oldTreeMap = dataSource.treeMap
        let oldHashKey = dataSource.hashKey
        
        outlineView.beginUpdates()

        dataSource.items = newState
        updater.performUpdates(
            outlineView: outlineView,
            oldStateTree: oldTreeMap,
            oldHashKey: oldHashKey,
            newState: newState,
            parent: nil)

        outlineView.endUpdates()
        
        // After updates, dataSource must rebuild its idTree for future updates
        dataSource.rebuildIDTree(rootItems: newState, outlineView: outlineView)
        
        // If data in outlineView has changed, it's possible that the selected
        // row has changed also, and we need to manually update the binding
        // selection in order to make it reflect the new selection coming from
        // the outlineView
        let newHashKey = dataSource.hashKey
        if oldHashKey != newHashKey {
            // Do this in a DispatchQueue.main.async because without that, it was
            // causing wrong values to be found for `currentSelection`
            DispatchQueue.main.async {
                let currentSelection = self.outlineView.item(atRow: self.outlineView.selectedRow) as? OutlineViewItem<Data>
                let delegateSelection = self.delegate.selectedItem
                if currentSelection?.value.id != delegateSelection?.value.id {
                    self.delegate.selectionChanged(currentSelection?.value)
                }
            }
        }
    }

    func changeSelectedItem(to item: Data.Element?) {
        delegate.changeSelectedItem(
            to: item.map { OutlineViewItem(value: $0, children: childrenSource) },
            in: outlineView)
    }
    
    func changeExpandedItems(to itemIds: Set<Data.Element.ID>) {
        guard itemIds != readExpandedItemIds() else { return }
        
        blockExpansionListener = true
        
        var n = 0
        while n < outlineView.numberOfRows {
            if let typedItem = outlineView.item(atRow: n) as? OutlineViewItem<Data> {
                let isExpanded = outlineView.isItemExpanded(typedItem)
                if isExpanded && !itemIds.contains(typedItem.id) {
                    outlineView.collapseItem(typedItem)
                } else if !isExpanded && itemIds.contains(typedItem.id) {
                    outlineView.expandItem(typedItem)
                } else {
                    n += 1
                }
            } else {
                n += 1
            }
        }
        
        blockExpansionListener = false
        
        DispatchQueue.main.async {
            self.expandedStateChanged(self.readExpandedItemIds())
        }
    }

    @available(macOS 11.0, *)
    func setStyle(to style: NSOutlineView.Style) {
        outlineView.style = style
    }

    func setIndentation(to width: CGFloat) {
        outlineView.indentationPerLevel = width
    }

    func setRowSeparator(visibility: SeparatorVisibility) {
        switch visibility {
        case .hidden:
            outlineView.gridStyleMask = []
        case .visible:
            outlineView.gridStyleMask = .solidHorizontalGridLineMask
        }
    }
    
    func setContextMenuHandler(_ handler: ContextMenuHandler<Data.Element>?) {
        if let handler {
            outlineView.menuProvider = { [weak self] (event, clickedItem) in
                let (menu, highlight) = handler(event, clickedItem)
                self?.changeSelectedItem(to: highlight)
                return menu
            }
        } else {
            outlineView.menuProvider = nil
        }
    }

    func setRowSeparator(color: NSColor) {
        guard color != outlineView.gridColor else {
            return
        }

        outlineView.gridColor = color
        outlineView.reloadData()
    }
        
    func setDragSourceWriter(_ writer: DragSourceWriter<Data.Element>?) {
        dataSource.dragWriter = writer
    }
    
    func setDropReceiver(_ receiver: Drop?) {
        dataSource.dropReceiver = receiver
    }
    
    func setAcceptedDragTypes(_ acceptedTypes: [NSPasteboard.PasteboardType]?) {
        outlineView.unregisterDraggedTypes()
        if let acceptedTypes,
           !acceptedTypes.isEmpty
        {
            outlineView.registerForDraggedTypes(acceptedTypes)
        }
    }
}

// MARK: - Private Helpers

@available(macOS 10.15, *)
private extension OutlineViewController {
    func expandedItemsStateDidChange(outlineView: NSOutlineView, changedItem: Any) {
        guard outlineView == self.outlineView,
              !blockExpansionListener
        else { return }
        
        expandedStateChanged(readExpandedItemIds())
    }
    
    func readExpandedItemIds() -> Set<Data.Element.ID> {
        let newExpandedItems = stride(from: 0, to: outlineView.numberOfRows, by: 1)
            .compactMap { outlineView.item(atRow: $0) as? OutlineViewItem<Data> }
            .filter { outlineView.isItemExpanded($0) }
            .map { $0.id }
        return Set(newExpandedItems)
    }
}

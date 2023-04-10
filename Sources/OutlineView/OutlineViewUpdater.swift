import Cocoa

@available(macOS 10.15, *)
struct OutlineViewUpdater<Data: Sequence>
where Data.Element: OutlineViewData {
    /// variable for testing purposes. When set to false (the default),
    /// `performUpdates` will escape its recursion for objects that are not
    /// expanded in the outlineView.
    var assumeOutlineIsExpanded = false
    
    /// Perform updates on the outline view based on the change in state.
    /// - NOTE: Calls to this method must be surrounded by
    ///  `NSOutlineView.beginUpdates` and `NSOutlineView.endUpdates`.
    ///  `OutlineViewDataSource.items` should be updated to the new state before calling this method.
    func performUpdates(
        outlineView: NSOutlineView,
        oldStateTree: TreeMap<Data.Element.ID>,
        oldHashKey: [Data.Element.ID : Int],
        newState: [OutlineViewItem<Data>],
        parent: OutlineViewItem<Data>?
    ) {
        // Get states to compare: oldIDs and newIDs, as related to the given parent object
        let oldIDs: [Data.Element.ID]
        if let parent {
            if let children = oldStateTree.currentChildrenOfItem(parent.id) {
                oldIDs = children
            } else {
                oldIDs = []
            }
        } else {
            oldIDs = oldStateTree.rootData
        }
        
        let newIDs = newState.map(\.id)
        
        // Do insert and removal
        let diff = newIDs.difference(from: oldIDs)
        var oldUnchangedElements = newState
            .filter { oldIDs.contains($0.id) }
            .reduce(into: [:], { $0[$1.id] = $1 })
        applyDiffs(diff, outlineView: outlineView, parentItem: parent, unchangedElements: &oldUnchangedElements)
        
        for (remainingID, remainingItem) in oldUnchangedElements {
            // reload item if its hashValue has changed
            if oldHashKey[remainingID] != remainingItem.value.hashValue {
                print("Reloading \(remainingID)")
                outlineView.reloadItem(remainingItem, reloadChildren: false)
            }
            
            // then recurse on its children
            if assumeOutlineIsExpanded || outlineView.isItemExpanded(remainingItem) {
                let children = remainingItem.children ?? []
                performUpdates(outlineView: outlineView, oldStateTree: oldStateTree, oldHashKey: oldHashKey, newState: children, parent: remainingItem)
            }
        }
    }
        
    private func applyDiffs(
        _ diff: CollectionDifference<Data.Element.ID>,
        outlineView: NSOutlineView,
        parentItem:  OutlineViewItem<Data>?,
        unchangedElements: inout [Data.Element.ID : OutlineViewItem<Data>]
    ) {
        for change in diff {
            switch change {
            case .insert(offset: let offset, _, _):
                outlineView.insertItems(
                    at: IndexSet([offset]),
                    inParent: parentItem,
                    withAnimation: .effectFade)

            case .remove(offset: let offset, element: let element, _):
                unchangedElements[element] = nil
                outlineView.removeItems(
                    at: IndexSet([offset]),
                    inParent: parentItem,
                    withAnimation: .effectFade)
            }
        }
    }
}

@available(macOS 10.15, *)
fileprivate extension Sequence where Element: Identifiable {
    func dictionaryFromIdentity() -> [Element.ID: Element] {
        Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
    }
}

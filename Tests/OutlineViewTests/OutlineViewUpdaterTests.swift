import XCTest
@testable import OutlineView

class OutlineViewUpdaterTests: XCTestCase {
    struct TestItem: OutlineViewData {
        var id: Int
        var children: [TestItem]?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(children != nil)
        }
    }

    let oldState = [
        TestItem(id: 0, children: nil),
        TestItem(id: 1, children: []),
        TestItem(id: 2, children: nil),
        TestItem(id: 3, children: [TestItem(id: 4, children: nil)]),
        TestItem(id: 5, children: [TestItem(id: 6, children: [TestItem(id: 7, children: nil)])]),
    ]
    .map { OutlineViewItem(value: $0, children: \TestItem.children) }

    let newState = [
        TestItem(id: 0, children: []),
        TestItem(id: 1, children: [TestItem(id: 4, children: nil)]),
        TestItem(id: 3, children: []),
        TestItem(id: 5, children: [TestItem(id: 6, children: nil)]),
        TestItem(id: 8, children: nil),
    ]
    .map { OutlineViewItem(value: $0, children: \TestItem.children) }

    func testPerformUpdates() {
        let outlineView = TestOutlineView()
        outlineView.addVirtualData(oldState)
        
        var updater = OutlineViewUpdater<[TestItem]>()
        updater.assumeOutlineIsExpanded = true

        let oldStateTree = TreeMap(rootItems: oldState, itemIsExpanded: { _ in true })
        let oldHashKey = outlineView.hashKey
        
        updater.performUpdates(
            outlineView: outlineView,
            oldStateTree: oldStateTree,
            oldHashKey: oldHashKey,
            newState: newState,
            parent: nil)

        outlineView.hashKey = [:]
        outlineView.addVirtualData(newState)
        let newHashKey = outlineView.hashKey
        
        XCTAssertEqual(oldHashKey.keys.sorted(),
                       [0, 1, 2, 3, 4, 5, 6, 7])
        
        XCTAssertEqual(newHashKey.keys.sorted(),
                       [0, 1, 3, 4, 5, 6, 8])
        
        XCTAssertNotEqual(newHashKey[0], oldHashKey[0])
        XCTAssertNotEqual(newHashKey[6], oldHashKey[6])
        XCTAssertEqual(newHashKey[1], oldHashKey[1])
        XCTAssertEqual(newHashKey[3], oldHashKey[3])
        XCTAssertEqual(newHashKey[4], oldHashKey[4])
        XCTAssertEqual(newHashKey[5], oldHashKey[5])
        
        XCTAssertEqual(
            outlineView.insertedItems.sorted(),
            [
                UpdatedItem(parent: nil, index: 4),
                UpdatedItem(parent: 1, index: 0),
            ])

        XCTAssertEqual(
            outlineView.removedItems.sorted(),
            [
                UpdatedItem(parent: nil, index: 2),
                UpdatedItem(parent: 3, index: 0),
                UpdatedItem(parent: 6, index: 0),
            ])

        XCTAssertEqual(
            outlineView.reloadedItems.sorted(),
            [0, 6])
    }
}

extension OutlineViewUpdaterTests {
    struct UpdatedItem: Equatable, Comparable {
        let parent: Int?
        let index: Int

        static func < (lhs: Self, rhs: Self) -> Bool {
            switch ((lhs.parent, lhs.index), (rhs.parent, rhs.index)) {
            case ((nil, let l), (nil, let r)): return l < r
            case ((nil, _), (_, _)): return true
            case ((_, _), (nil, _)): return false
            case ((let l, _), (let r, _)): return l < r
            }
        }
    }

    class TestOutlineView: NSOutlineView {
        typealias Item = OutlineViewItem<[TestItem]>
        var insertedItems = [UpdatedItem]()
        var removedItems = [UpdatedItem]()
        var reloadedItems = [Item.ID?]()
        
        var hashKey: [Int : Int] = [:]
        
        func addVirtualData(_ data: [OutlineViewItem<[TestItem]>]) {
            for item in data {
                hashKey[item.value.id] = item.value.hashValue
                if let subItems = item.children {
                    addVirtualData(subItems)
                }
            }
        }

        override func insertItems(
            at indexes: IndexSet,
            inParent parent: Any?,
            withAnimation animationOptions: NSTableView.AnimationOptions = []
        ) {
            indexes.forEach {
                insertedItems.append(UpdatedItem(parent: (parent as? Item)?.id, index: $0))
            }
        }

        override func removeItems(
            at indexes: IndexSet,
            inParent parent: Any?,
            withAnimation animationOptions: NSTableView.AnimationOptions = []
        ) {
            indexes.forEach {
                removedItems.append(UpdatedItem(parent: (parent as? Item)?.id, index: $0))
            }
        }

        override func reloadItem(
            _ item: Any?,
            reloadChildren: Bool
        ) {
            reloadedItems.append((item as? Item)?.id)
        }
    }
}

extension Optional: Comparable where Wrapped: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (nil, _): return true
        case (_, nil): return false
        case (let l, let r): return l.unsafelyUnwrapped < r.unsafelyUnwrapped
        }
    }
}

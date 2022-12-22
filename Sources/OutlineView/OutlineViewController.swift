import Cocoa

@available(macOS 10.15, *)
public class OutlineViewController<Data: Sequence, CellType: NSView>: NSViewController
where Data.Element: Identifiable {
    let outlineView = CenteringOutlineView()
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
    
    let dataSource: OutlineViewDataSource<Data>
    let delegate: OutlineViewDelegate<Data, CellType>
    let updater = OutlineViewUpdater<Data>()

    let childrenPath: KeyPath<Data.Element, Data?>

    init(
        data: Data,
        children: KeyPath<Data.Element, Data?>,
        cellBuilder: @escaping CellBuilder<CellType>,
        cellConfiguration: @escaping CellConfigurer<Data.Element, CellType>,
        selectionChanged: @escaping (Data.Element?) -> Void,
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
        outlineView.backgroundColor = .clear

        let onlyColumn = NSTableColumn()
        onlyColumn.resizingMask = .autoresizingMask
        outlineView.addTableColumn(onlyColumn)

        dataSource = OutlineViewDataSource(
            items: data.map { OutlineViewItem(value: $0, children: children) })
        delegate = OutlineViewDelegate(
            buildCell: cellBuilder,
            configureCell: cellConfiguration,
            selectionChanged: selectionChanged,
            separatorInsets: separatorInsets)
        outlineView.dataSource = dataSource
        outlineView.delegate = delegate

        childrenPath = children

        super.init(nibName: nil, bundle: nil)

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
        let newState = newValue.map { OutlineViewItem(value: $0, children: childrenPath) }

        outlineView.beginUpdates()

        let oldState = dataSource.items
        dataSource.items = newState
        updater.performUpdates(
            outlineView: outlineView,
            oldState: oldState,
            newState: newState,
            parent: nil)

        outlineView.endUpdates()
    }

    func changeSelectedItem(to item: Data.Element?) {
        delegate.changeSelectedItem(
            to: item.map { OutlineViewItem(value: $0, children: childrenPath) },
            in: outlineView)
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

    func setRowSeparator(color: NSColor) {
        guard color != outlineView.gridColor else {
            return
        }

        outlineView.gridColor = color
        outlineView.reloadData()
    }
}


/// A subclass of NSOutlineView that overrides the frame of the disclosure button
/// in order to keep it vertically centered in each row.
///
/// When NSOutlineView rows have a height greater than standard, the only way to
/// get the disclosure to display vertically centered is to override `frameOfOutlineCell(atRow:)`.
/// Bizarrely, with some testing I've found that you don't need to recalculate a new frame
/// for the outline cell... just calling `super.frameOfOutlineCell(atRow:)` seems
/// to bring the disclosure button into the correct center.
class CenteringOutlineView: NSOutlineView {
    
    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
        super.frameOfOutlineCell(atRow: row)
    }
    
}

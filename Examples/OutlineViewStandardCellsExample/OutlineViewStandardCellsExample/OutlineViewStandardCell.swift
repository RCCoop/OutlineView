//
//  OutlineViewStandardCell.swift
//  OutlineViewStandardCellsExample
//

import Foundation

import Cocoa

class FileItemView: NSTableCellView {
    init(fileItem: FileItem) {
        let field = NSTextField(string: fileItem.description)
        field.isEditable = true
        field.isSelectable = true
        field.isBezeled = false
        field.drawsBackground = false
        field.usesSingleLineMode = false
        field.cell?.wraps = true
        field.cell?.isScrollable = false

        let img = NSImage(systemSymbolName: fileItem.children == nil ? "doc" : "folder", accessibilityDescription: nil)
        let imgView = NSImageView(image: img!)
        
        super.init(frame: .zero)

        addSubview(field)
        addSubview(imgView)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        NSLayoutConstraint.activate([
            imgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imgView.widthAnchor.constraint(equalTo: imgView.heightAnchor),
            imgView.centerYAnchor.constraint(equalTo: field.centerYAnchor),
            field.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: 5.0),
            field.trailingAnchor.constraint(equalTo: trailingAnchor),
            field.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            field.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

import AppKit
import CoreImage

enum RedactionTool: String, Codable {
    case blur = "blur"
    case pixelate = "pixelate"
    case solid = "solid"
    case highlight = "highlight"
    case note = "note"
}

enum RedactionTemplate: String, Codable {
    case none = "none"
    case hipaa = "hipaa"
    case gdpr = "gdpr"
    case legal = "legal"
    case custom = "custom"

    var defaultTools: [RedactionTool] {
        switch self {
        case .none: return [.blur, .pixelate, .solid, .highlight, .note]
        case .hipaa: return [.solid, .blackout]
        case .gdpr: return [.blur, .solid, .blackout]
        case .legal: return [.blur, .pixelate, .solid, .blackout]
        case .custom: return [.blur, .pixelate, .solid, .highlight, .note]
        }
    }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .hipaa: return "HIPAA"
        case .gdpr: return "GDPR"
        case .legal: return "Legal"
        case .custom: return "Custom"
        }
    }
}

struct RedactionRegion: Codable, Identifiable {
    let id: UUID
    let rect: CGRect
    let tool: RedactionTool
    let noteText: String?
    let timestamp: Date

    init(id: UUID = UUID(), rect: CGRect, tool: RedactionTool, noteText: String? = nil) {
        self.id = id
        self.rect = rect
        self.tool = tool
        self.noteText = noteText
        self.timestamp = Date()
    }
}

struct RedactionAuditEntry: Codable, Identifiable {
    let id: UUID
    let captureId: UUID
    let regionId: UUID
    let tool: RedactionTool
    let rect: CGRect
    let noteText: String?
    let appliedAt: Date
    let exportedSafe: Bool

    init(id: UUID = UUID(), captureId: UUID, region: RedactionRegion, exportedSafe: Bool = false) {
        self.id = id
        self.captureId = captureId
        self.regionId = region.id
        self.tool = region.tool
        self.rect = region.rect
        self.noteText = region.noteText
        self.appliedAt = Date()
        self.exportedSafe = exportedSafe
    }
}

class RedactionOverlayView: NSView {
    var tool: RedactionTool = .blur
    var regions: [RedactionRegion] = []
    var selectedRegion: RedactionRegion?
    var onSelectionChanged: (() -> Void)?

    private var currentRect: NSRect?
    private var isDragging = false
    private var dragStart: NSPoint?
    private var noteTextField: NSTextField?
    private var selectedNoteField: NSTextField?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if event.clickCount == 2 {
            if let index = regions.lastIndex(where: { $0.rect.contains(point) }) {
                let region = regions[index]
                if region.tool == .note, let noteField = noteTextField, noteField.frame.contains(point) {
                    window?.makeFirstResponder(noteField)
                    selectedRegion = region
                    onSelectionChanged?()
                    return
                }
                regions.remove(at: index)
                setNeedsDisplay(bounds)
                onSelectionChanged?()
                return
            }
        }
        isDragging = true
        dragStart = point
        currentRect = NSRect(origin: point, size: .zero)
        selectedRegion = nil
        onSelectionChanged?()
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging, let start = dragStart else { return }
        let point = convert(event.locationInWindow, from: nil)
        currentRect = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging, let rect = currentRect, rect.width > 5, rect.height > 5 else {
            isDragging = false
            currentRect = nil
            return
        }
        isDragging = false

        let region = RedactionRegion(rect: rect, tool: tool)
        regions.append(region)
        currentRect = nil
        setNeedsDisplay(bounds)
        onSelectionChanged?()

        if tool == .note {
            showNoteEditor(for: region)
        }
    }

    private func showNoteEditor(for region: RedactionRegion) {
        noteTextField = NSTextField(frame: region.rect)
        noteTextField?.borderStyle = .bezelBorder
        noteTextField?.backgroundColor = NSColor(calibratedWhite: 0.9, alpha: 0.9)
        noteTextField?.stringValue = region.noteText ?? ""
        noteTextField?.delegate = self
        noteTextField?.tag = region.id.hashValue
        addSubview(noteTextField!)
        window?.makeFirstResponder(noteTextField)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        for region in regions {
            drawRegion(region)
        }

        if let rect = currentRect {
            drawPreviewRect(rect)
        }
    }

    private func drawRegion(_ region: RedactionRegion) {
        switch region.tool {
        case .blur:
            let fill = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.35)
            fill.setFill()
            NSBezierPath(rect: region.rect).fill()
            NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 0.9).setStroke()
            NSBezierPath(rect: region.rect).lineWidth = 2
            NSBezierPath(rect: region.rect).stroke()

        case .pixelate:
            let fill = NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.22, alpha: 0.35)
            fill.setFill()
            NSBezierPath(rect: region.rect).fill()
            NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.22, alpha: 0.9).setStroke()
            NSBezierPath(rect: region.rect).lineWidth = 2
            NSBezierPath(rect: region.rect).stroke()

        case .solid:
            NSColor.black.setFill()
            NSBezierPath(rect: region.rect).fill()
            NSColor.darkGray.setStroke()
            NSBezierPath(rect: region.rect).lineWidth = 1
            NSBezierPath(rect: region.rect).stroke()

        case .highlight:
            let fill = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 0.4)
            fill.setFill()
            NSBezierPath(rect: region.rect).fill()
            NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.0, alpha: 0.9).setStroke()
            NSBezierPath(rect: region.rect).lineWidth = 2
            NSBezierPath(rect: region.rect).stroke()

        case .note:
            let fill = NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 0.3)
            fill.setFill()
            NSBezierPath(rect: region.rect).fill()
            NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 0.9).setStroke()
            NSBezierPath(rect: region.rect).lineWidth = 2
            NSBezierPath(rect: region.rect).stroke()

            if let note = region.noteText, !note.isEmpty {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.white,
                    .backgroundColor: NSColor.clear
                ]
                note.draw(in: region.rect.insetBy(dx: 4, dy: 4), withAttributes: attrs)
            }
        }
    }

    private func drawPreviewRect(_ rect: NSRect) {
        let fill: NSColor
        let stroke: NSColor
        switch tool {
        case .blur:
            fill = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.25)
            stroke = NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 0.7)
        case .pixelate:
            fill = NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.22, alpha: 0.25)
            stroke = NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.22, alpha: 0.7)
        case .solid:
            fill = NSColor.black.withAlphaComponent(0.7)
            stroke = NSColor.darkGray
        case .highlight:
            fill = NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 0.3)
            stroke = NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.0, alpha: 0.7)
        case .note:
            fill = NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 0.25)
            stroke = NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 0.7)
        }
        fill.setFill()
        NSBezierPath(rect: rect).fill()
        stroke.setStroke()
        NSBezierPath(rect: rect).lineWidth = 1
        NSBezierPath(rect: rect).stroke()
    }

    func renderRedactedImage(from baseImage: NSImage, template: RedactionTemplate = .none) -> NSImage? {
        guard let tiffData = baseImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return baseImage }

        let imageRect = NSRect(origin: .zero, size: baseImage.size)
        let result = NSImage(size: baseImage.size)
        result.lockFocus()
        baseImage.draw(in: imageRect)

        for region in regions {
            guard let cropped = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil)?.cropping(to: region.rect) else { continue }
            let regionImage = NSImage(cgImage: cropped, size: region.rect.size)

            switch region.tool {
            case .blur:
                regionImage.draw(in: region.rect, from: .zero, operation: .copy, fraction: 0.6)
                if let blurFilter = CIFilter(name: "CIGaussianBlur") {
                    blurFilter.setValue(10, forKey: kCIInputRadiusKey)
                    if let context = CIContext(options: nil),
                       let output = blurFilter.outputImage,
                       let cgBlur = context.createCGImage(output, from: region.rect) {
                        NSImage(cgImage: cgBlur, size: region.rect.size).draw(in: region.rect)
                    }
                }
            case .pixelate:
                if let pixelateFilter = CIFilter(name: "CIPixellate") {
                    pixelateFilter.setValue(8, forKey: "inputScale")
                    if let context = CIContext(options: nil),
                       let output = pixelateFilter.outputImage,
                       let cgPixel = context.createCGImage(output, from: region.rect) {
                        NSImage(cgImage: cgPixel, size: region.rect.size).draw(in: region.rect)
                    }
                }
            case .solid:
                NSColor.black.setFill()
                NSBezierPath(rect: region.rect).fill()
            case .highlight:
                NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 0.35).setFill()
                NSBezierPath(rect: region.rect).fill()
            case .note:
                NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 0.35).setFill()
                NSBezierPath(rect: region.rect).fill()
                if let note = region.noteText, !note.isEmpty {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.boldSystemFont(ofSize: 12),
                        .foregroundColor: NSColor.white,
                        .backgroundColor: NSColor.clear
                    ]
                    note.draw(in: region.rect.insetBy(dx: 6, dy: 6), withAttributes: attrs)
                }
            }
        }

        result.unlockFocus()

        if template != .none {
            return applyTemplateWatermark(to: result, template: template)
        }

        return result
    }

    private func applyTemplateWatermark(to image: NSImage, template: RedactionTemplate) -> NSImage? {
        let result = NSImage(size: image.size)
        result.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: image.size))

        let watermark: String
        switch template {
        case .hipaa: watermark = "HIPAA REDACTED"
        case .gdpr: watermark = "GDPR REDACTED"
        case .legal: watermark = "LEGALLY REDACTED"
        default: watermark = "REDACTED"
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 48),
            .foregroundColor: NSColor.red.withAlphaComponent(0.5),
            .backgroundColor: NSColor.clear
        ]
        let size = watermark.size(withAttributes: attrs)
        let rect = NSRect(x: image.size.width - size.width - 20, y: 20, width: size.width, height: size.height)
        watermark.draw(in: rect, withAttributes: attrs)
        result.unlockFocus()
        return result
    }

    func exportSafeData() -> Data? {
        guard let rendered = renderRedactedImage(from: imageView.image ?? NSImage()) else { return nil }
        return rendered.tiffRepresentation
    }
}

extension RedactionOverlayView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField,
              let region = regions.first(where: { $0.id.hashValue == field.tag }) else { return }
        region.noteText = field.stringValue
        selectedNoteField = nil
        setNeedsDisplay(bounds)
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField,
              let region = regions.first(where: { $0.id.hashValue == field.tag }) else { return }
        region.noteText = field.stringValue
        setNeedsDisplay(bounds)
    }
}

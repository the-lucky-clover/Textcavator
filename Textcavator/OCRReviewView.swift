import AppKit
import Vision

class OCRReviewView: NSView {
    var image: NSImage?
    var observations: [VNRecognizedTextObservation] = []
    var selectedText: String = ""

    private let imageView = NSImageView()
    private let overlayView = NSView()
    let textView: NSTextView = {
        let tv = NSTextView()
        tv.isEditable = true
        tv.isSelectable = true
        tv.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1.0)
        tv.textColor = .white
        tv.font = NSFont.systemFont(ofSize: 13)
        return tv
    }()

    var extractedText: String {
        return textView.string
    }
    private let scrollView = NSScrollView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 1.0).cgColor

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(imageView)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(overlayView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.documentView = textView

        addSubview(scrollView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -8),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    func configure(image: NSImage, observations: [VNRecognizedTextObservation]) {
        self.image = image
        self.observations = observations
        imageView.image = image

        let text = observations.compactMap { obs in
            obs.topCandidates(1).first?.string
        }.joined(separator: "\n")
        selectedText = text
        textView.string = text

        setNeedsDisplay(overlayView.bounds)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let image = imageView.image, let imageRef = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }

        let imageViewSize = imageView.bounds.size
        let imageSize = NSSize(width: imageRef.width, height: imageRef.height)
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = imageViewSize.width / imageViewSize.height

        var drawRect: NSRect
        if imageAspect > viewAspect {
            let width = imageViewSize.width
            let height = width / imageAspect
            drawRect = NSRect(x: 0, y: (imageViewSize.height - height) / 2, width: width, height: height)
        } else {
            let height = imageViewSize.height
            let width = height * imageAspect
            drawRect = NSRect(x: (imageViewSize.width - width) / 2, y: 0, width: width, height: height)
        }

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }

            let visionRect = observation.boundingBox
            let convertedRect = convertVisionRect(visionRect, to: drawRect, imageSize: imageSize)

            let path = NSBezierPath(rect: convertedRect)
            NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.35).setFill()
            path.fill()

            path.lineWidth = 2
            NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 0.9).setStroke()
            path.stroke()

            if let text = candidate.string as String? {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: NSColor(calibratedRed: 0.0, green: 0.95, blue: 1.0, alpha: 1.0),
                    .backgroundColor: NSColor(calibratedWhite: 0.0, alpha: 0.7)
                ]
                let textSize = text.size(withAttributes: attrs)
                let textRect = NSRect(
                    x: convertedRect.minX,
                    y: convertedRect.maxY + 2,
                    width: min(textSize.width, convertedRect.width),
                    height: textSize.height
                )
                text.draw(in: textRect, withAttributes: attrs)
            }
        }
    }

    private func convertVisionRect(_ rect: CGRect, to targetRect: NSRect, imageSize: NSSize) -> NSRect {
        let normalizedX = rect.origin.x
        let normalizedY = rect.origin.y
        let normalizedWidth = rect.width
        let normalizedHeight = rect.height

        let x = targetRect.minX + normalizedX * targetRect.width
        let y = targetRect.minY + normalizedY * targetRect.height
        let width = normalizedWidth * targetRect.width
        let height = normalizedHeight * targetRect.height

        return NSRect(x: x, y: y, width: width, height: height)
    }
}

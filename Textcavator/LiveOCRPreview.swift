import AppKit
import AVFoundation
import Vision

class LiveOCRPreview: NSView {
    var onTextDetected: ((String, [VNRecognizedTextObservation]) -> Void)?
    var onCaptureTriggered: (() -> Void)?

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var textOverlayLayer = CALayer()
    private var isRunning = false
    private var request: VNRecognizeTextRequest?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupOverlay()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }

    private func setupOverlay() {
        wantsLayer = true
        layer?.addSublayer(textOverlayLayer)
        textOverlayLayer.backgroundColor = .clear
    }

    func attachPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        layer.removeFromSuperlayer()
        layer.insertSublayer(textOverlayLayer, at: 0)
        textOverlayLayer.frame = bounds
    }

    func startLiveOCR() {
        guard !isRunning else { return }
        isRunning = true

        request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self, isRunning else { return }
            if let error {
                print("Live OCR error: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else { return }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            onTextDetected?(text, observations)
            self.drawTextOverlays(observations)
        }

        request?.recognitionLevel = .accurate
        request?.usesLanguageCorrection = true
        request?.processesAsynchronously = false
    }

    func stopLiveOCR() {
        isRunning = false
        request = nil
        textOverlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    private func drawTextOverlays(_ observations: [VNRecognizedTextObservation]) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        textOverlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        guard let previewLayer = previewLayer else {
            CATransaction.commit()
            return
        }

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let rect = observation.boundingBox
            let converted = previewLayer.layerRectConverted(fromMetadataOutputRect: rect)

            let textLayer = CATextLayer()
            textLayer.string = candidate.string
            textLayer.font = NSFont.boldSystemFont(ofSize: 14)
            textLayer.fontSize = 14
            textLayer.foregroundColor = NSColor.systemGreen.cgColor
            textLayer.backgroundColor = NSColor(calibratedWhite: 0.0, alpha: 0.6).cgColor
            textLayer.cornerRadius = 4
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            textLayer.frame = converted
            textLayer.masksToBounds = true

            let border = CAShapeLayer()
            border.path = CGPath(rect: converted, transform: nil)
            border.strokeColor = NSColor.systemGreen.cgColor
            border.lineWidth = 2
            border.fillColor = nil

            textOverlayLayer.addSublayer(border)
            textOverlayLayer.addSublayer(textLayer)
        }

        CATransaction.commit()
    }

    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            onCaptureTriggered?()
        }
    }
}

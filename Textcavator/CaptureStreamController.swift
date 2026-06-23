import AppKit
import CoreGraphics
import ScreenCaptureKit
import CoreMedia

class CaptureStreamController: NSObject {
    static let shared = CaptureStreamController()

    private var stream: SCStream?
    private var isRecording = false
    private var frameCount = 0
    private var onFrameCaptured: ((NSImage, Date) -> Void)?

    private override init() {}

    func startStream(displayID: CGDirectDisplayID) async throws {
        guard !isRecording else { return }

        let content = try SCShareableContent.current
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw NSError(domain: "CaptureStream", code: 1, userInfo: [NSLocalizedDescriptionKey: "Display not found"])
        }

        let config = SCStreamConfiguration()
        config.width = 1920
        config.height = 1080
        config.minimumFrameInterval = CMTime(value: 1, timescale: 15)
        config.showsCursor = true
        config.queueDepth = 1

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        stream = SCStream(filter: filter, configuration: config, delegate: self)

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "com.textcavator.stream.queue"))
        try await stream?.startCapture()

        isRecording = true
        frameCount = 0
    }

    func stopStream() -> Int {
        guard isRecording else { return 0 }
        isRecording = false
        let count = frameCount
        Task {
            try? await stream?.stopCapture()
        }
        stream = nil
        return count
    }

    func captureSingleFrame() async -> NSImage? {
        return await withCheckedContinuation { continuation in
            let tempOnFrame: ((NSImage, Date) -> Void)? = { [weak self] image, _ in
                continuation.resume(returning: image)
                self?.onFrameCaptured = nil
            }
            onFrameCaptured = tempOnFrame
        }
    }
}

extension CaptureStreamController: SCStreamDelegate, SCStreamOutput {
    func stream(_ stream: SCStream, didOutput sampleBuffer: CMSampleBuffer, of sampleType: SCStreamOutputType) {
        guard sampleType == .screen, isRecording else { return }
        guard let image = imageFromSampleBuffer(sampleBuffer) else { return }
        frameCount += 1
        let timestamp = Date()
        onFrameCaptured?(image, timestamp)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        isRecording = false
        frameCount = 0
    }

    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> NSImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

import AppKit

class BatchCaptureController {
    static let shared = BatchCaptureController()

    private var queue: [NSImage] = []
    private var isProcessing = false
    private var onProgress: ((Int, Int, String) -> Void)?
    private var onComplete: (() -> Void)?

    private init() {}

    func enqueue(_ image: NSImage) {
        queue.append(image)
        if !isProcessing {
            processNext()
        }
    }

    func enqueue(images: [NSImage]) {
        queue.append(contentsOf: images)
        if !isProcessing {
            processNext()
        }
    }

    func cancel() {
        queue.removeAll()
        isProcessing = false
        onComplete?( )
        onComplete = nil
        onProgress = nil
    }

    private func processNext() {
        guard !queue.isEmpty else {
            isProcessing = false
            onComplete?()
            onProgress = nil
            return
        }

        isProcessing = true
        let image = queue.removeFirst()
        let total = queue.count + 1
        let current = total - queue.count

        onProgress?(current, total, "Processing capture \(current)/\(total)")

        NotificationCenter.default.post(name: .init("BatchCaptureNext"), object: image)
    }
}

extension Notification.Name {
    static let BatchCaptureNext = Notification.Name("BatchCaptureNext")
}

import AppKit
import CoreGraphics

class ScrollCaptureController {
    static let shared = ScrollCaptureController()

    private var targetWindowID: CGWindowID = 0
    private var targetRect: CGRect = .zero
    private var stitchedImage: NSImage?
    private var previousFrame: NSImage?
    private var scrollAmount: CGFloat = 0
    private var lastScrollOffset: CGFloat = 0
    private var scrollCount: Int = 0
    private var maxScrolls: Int = 100
    private var minScrollThreshold: CGFloat = 2.0
    private var scrollWheelSteps: Int = 3
    private var onProgress: ((String, Double) -> Void)?
    private var onComplete: ((NSImage?) -> Void)?
    private var isCapturing = false

    private init() {}

    func startCapture(windowID: CGWindowID, frame: CGRect, onProgress: ((String, Double) -> Void)? = nil, onComplete: ((NSImage?) -> Void)? = nil) {
        guard !isCapturing else { return }
        isCapturing = true
        self.targetWindowID = windowID
        self.targetRect = frame
        self.onProgress = onProgress
        self.onComplete = onComplete
        self.scrollCount = 0
        self.stitchedImage = nil
        self.previousFrame = nil
        self.lastScrollOffset = 0
        self.maxScrolls = SettingsManager.shared.scrollCaptureSteps

        captureNextFrame()
    }

    func startCapture(region: CGRect, onProgress: ((String, Double) -> Void)? = nil, onComplete: ((NSImage?) -> Void)? = nil) {
        guard !isCapturing else { return }
        isCapturing = true
        self.targetWindowID = 0
        self.targetRect = region
        self.onProgress = onProgress
        self.onComplete = onComplete
        self.scrollCount = 0
        self.stitchedImage = nil
        self.previousFrame = nil
        self.lastScrollOffset = 0
        self.maxScrolls = SettingsManager.shared.scrollCaptureSteps

        captureNextFrame()
    }

    func cancel() {
        isCapturing = false
        stitchedImage = nil
        previousFrame = nil
        onComplete?(nil)
        onComplete = nil
        onProgress = nil
    }

    private func captureNextFrame() {
        guard isCapturing else { return }

        let image: NSImage?
        if targetWindowID != 0 {
            image = captureWindowImage(windowID: targetWindowID, fallbackRect: targetRect)
        } else {
            image = captureScreenRect(targetRect)
        }

        guard let newFrame = image else {
            finishCapture(result: nil)
            return
        }

        if let previous = previousFrame {
            let offset = detectScrollOffset(between: previous, and: newFrame)

            if abs(offset) < minScrollThreshold && scrollCount > 2 {
                finishCapture(result: stitchedImage)
                return
            }

            if let stitched = stitchFrames(previousStitched: stitchedImage, newFrame: newFrame, scrollOffset: offset) {
                stitchedImage = stitched
            }

            lastScrollOffset = offset
        } else {
            stitchedImage = newFrame
        }

        previousFrame = newFrame
        scrollCount += 1

        onProgress?("Captured frame \(scrollCount)", Double(scrollCount) / Double(maxScrolls))

        if scrollCount >= maxScrolls {
            finishCapture(result: stitchedImage)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.performScroll()
        }
    }

    private func performScroll() {
        guard isCapturing else { return }

        let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: scrollWheelSteps * 30, wheel2: 0, wheel3: 0)
        scrollEvent?.post(tap: .cgSessionEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.captureNextFrame()
        }
    }

    private func detectScrollOffset(between oldFrame: NSImage, and newFrame: NSImage) -> CGFloat {
        guard let oldCG = oldFrame.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let newCG = newFrame.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return 0
        }

        let width = min(oldCG.width, newCG.width)
        let height = min(oldCG.height, newCG.height)

        guard width > 0 && height > 0 else { return 0 }

        let oldData = oldCG.dataProvider?.data
        let newData = newCG.dataProvider?.data

        guard let oldBase = oldData?.baseAddress, let newBase = newData?.baseAddress else { return 0 }

        let oldBytesPerRow = oldCG.bytesPerRow
        let newBytesPerRow = newCG.bytesPerRow

        var bestOffset: CGFloat = 0
        var bestDiff = UInt64.max

        let searchRange = min(200, Int(height * 0.5))

        for offset in 0..<searchRange {
            let pixelsToCompare = min(1000, width * (height - offset))
            var diff: UInt64 = 0

            for i in 0..<pixelsToCompare {
                let oldByte = oldBase.advanced(by: i).load(as: UInt8.self)
                let newByte = newBase.advanced(by: i + offset * newBytesPerRow).load(as: UInt8.self)
                let delta = oldByte > newByte ? oldByte - newByte : newByte - oldByte
                diff += UInt64(delta)
            }

            if diff < bestDiff {
                bestDiff = diff
                bestOffset = CGFloat(offset)
            }
        }

        return bestOffset
    }

    private func stitchFrames(previousStitched: NSImage?, newFrame: NSImage, scrollOffset: CGFloat) -> NSImage? {
        guard let stitched = previousStitched, let stitchedCG = stitched.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return newFrame
        }

        let overlapHeight = max(0, newFrame.size.height - scrollOffset)
        let newTotalHeight = stitched.size.height + newFrame.size.height - overlapHeight

        guard newTotalHeight > 0 && newTotalHeight < 50000 else { return stitched }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(.premultipliedFirst)

        guard let context = CGContext(
            data: nil,
            width: Int(newFrame.size.width),
            height: Int(newTotalHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return stitched }

        let newCG = newFrame.cgImage(forProposedRect: nil, context: nil, hints: nil)

        context.draw(stitchedCG, in: CGRect(x: 0, y: 0, width: stitched.size.width, height: stitched.size.height))

        if let newCG = newCG {
            let drawY = stitched.size.height - overlapHeight
            context.draw(newCG, in: CGRect(x: 0, y: drawY, width: newFrame.size.width, height: newFrame.size.height))
        }

        guard let outputCG = context.makeImage() else { return stitched }
        return NSImage(cgImage: outputCG, size: NSSize(width: outputCG.width, height: outputCG.height))
    }

    private func finishCapture(result: NSImage?) {
        isCapturing = false
        let finalResult = result ?? stitchedImage
        stitchedImage = nil
        previousFrame = nil
        onComplete?(finalResult)
        onComplete = nil
        onProgress = nil
    }

    private func captureWindowImage(windowID: CGWindowID, fallbackRect: CGRect) -> NSImage? {
        if let cgImage = CGWindowListCreateImage(.null, [.optionIncludingWindow], windowID, [.bestResolution]) {
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
        return captureScreenRect(fallbackRect)
    }

    private func captureScreenRect(_ rect: CGRect) -> NSImage? {
        let screenHeight = NSScreen.screens.first?.frame.maxY ?? rect.maxY
        let cgRect = CGRect(x: rect.minX, y: screenHeight - rect.maxY, width: rect.width, height: rect.height)
        guard let cgImage = CGWindowListCreateImage(cgRect, [.optionOnScreenOnly], kCGNullWindowID, [.bestResolution]) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

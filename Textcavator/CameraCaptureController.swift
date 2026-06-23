import AppKit
import AVFoundation
import Vision

class CameraCaptureController: NSObject {
    static let shared = CameraCaptureController()

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var livePreview: NSView?

    private var onFrame: ((NSImage) -> Void)?
    private var isStreaming = false

    private override init() {
        super.init()
    }

    func availableCameras() -> [AVCaptureDevice] {
        var deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        if #available(macOS 14.0, *) {
            deviceTypes.append(.continuityCamera)
        }
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        ).devices
    }

    func startCaptureSession(previewView: NSView) async throws -> AVCaptureSession {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "Camera", code: 1, userInfo: [NSLocalizedDescriptionKey: "Camera capture failed"]))
                    return
                }
                do {
                    try self.configureCaptureSession(previewView: previewView)
                    continuation.resume(returning: self.captureSession!)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func configureCaptureSession(previewView: NSView) throws {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        var deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        if #available(macOS 14.0, *) {
            deviceTypes.append(.continuityCamera)
        }
        guard let camera = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        ).devices.first else {
            throw NSError(domain: "Camera", code: 2, userInfo: [NSLocalizedDescriptionKey: "No camera found. Connect an iPhone/iPad via Continuity Camera."])
        }

        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard captureSession!.canAddInput(videoInput) else {
            throw NSError(domain: "Camera", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"])
        }
        captureSession?.addInput(videoInput)

        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.video.queue"))
        videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        guard let output = videoOutput, captureSession!.canAddOutput(output) else {
            throw NSError(domain: "Camera", code: 4, userInfo: [NSLocalizedDescriptionKey: "Cannot add video output"])
        }
        captureSession?.addOutput(output)

        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession!.canAddOutput(photoOutput) {
            captureSession?.addOutput(photoOutput)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.wantsLayer = true
        previewView.layer?.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        self.livePreview = previewView

        captureSession?.startRunning()
    }

    func stopCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
            self?.videoOutput = nil
            self?.photoOutput = nil
            self?.previewLayer?.removeFromSuperlayer()
            self?.previewLayer = nil
            self?.livePreview = nil
            self?.isStreaming = false
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    func startLiveOCR(handler: @escaping (String, [VNRecognizedTextObservation]) -> Void) {
        isStreaming = true
        self.onFrame = { [weak self] image in
            guard let self = self, self.isStreaming else { return }
            self.performOCR(on: image) { text, observations in
                handler(text, observations)
            }
        }
    }

    func stopLiveOCR() {
        isStreaming = false
        onFrame = nil
    }

    private func performOCR(on image: NSImage, completion: @escaping (String, [VNRecognizedTextObservation]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self, self.isStreaming else { return }
            if let error {
                print("Live OCR error: \(error)")
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else { return }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            completion(text, observations)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

extension CameraCaptureController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isStreaming else { return }
        guard let image = imageFromSampleBuffer(sampleBuffer) else { return }
        onFrame?(image)
    }

    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> NSImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

extension CameraCaptureController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = NSImage(data: data) else { return }
        onFrame?(image)
    }
}

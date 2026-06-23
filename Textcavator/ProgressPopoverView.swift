import AppKit

class ProgressPopoverViewController: NSViewController {
    
    private var progressBar: CyberpunkProgressBar!
    private var statusLabel: NSTextField!
    private var etaLabel: NSTextField!
    private var percentageLabel: NSTextField!
    
    private var startTime: Date?
    private var updateTimer: Timer?
    private var currentProgress: Double = 0
    
    var onCancel: (() -> Void)?
    
    override func loadView() {
        view = CyberpunkCard(frame: NSRect(x: 0, y: 0, width: 320, height: 140))
        (view as? CyberpunkCard)?.glowColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = createLabel(text: LocalizedText.value("processing"), fontSize: 16, weight: .semibold)
        titleLabel.frame = NSRect(x: 20, y: 110, width: 280, height: 24)
        view.addSubview(titleLabel)
        
        // Status label
        statusLabel = createLabel(text: LocalizedText.value("initializing"), fontSize: 12, weight: .regular)
        statusLabel.textColor = NSColor(white: 0.7, alpha: 1.0)
        statusLabel.frame = NSRect(x: 20, y: 85, width: 280, height: 18)
        view.addSubview(statusLabel)
        
        // Progress bar
        progressBar = CyberpunkProgressBar(frame: NSRect(x: 20, y: 55, width: 280, height: 20))
        view.addSubview(progressBar)
        
        // Percentage label
        percentageLabel = createLabel(text: "0%", fontSize: 14, weight: .bold)
        percentageLabel.alignment = .right
        percentageLabel.frame = NSRect(x: 240, y: 25, width: 60, height: 20)
        view.addSubview(percentageLabel)
        
        // ETA label
        etaLabel = createLabel(text: LocalizedText.value("calculating"), fontSize: 11, weight: .regular)
        etaLabel.textColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
        etaLabel.frame = NSRect(x: 20, y: 25, width: 200, height: 16)
        view.addSubview(etaLabel)
        
        // Cancel button
        let cancelBtn = CyberpunkButton(frame: NSRect(x: 20, y: 5, width: 80, height: 28))
        cancelBtn.title = LocalizedText.value("cancel")
        cancelBtn.glowColor = NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        cancelBtn.target = self
        cancelBtn.action = #selector(cancelClicked)
        view.addSubview(cancelBtn)
    }
    
    private func createLabel(text: String, fontSize: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let label = NSTextField()
        label.stringValue = text
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.textColor = .white
        label.backgroundColor = .clear
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        return label
    }
    
    func startProgress() {
        startTime = Date()
        currentProgress = 0
        progressBar.setProgress(0, animated: true)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateETA()
        }
    }
    
    func updateProgress(_ progress: Double, status: String) {
        currentProgress = min(max(progress, 0), 1)
        progressBar.setProgress(currentProgress, animated: true)
        statusLabel.stringValue = status
        percentageLabel.stringValue = "\(Int(currentProgress * 100))%"
    }
    
    func completeProgress() {
        updateTimer?.invalidate()
        updateTimer = nil
        progressBar.setProgress(1.0, animated: true)
        percentageLabel.stringValue = "100%"
        etaLabel.stringValue = LocalizedText.value("complete")
        etaLabel.textColor = NSColor(calibratedRed: 0.4, green: 1.0, blue: 0.6, alpha: 1.0)
    }
    
    private func updateETA() {
        guard let startTime = startTime, currentProgress > 0.05 else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let estimatedTotal = elapsed / currentProgress
        let remaining = estimatedTotal - elapsed
        
        if remaining > 0 {
            if remaining < 60 {
                etaLabel.stringValue = String(format: "%.0f seconds remaining", remaining)
            } else {
                let minutes = Int(remaining / 60)
                let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
                etaLabel.stringValue = String(format: "%d:%02d remaining", minutes, seconds)
            }
        }
    }
    
    @objc private func cancelClicked() {
        updateTimer?.invalidate()
        onCancel?()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

class ProgressPopoverWindowController {
    
    private var popover: NSPopover!
    private var contentController: ProgressPopoverViewController!
    
    init() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        
        contentController = ProgressPopoverViewController()
        contentController.onCancel = { [weak self] in
            self?.close()
        }
        
        popover.contentViewController = contentController
        popover.contentSize = NSSize(width: 320, height: 140)
    }
    
    func show(relativeTo positioningRect: NSRect, of positioningView: NSView) {
        popover.show(relativeTo: positioningRect, of: positioningView, preferredEdge: .minY)
        contentController.startProgress()
    }
    
    func updateProgress(_ progress: Double, status: String) {
        contentController.updateProgress(progress, status: status)
    }
    
    func complete() {
        contentController.completeProgress()
        
        // Auto-close after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.close()
        }
    }
    
    func close() {
        popover.performClose(nil)
    }
}
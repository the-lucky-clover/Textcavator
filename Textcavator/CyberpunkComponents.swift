import AppKit
import Quartz

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as? CGDirectDisplayID ?? CGMainDisplayID()
    }
}

struct UXSoundPlayer {
    static let shared = UXSoundPlayer()

    enum Kind {
        case hover
        case select
        case arm
        case capture
        case complete
        case cancel
    }

    private init() {}

    func play(_ kind: Kind) {
        guard SettingsManager.shared.soundEnabled else { return }
        let name: NSSound.Name
        switch kind {
        case .hover:
            name = "Tink"
        case .select:
            name = "Pop"
        case .arm:
            name = "Glass"
        case .capture:
            name = "Submarine"
        case .complete:
            name = "Hero"
        case .cancel:
            name = "Morse"
        }

        let sound = NSSound(named: name)
        sound?.volume = 0.18
        sound?.play()
    }
}

struct HUDPalette {
    static let cyan = NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 1.0)
    static let mint = NSColor(calibratedRed: 0.42, green: 1.0, blue: 0.62, alpha: 1.0)
    static let violet = NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 1.0)
    static let rose = NSColor(calibratedRed: 1.0, green: 0.28, blue: 0.62, alpha: 1.0)
    static let amber = NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.22, alpha: 1.0)
    static let panel = NSColor(white: 0.055, alpha: 0.88)
    static let panelBright = NSColor(white: 0.13, alpha: 0.9)
    static let text = NSColor(white: 0.96, alpha: 1.0)
    static let mutedText = NSColor(white: 0.62, alpha: 1.0)
}

struct LanguageDefinition {
    let code: String
    let name: String
    let nativeName: String
    let flag: String
    let direction: NSWritingDirection = .natural
}

struct LocalizedText {
    static let languages: [LanguageDefinition] = [
        LanguageDefinition(code: "en-US", name: "English", nativeName: "English", flag: "🇺🇸"),
        LanguageDefinition(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", flag: "🇻🇳"),
        LanguageDefinition(code: "hmn", name: "Hmong", nativeName: "Hmoob", flag: "HM"),
        LanguageDefinition(code: "ar-MA", name: "Morocco", nativeName: "العربية", flag: "🇲🇦"),
        LanguageDefinition(code: "ar-EG", name: "Egypt", nativeName: "العربية", flag: "🇪🇬"),
        LanguageDefinition(code: "ru", name: "Russian", nativeName: "Русский", flag: "🇷🇺"),
        LanguageDefinition(code: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸"),
        LanguageDefinition(code: "fr", name: "French", nativeName: "Français", flag: "🇫🇷"),
        LanguageDefinition(code: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪"),
        LanguageDefinition(code: "it", name: "Italian", nativeName: "Italiano", flag: "🇮🇹"),
        LanguageDefinition(code: "pt", name: "Portuguese", nativeName: "Português", flag: "🇵🇹"),
        LanguageDefinition(code: "ja", name: "Japanese", nativeName: "日本語", flag: "🇯🇵"),
        LanguageDefinition(code: "ko", name: "Korean", nativeName: "한국어", flag: "🇰🇷"),
        LanguageDefinition(code: "zh-Hans", name: "Chinese Simplified", nativeName: "简体中文", flag: "🇨🇳"),
        LanguageDefinition(code: "zh-Hant", name: "Chinese Traditional", nativeName: "繁體中文", flag: "🇹🇼"),
        LanguageDefinition(code: "th", name: "Thai", nativeName: "ไทย", flag: "🇹🇭"),
        LanguageDefinition(code: "id", name: "Indonesian", nativeName: "Bahasa Indonesia", flag: "🇮🇩"),
        LanguageDefinition(code: "tl", name: "Tagalog", nativeName: "Tagalog", flag: "🇵🇭"),
        LanguageDefinition(code: "hi", name: "Hindi", nativeName: "हिन्दी", flag: "🇮🇳"),
        LanguageDefinition(code: "bn", name: "Bengali", nativeName: "বাংলা", flag: "🇧🇩"),
        LanguageDefinition(code: "ur", name: "Urdu", nativeName: "اردو", flag: "🇵🇰"),
        LanguageDefinition(code: "fa", name: "Persian", nativeName: "فارسی", flag: "🇮🇷"),
        LanguageDefinition(code: "tr", name: "Turkish", nativeName: "Türkçe", flag: "🇹🇷"),
        LanguageDefinition(code: "pl", name: "Polish", nativeName: "Polski", flag: "🇵🇱"),
        LanguageDefinition(code: "uk", name: "Ukrainian", nativeName: "Українська", flag: "🇺🇦"),
        LanguageDefinition(code: "ro", name: "Romanian", nativeName: "Română", flag: "🇷🇴"),
        LanguageDefinition(code: "nl", name: "Dutch", nativeName: "Nederlands", flag: "🇳🇱"),
        LanguageDefinition(code: "sv", name: "Swedish", nativeName: "Svenska", flag: "🇸🇪"),
        LanguageDefinition(code: "da", name: "Danish", nativeName: "Dansk", flag: "🇩🇰"),
        LanguageDefinition(code: "fi", name: "Finnish", nativeName: "Suomi", flag: "🇫🇮"),
        LanguageDefinition(code: "no", name: "Norwegian", nativeName: "Norsk", flag: "🇳🇴")
    ]

    private static let bundles: [String: [String: String]] = [
        "en-US": [
            "app": "Textcavator HUD",
            "subtitle": "Turn any screen into local OCR text",
            "flagMenu": "⚑ Flag Menu",
            "crosshair": "Crosshair\nCapture",
            "window": "Window\nCapture",
            "chipOcr": "Local Vision OCR",
            "chipShortcuts": "Cmd+Shift 1 / 2",
            "chipEffects": "Glass HUD Effects",
            "chipEsc": "Esc cancels cursor",
            "areaReady": "Crosshair capture ready",
            "windowReady": "Window capture ready",
            "scrollReady": "Scroll Ready",
            "streamReady": "Stream Ready",
            "stream": "Stream",
            "cameraReady": "Camera Ready",
            "camera": "Camera",
            "settings": "Settings HUD",
            "settingsSubtitle": "Local OCR routing, capture flags, and glass HUD preferences",
            "captureFlags": "CAPTURE FLAGS",
            "outputMode": "OUTPUT MODE",
            "outputFolder": "OUTPUT FOLDER",
            "preferences": "PREFERENCES",
            "notifications": "Show Notifications",
            "launch": "Launch at Login",
            "sounds": "Soft HUD Sounds",
            "effects": "Particle Effects",
            "done": "Done",
            "browse": "Browse",
            "clipboard": "Clipboard",
            "textFile": "Text File",
            "processing": "Processing...",
            "initializing": "Initializing OCR...",
            "calculating": "Calculating...",
            "complete": "Complete!",
            "cancel": "Cancel",
            "welcome": "Welcome to Textcavator",
            "onboarding": "Textcavator runs OCR locally with Apple Vision.\n\nTo use ⌃⌘⌥1-⌃⌘⌥7, grant:\n1. Screen Recording permission\n2. Accessibility permission for global hotkeys\n3. Camera and Microphone permissions\n\nOpen System Settings now, or choose Later.",
            "openSettings": "Open System Settings",
            "later": "Later",
            "launchNotification": "Press ⌃⌘⌥1 crosshair, ⌃⌘⌥2 window, ⌃⌘⌥3 fullscreen, ⌃⌘⌥4 scroll, ⌃⌘⌥6 stream, ⌃⌘⌥7 camera",
            "copied": "Text copied to clipboard",
            "saved": "Saved to ",
            "failedSave": "Failed to save file: ",
            "privacy": "Textcavator privacy audit: local Vision OCR only; no URLSession, socket, shell, or temp screenshot pipeline detected in active capture path.",
            "languageTitle": "Choose Language",
            "languageSubtitle": "Pick a localized HUD voice. Your selection stays on this Mac.",
            "confirmLanguageTitle": "Activate localized HUD?",
            "confirmLanguageBody": "Textcavator will refresh menus, buttons, progress labels, and settings in %@.",
            "confirm": "Confirm",
            "goBack": "Go Back",
            "downloadCta": "Download Textcavator",
            "downloadSub": "Menu-bar capture → local OCR → clipboard or text file.",
            "support": "Support Path",
            "supportBody": "Send focused feedback: what you captured, what broke, and the result you expected.",
            "roadmap": "Roadmap",
            "roadmapBody": "Prioritized next: multilingual OCR tuning, batch history, and privacy-preserving local analytics.",
            "whitepaper": "ADHD Use Case Brief",
            "whitepaperBody": "Screen text becomes external working memory: capture once, extract instantly, reduce tab switching, and keep the next action visible.",
            "feature": "Feature Requests",
            "featureBody": "Request one outcome at a time with context, frequency, and the workflow it unblocks.",
            "heroHeadline": "Capture screen text with a private AI lens",
            "heroSubheading": "Crosshair or window capture, local Vision OCR, animated HUD feedback, and instant clipboard or text-file output.",
            "statLanguages": "31 languages",
            "statLanguagesCaption": "localized HUD",
            "statModes": "2 modes",
            "statModesCaption": "area + window",
            "statCloud": "0 cloud OCR",
            "statCloudCaption": "private by default",
            "statHotkeys": "2 hotkeys",
            "statHotkeysCaption": "⌃⌘⌥1/2/3/4",
            "statOutput": "2 outputs",
            "statOutputCaption": "clipboard + file",
            "featuresTitle": "Features that feel instant",
            "featureLocal": "Local Vision OCR",
            "featureLocalBody": "Apple Vision extracts text on-device without a cloud OCR hop.",
            "featurePrivate": "Private capture path",
            "featurePrivateBody": "In-memory screen capture avoids temp screenshot files.",
            "featureFast": "Keyboard-first speed",
            "featureFastBody": "Arm crosshair or window capture from the menu bar in one shortcut.",
            "featureGlobal": "Multilingual HUD",
            "featureGlobalBody": "Localized menus, buttons, progress labels, and settings stay on this Mac.",
            "socialProofTitle": "Social proof: private, local, purpose-built",
            "socialProofBody": "Built around local Vision OCR, in-memory capture, and keyboard-first workflows—not cloud scraping."
        ],
        "vi": [
            "app": "Bảng điều khiển Textcavator",
            "subtitle": "Biến bất kỳ màn hình nào thành văn bản OCR cục bộ",
            "flagMenu": "⚑ Ngôn ngữ",
            "crosshair": "Chụp\nVùng chọn",
            "window": "Chụp\nCửa sổ",
            "chipOcr": "OCR Vision cục bộ",
            "chipShortcuts": "Cmd+Shift 1 / 2",
            "chipEffects": "Hiệu ứng HUD kính",
            "chipEsc": "Esc hủy con trỏ",
            "areaReady": "⬚ Sẵn sàng chụp vùng chọn",
            "windowReady": "⊞ Sẵn sàng chụp cửa sổ",
            "settings": "Cài đặt HUD",
            "settingsSubtitle": "Định tuyến OCR cục bộ, cờ chụp và tùy chọn HUD kính",
            "captureFlags": "CỜ CHỤP",
            "outputMode": "CHẾ ĐỘ ĐẦU RA",
            "outputFolder": "THƯ MỤC ĐẦU RA",
            "preferences": "TÙY CHỈNH",
            "notifications": "Hiện thông báo",
            "launch": "Chạy khi đăng nhập",
            "sounds": "Âm HUD nhẹ",
            "effects": "Hiệu ứng hạt",
            "done": "Xong",
            "browse": "Duyệt",
            "clipboard": "Bảng nhớ tạm",
            "textFile": "Tệp văn bản",
            "processing": "Đang xử lý...",
            "initializing": "Khởi tạo OCR...",
            "calculating": "Đang tính...",
            "complete": "Hoàn tất!",
            "cancel": "Hủy",
            "welcome": "Chào mừng đến với Textcavator",
            "onboarding": "Textcavator chạy OCR cục bộ bằng Apple Vision.\n\nĐể dùng ⌃⌘⌥1, ⌃⌘⌥2, ⌃⌘⌥3, ⌃⌘⌥4, hãy cấp:\n1. Quyền ghi màn hình\n2. Quyền Trợ năng cho phím nóng toàn cục\n\nMở Cài đặt hệ thống ngay, hoặc chọn Sau.",
            "openSettings": "Mở Cài đặt hệ thống",
            "later": "Sau",
            "launchNotification": "Nhấn ⌃⌘⌥1-4 để chụp",
            "copied": "Đã sao chép văn bản vào bảng nhớ tạm",
            "saved": "Đã lưu vào ",
            "failedSave": "Không lưu được tệp: ",
            "privacy": "Kiểm tra quyền riêng tư Textcavator: OCR Vision cục bộ; không có đường dẫn URLSession, socket, shell hoặc ảnh chụp tạm trong quy trình chụp hiện hoạt.",
            "languageTitle": "Chọn ngôn ngữ",
            "languageSubtitle": "Chọn giọng HUD bản địa. Lựa chọn của bạn chỉ lưu trên Mac này.",
            "confirmLanguageTitle": "Kích hoạt HUD bản địa?",
            "confirmLanguageBody": "Textcavator sẽ làm mới menu, nút, nhãn tiến trình và cài đặt bằng %@.",
            "confirm": "Xác nhận",
            "goBack": "Quay lại",
            "downloadCta": "Tải Textcavator",
            "downloadSub": "Chụp từ thanh menu → OCR cục bộ → bảng nhớ tạm hoặc tệp văn bản.",
            "support": "Đường hỗ trợ",
            "supportBody": "Gửi phản hồi tập trung: bạn đã chụp gì, lỗi gì xảy ra, và kết quả mong đợi.",
            "roadmap": "Lộ trình",
            "roadmapBody": "Ưu tiên tiếp: tinh chỉnh OCR đa ngôn ngữ, lịch sử theo lô và phân tích cục bộ bảo vệ quyền riêng tư.",
            "whitepaper": "Tóm tắt dùng cho ADHD",
            "whitepaperBody": "Văn bản màn hình trở thành bộ nhớ làm việc bên ngoài: chụp một lần, trích xuất ngay, giảm chuyển tab và giữ hành động tiếp theo hiển thị.",
            "feature": "Yêu cầu tính năng",
            "featureBody": "Yêu cầu từng kết quả một kèm ngữ cảnh, tần suất và quy trình bị chặn.",
            "heroHeadline": "Chụp văn bản màn hình bằng ống kính AI riêng tư",
            "heroSubheading": "Chụp vùng chọn hoặc cửa sổ, OCR Vision cục bộ, HUD hoạt ảnh và xuất ngay vào clipboard hoặc tệp văn bản.",
            "statLanguages": "31 ngôn ngữ",
            "statLanguagesCaption": "HUD bản địa",
            "statModes": "2 chế độ",
            "statModesCaption": "vùng + cửa sổ",
            "statCloud": "0 OCR đám mây",
            "statCloudCaption": "riêng tư mặc định",
            "statHotkeys": "2 phím tắt",
            "statHotkeysCaption": "⌃⌘⌥1/2/3/4",
            "statOutput": "2 đầu ra",
            "statOutputCaption": "clipboard + tệp",
            "featuresTitle": "Các tính năng tức thì",
            "featureLocal": "OCR Vision cục bộ",
            "featureLocalBody": "Apple Vision trích xuất văn bản trên thiết bị mà không gửi lên đám mây.",
            "featurePrivate": "Đường chụp riêng tư",
            "featurePrivateBody": "Chụp màn hình trong bộ nhớ, tránh tệp ảnh tạm.",
            "featureFast": "Tốc độ bàn phím",
            "featureFastBody": "Kích hoạt chụp vùng hoặc cửa sổ từ thanh menu bằng một phím tắt.",
            "featureGlobal": "HUD đa ngôn ngữ",
            "featureGlobalBody": "Menu, nút, nhãn tiến trình và cài đặt bản địa chỉ lưu trên Mac này.",
            "socialProofTitle": "Social proof: riêng tư, cục bộ, đúng mục đích",
            "socialProofBody": "Thiết kế quanh OCR Vision cục bộ, chụp trong bộ nhớ và workflow bàn phím—không cào đám mây."
        ],
        "hmn": [
            "app": "Textcavator HUD",
            "subtitle": "Hloov ib qho screen los ua OCR cov ntawv hauv koj lub Mac",
            "flagMenu": "⚑ Hom lus",
            "crosshair": "Capture\nCheeb tsam",
            "window": "Capture\nQhov window",
            "chipOcr": "Vision OCR hauv zos",
            "chipShortcuts": "Cmd+Shift 1 / 2",
            "chipEffects": "Glass HUD effects",
            "chipEsc": "Esc txiav cursor",
            "areaReady": "⬚ Cheeb tsam npuaj tau",
            "windowReady": "⊞ Qhov window npuaj tau",
            "settings": "Settings HUD",
            "settingsSubtitle": "OCR routing, capture flags, thiab glass HUD preferences",
            "captureFlags": "CAPTURE FLAGS",
            "outputMode": "OUTPUT MODE",
            "outputFolder": "OUTPUT FOLDER",
            "preferences": "PREFERENCES",
            "notifications": "Show Notifications",
            "launch": "Launch at Login",
            "sounds": "Soft HUD Sounds",
            "effects": "Particle Effects",
            "done": "Done",
            "browse": "Browse",
            "clipboard": "Clipboard",
            "textFile": "Text File",
            "processing": "Processing...",
            "initializing": "Initializing OCR...",
            "calculating": "Calculating...",
            "complete": "Complete!",
            "cancel": "Cancel",
            "welcome": "Zoo siab txais tos Textcavator",
            "onboarding": "Textcavator siv Apple Vision OCR hauv koj lub Mac xwb.\n\nKom siv ⌃⌘⌥1-4, cia permissions rau:\n1. Screen Recording\n2. Accessibility rau global hotkeys\n\nQhib System Settings os, lossis xaiv Later.",
            "openSettings": "Qhib System Settings",
            "later": "Later",
            "launchNotification": "Nyem ⌃⌘⌥1-4 capture",
            "copied": "Copied text rau clipboard",
            "saved": "Saved to ",
            "failedSave": "Failed to save file: ",
            "privacy": "Privacy audit: local Vision OCR xwb; tsis muaj URLSession, socket, shell, los yog temp screenshot pipeline.",
            "languageTitle": "Xaiv hom lus",
            "languageSubtitle": "Xaiv ib hom HUD voice. Koj txoj kev xaiv nyob hauv Mac no xwb.",
            "confirmLanguageTitle": "Activate localized HUD?",
            "confirmLanguageBody": "Textcavator yuav hloov menus, buttons, progress labels, thiab settings rau %@.",
            "confirm": "Confirm",
            "goBack": "Go Back",
            "downloadCta": "Download Textcavator",
            "downloadSub": "Menu-bar capture → local OCR → clipboard lossis text file.",
            "support": "Support Path",
            "supportBody": "Thov feedback nrog context: koj capture dab tsi, dab tsi tsis ua, thiab koj xav tau result.",
            "roadmap": "Roadmap",
            "roadmapBody": "Priority tom ntej: multilingual OCR tuning, batch history, thiab privacy-preserving local analytics.",
            "whitepaper": "ADHD Use Case Brief",
            "whitepaperBody": "Screen text ua ib qho external working memory: capture ib zaug, extract sai, txo tab switching, thiab khaws next action pom.",
            "feature": "Feature Requests",
            "featureBody": "Thov ib outcome ib zaug nrog context, frequency, thiab workflow uas nws unblocks.",
            "heroHeadline": "Capture screen text with a private AI lens",
            "heroSubheading": "Crosshair or window capture, local Vision OCR, animated HUD feedback, and instant clipboard or text-file output.",
            "statLanguages": "31 hom lus",
            "statLanguagesCaption": "localized HUD",
            "statModes": "2 modes",
            "statModesCaption": "area + window",
            "statCloud": "0 cloud OCR",
            "statCloudCaption": "private by default",
            "statHotkeys": "2 hotkeys",
            "statHotkeysCaption": "⌃⌘⌥1/2/3/4",
            "statOutput": "2 outputs",
            "statOutputCaption": "clipboard + file",
            "featuresTitle": "Features that feel instant",
            "featureLocal": "Local Vision OCR",
            "featureLocalBody": "Apple Vision extracts text on-device without a cloud OCR hop.",
            "featurePrivate": "Private capture path",
            "featurePrivateBody": "In-memory screen capture avoids temp screenshot files.",
            "featureFast": "Keyboard-first speed",
            "featureFastBody": "Arm crosshair or window capture from the menu bar in one shortcut.",
            "featureGlobal": "Multilingual HUD",
            "featureGlobalBody": "Localized menus, buttons, progress labels, and settings stay on this Mac.",
            "socialProofTitle": "Social proof: private, local, purpose-built",
            "socialProofBody": "Built around local Vision OCR, in-memory capture, and keyboard-first workflows—not cloud scraping."
        ],
        "ru": [
            "app": "HUD Textcavator",
            "subtitle": "Превращает любой экран в локальный OCR-текст",
            "flagMenu": "⚑ Язык",
            "crosshair": "Область\nэкрана",
            "window": "Окно\nэкрана",
            "chipOcr": "Локальный Vision OCR",
            "chipShortcuts": "Cmd+Shift 1 / 2",
            "chipEffects": "Стеклянный HUD",
            "chipEsc": "Esc отменяет курсор",
            "areaReady": "⬚ Готово к выбору области",
            "windowReady": "⊞ Готово к выбору окна",
            "settings": "Настройки HUD",
            "settingsSubtitle": "Локальная OCR-маршрутизация, флаги захвата и настройки glass HUD",
            "captureFlags": "ФЛАГИ ЗАХВАТА",
            "outputMode": "РЕЖИМ ВЫВОДА",
            "outputFolder": "ПАПКА ВЫВОДА",
            "preferences": "НАСТРОЙКИ",
            "notifications": "Показывать уведомления",
            "launch": "Запускать при входе",
            "sounds": "Мягкие звуки HUD",
            "effects": "Частицы",
            "done": "Готово",
            "browse": "Обзор",
            "clipboard": "Буфер обмена",
            "textFile": "Текстовый файл",
            "processing": "Обработка...",
            "initializing": "Инициализация OCR...",
            "calculating": "Расчет...",
            "complete": "Готово!",
            "cancel": "Отмена",
            "welcome": "Добро пожаловать в Textcavator",
            "onboarding": "Textcavator выполняет OCR локально через Apple Vision.\n\nДля ⌃⌘⌥1-4 нужны:\n1. Разрешение записи экрана\n2. Разрешение универсального доступа для горячих клавиш\n\nОткройте настройки системы сейчас или выберите позже.",
            "openSettings": "Открыть настройки системы",
            "later": "Позже",
            "launchNotification": "Нажмите ⌃⌘⌥1-4",
            "copied": "Текст скопирован в буфер обмена",
            "saved": "Сохранено в ",
            "failedSave": "Не удалось сохранить файл: ",
            "privacy": "Проверка приватности Textcavator: только локальный Vision OCR; нет URLSession, socket, shell или временного скриншот-пайплайна.",
            "languageTitle": "Выберите язык",
            "languageSubtitle": "Выберите локализованный голос HUD. Настройка хранится только на этом Mac.",
            "confirmLanguageTitle": "Активировать локализованный HUD?",
            "confirmLanguageBody": "Textcavator обновит меню, кнопки, подписи прогресса и настройки на %@.",
            "confirm": "Подтвердить",
            "goBack": "Назад",
            "downloadCta": "Скачать Textcavator",
            "downloadSub": "Захват из строки меню → локальный OCR → буфер обмена или текстовый файл.",
            "support": "Поддержка",
            "supportBody": "Отправьте точную обратную связь: что захватили, что сломалось и какой результат ожидали.",
            "roadmap": "Дорожная карта",
            "roadmapBody": "Далее: настройка многоязычного OCR, пакетная история и локальная аналитика с сохранением приватности.",
            "whitepaper": "Сценарий для ADHD",
            "whitepaperBody": "Текст экрана становится внешней рабочей памятью: один захват, мгновенное извлечение, меньше переключений вкладок и видимое следующее действие.",
            "feature": "Запросы функций",
            "featureBody": "Запрашивайте один результат за раз с контекстом, частотой и рабочим процессом, который он разблокирует.",
            "heroHeadline": "Захват текста с экрана через приватную AI-линзу",
            "heroSubheading": "Выбор области или окна, локальный Vision OCR, анимированный HUD и мгновенный вывод в буфер или текстовый файл.",
            "statLanguages": "31 язык",
            "statLanguagesCaption": "локальный HUD",
            "statModes": "2 режима",
            "statModesCaption": "область + окно",
            "statCloud": "0 cloud OCR",
            "statCloudCaption": "приватно",
            "statHotkeys": "2 hotkeys",
            "statHotkeysCaption": "⌃⌘⌥1/2/3/4",
            "statOutput": "2 вывода",
            "statOutputCaption": "буфер + файл",
            "featuresTitle": "Мгновенные функции",
            "featureLocal": "Локальный Vision OCR",
            "featureLocalBody": "Apple Vision извлекает текст на устройстве без облачного OCR.",
            "featurePrivate": "Приватный захват",
            "featurePrivateBody": "Снимок хранится в памяти, без временных файлов.",
            "featureFast": "Скорость с клавиатуры",
            "featureFastBody": "Один хоткей из строки меню включает область или окно.",
            "featureGlobal": "Многоязычный HUD",
            "featureGlobalBody": "Локализованные меню, кнопки, прогресс и настройки остаются на этом Mac.",
            "socialProofTitle": "Социальное доказательство: приватно, локально, по делу",
            "socialProofBody": "Основа: локальный Vision OCR, снимки в памяти и работа с клавиатуры — без облачного скрейпинга."
        ]
    ]

    static func value(_ key: String, languageCode: String = SettingsManager.shared.languageCode) -> String {
        if let value = bundles[languageCode]?[key] {
            return value
        }
        return bundles["en-US"]?[key] ?? key
    }

    static func languageDefinition(for code: String) -> LanguageDefinition {
        languages.first { $0.code == code } ?? languages.first!
    }
}

class CyberpunkButton: NSButton {
    var glowColor: NSColor = HUDPalette.cyan { didSet { updateGlow(); updateTitleAttributes() } }
    var isSelected: Bool = false { didSet { updateGlow(); updateTitleAttributes() } }

    fileprivate var isHovered = false
    private var isPressed = false
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }

    private func setupStyle() {
        wantsLayer = true
        isBordered = false
        layer?.cornerRadius = 10
        layer?.masksToBounds = false
        updateGlow()
        updateTitleAttributes()
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        trackingArea = area
        addTrackingArea(area)
    }

    private func updateTitleAttributes() {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let font = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        let foreground = isSelected ? NSColor.white : (isHovered ? NSColor.white.withAlphaComponent(0.96) : NSColor.white.withAlphaComponent(0.86))
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: font,
            .foregroundColor: foreground,
            .paragraphStyle: style,
            .kern: 0.15
        ])
    }

    private func updateGlow() {
        let borderAlpha: CGFloat = isSelected ? 1.0 : (isHovered ? 0.9 : 0.42)
        let shadowAlpha: CGFloat = isSelected ? 0.72 : (isHovered ? 0.55 : 0.28)
        let scale: CGFloat = isPressed ? 0.97 : (isSelected ? 1.015 : 1.0)
        layer?.borderColor = glowColor.withAlphaComponent(borderAlpha).cgColor
        layer?.borderWidth = isSelected ? 1.6 : 1.0
        layer?.shadowColor = glowColor.cgColor
        layer?.shadowRadius = isSelected ? 18 : (isHovered ? 15 : 10)
        layer?.shadowOpacity = Float(shadowAlpha)
        layer?.shadowOffset = CGSize(width: 0, height: isSelected || isHovered ? -1 : 0)
        layer?.transform = CATransform3DMakeScale(scale, scale, 1)
    }

    func pulse() {
        guard !isPressed else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer?.transform = CATransform3DMakeScale(1.035, 1.035, 1)
        } completionHandler: { [weak self] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self?.layer?.transform = CATransform3DMakeScale(self?.isSelected == true ? 1.015 : 1.0, self?.isSelected == true ? 1.015 : 1.0, 1)
            }
        }
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        UXSoundPlayer.shared.play(.hover)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.allowsImplicitAnimation = true
            updateGlow()
            updateTitleAttributes()
        }
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.allowsImplicitAnimation = true
            updateGlow()
            updateTitleAttributes()
        }
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        updateGlow()
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        isPressed = false
        pulse()
        updateGlow()
        super.mouseUp(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        let inset: CGFloat = isPressed ? 1.5 : 0
        let rect = dirtyRect.insetBy(dx: inset, dy: inset)
        let gradient = NSGradient(colors: [
            NSColor(white: 0.18, alpha: 0.92),
            NSColor(white: 0.075, alpha: 0.94),
            glowColor.withAlphaComponent(isSelected ? 0.22 : 0.12)
        ])
        gradient?.draw(in: rect, angle: 112)

        let inner = rect.insetBy(dx: 1, dy: 1)
        let innerGradient = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.11),
            NSColor.clear
        ])
        innerGradient?.draw(in: NSRect(x: inner.minX, y: inner.maxY - 8, width: inner.width, height: 8), angle: 90)

        let borderPath = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        borderPath.lineWidth = isSelected ? 1.8 : 1
        glowColor.withAlphaComponent(isSelected ? 0.95 : 0.55).setStroke()
        borderPath.stroke()

        super.draw(dirtyRect)
    }
}

class CyberpunkTextField: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }

    private func setupStyle() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor(white: 0.08, alpha: 0.72).cgColor
        layer?.borderColor = HUDPalette.cyan.withAlphaComponent(0.32).cgColor
        layer?.borderWidth = 1
        textColor = .white
        font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        backgroundColor = .clear
        isBordered = false
        focusRingType = .none
    }
}

class CyberpunkSegmentedControl: NSSegmentedControl {
    var selectedGlowColor: NSColor = HUDPalette.cyan { didSet { updateStyle() } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }

    private func setupStyle() {
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = false
        updateStyle()
    }

    private func updateStyle() {
        layer?.backgroundColor = NSColor(white: 0.08, alpha: 0.82).cgColor
        layer?.borderColor = selectedGlowColor.withAlphaComponent(0.35).cgColor
        layer?.borderWidth = 1
        layer?.shadowColor = selectedGlowColor.cgColor
        layer?.shadowRadius = 12
        layer?.shadowOpacity = 0.25
        for i in 0..<segmentCount {
            setWidth(CGFloat(bounds.width / CGFloat(segmentCount)) - 6, forSegment: i)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let segmentWidth = (bounds.width - 10) / CGFloat(segmentCount)
        for i in 0..<segmentCount {
            let rect = NSRect(x: 5 + CGFloat(i) * segmentWidth, y: 3, width: segmentWidth, height: bounds.height - 6)
            if i == selectedSegment {
                let gradient = NSGradient(colors: [selectedGlowColor.withAlphaComponent(0.34), selectedGlowColor.withAlphaComponent(0.12)])
                gradient?.draw(in: rect, angle: 90)
                let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
                selectedGlowColor.withAlphaComponent(0.8).setStroke()
                path.lineWidth = 1
                path.stroke()
            }
        }
        super.draw(dirtyRect)
    }
}

class CyberpunkProgressBar: NSView {
    var progress: CGFloat = 0 { didSet { updateProgress() } }
    var glowColor: NSColor = HUDPalette.cyan { didSet { updateColors() } }

    private var progressLayer: CAGradientLayer!
    private var glowLayer: CALayer!
    private var shimmerLayer: CAGradientLayer!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor(white: 0.08, alpha: 0.82).cgColor
        layer?.borderColor = glowColor.withAlphaComponent(0.3).cgColor
        layer?.borderWidth = 1

        glowLayer = CALayer()
        glowLayer.cornerRadius = 8
        glowLayer.shadowColor = glowColor.cgColor
        glowLayer.shadowRadius = 10
        glowLayer.shadowOpacity = 0.5
        glowLayer.shadowOffset = .zero
        layer?.addSublayer(glowLayer)

        progressLayer = CAGradientLayer()
        progressLayer.cornerRadius = 6
        progressLayer.startPoint = CGPoint(x: 0, y: 0.5)
        progressLayer.endPoint = CGPoint(x: 1, y: 0.5)
        updateColors()
        glowLayer.addSublayer(progressLayer)

        shimmerLayer = CAGradientLayer()
        shimmerLayer.colors = [NSColor.clear.cgColor, NSColor.white.withAlphaComponent(0.35).cgColor, NSColor.clear.cgColor]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.locations = [0, 0.5, 1]
        progressLayer.addSublayer(shimmerLayer)

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.6
        animation.repeatCount = .infinity
        shimmerLayer.add(animation, forKey: "shimmer")
    }

    private func updateColors() {
        progressLayer?.colors = [glowColor.withAlphaComponent(0.55).cgColor, glowColor.cgColor, glowColor.withAlphaComponent(0.78).cgColor]
        glowLayer?.shadowColor = glowColor.cgColor
        layer?.borderColor = glowColor.withAlphaComponent(0.3).cgColor
    }

    private func updateProgress() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.28)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        let clampedProgress = max(0, min(1, progress))
        let progressWidth = (bounds.width - 8) * clampedProgress
        progressLayer.frame = CGRect(x: 4, y: 4, width: progressWidth, height: bounds.height - 8)
        CATransaction.commit()
    }

    func setProgress(_ value: CGFloat, animated: Bool) {
        if animated {
            progress = value
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progress = value
            CATransaction.commit()
        }
    }

    override func layout() {
        super.layout()
        glowLayer.frame = bounds
        updateProgress()
    }
}

class CyberpunkCard: NSView {
    var glowColor: NSColor = HUDPalette.cyan { didSet { updateGlow() } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }

    private func setupStyle() {
        wantsLayer = true
        layer?.cornerRadius = 18
        layer?.backgroundColor = HUDPalette.panel.cgColor
        layer?.borderWidth = 0

        let borderGradient = CAGradientLayer()
        borderGradient.frame = bounds
        borderGradient.cornerRadius = 18
        borderGradient.colors = [glowColor.withAlphaComponent(0.7).cgColor, glowColor.withAlphaComponent(0.08).cgColor, glowColor.withAlphaComponent(0.08).cgColor, glowColor.withAlphaComponent(0.7).cgColor]
        borderGradient.startPoint = CGPoint(x: 0, y: 0)
        borderGradient.endPoint = CGPoint(x: 1, y: 1)
        borderGradient.type = .axial
        let borderMask = CAShapeLayer()
        borderMask.lineWidth = 2
        borderMask.path = CGPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerWidth: 18, cornerHeight: 18, transform: nil)
        borderGradient.mask = borderMask
        layer?.addSublayer(borderGradient)

        let inner = CALayer()
        inner.frame = bounds.insetBy(dx: 2, dy: 2)
        inner.cornerRadius = 16
        inner.backgroundColor = NSColor(white: 1, alpha: 0.055).cgColor
        layer?.addSublayer(inner)

        updateGlow()
    }

    private func updateGlow() {
        layer?.shadowColor = glowColor.cgColor
        layer?.shadowRadius = 24
        layer?.shadowOpacity = 0.34
        layer?.shadowOffset = CGSize(width: 0, height: 0)
    }

    override func layout() {
        super.layout()
        if let borderGradient = layer?.sublayers?.first as? CAGradientLayer {
            borderGradient.frame = bounds
            if let borderMask = borderGradient.mask as? CAShapeLayer {
                borderMask.path = CGPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerWidth: 18, cornerHeight: 18, transform: nil)
            }
        }
    }
}

class HUDGridBackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let bg = NSGradient(colors: [NSColor(white: 0.035, alpha: 0.96), NSColor(white: 0.015, alpha: 0.98)])
        bg?.draw(in: bounds, angle: 105)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.setLineWidth(0.45)

        var x = bounds.minX.truncatingRemainder(dividingBy: 24)
        while x <= bounds.maxX {
            context.setStrokeColor(NSColor(calibratedRed: 0.0, green: 0.9, blue: 1.0, alpha: 0.055).cgColor)
            context.beginPath()
            context.move(to: CGPoint(x: x, y: bounds.minY))
            context.addLine(to: CGPoint(x: x, y: bounds.maxY))
            context.strokePath()
            x += 24
        }

        var y = bounds.minY.truncatingRemainder(dividingBy: 24)
        while y <= bounds.maxY {
            context.setStrokeColor(NSColor(calibratedRed: 0.6, green: 0.25, blue: 1.0, alpha: 0.045).cgColor)
            context.beginPath()
            context.move(to: CGPoint(x: bounds.minX, y: y))
            context.addLine(to: CGPoint(x: bounds.maxX, y: y))
            context.strokePath()
            y += 24
        }

        let scan = NSGradient(colors: [NSColor.clear, NSColor.white.withAlphaComponent(0.035), NSColor.clear])
        scan?.draw(in: NSRect(x: bounds.minX, y: bounds.minY + 12, width: bounds.width, height: 2), angle: 0)
        context.restoreGState()
    }
}

struct Particle {
    var position: CGPoint
    var velocity: CGPoint
    var radius: CGFloat
    var color: NSColor
    var life: CGFloat
    var maxLife: CGFloat
    var shape: Int
}

class ParticleBurstView: NSView {
    private var particles: [Particle] = []
    private var timer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        alphaValue = 0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        alphaValue = 0
    }

    func startBurst(colors: [NSColor] = [HUDPalette.cyan, HUDPalette.mint, HUDPalette.violet, HUDPalette.rose, HUDPalette.amber]) {
        timer?.invalidate()
        particles.removeAll()
        alphaValue = 1
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let count = 58
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 0.7...3.8)
            let maxLife = CGFloat.random(in: 0.45...0.9)
            particles.append(Particle(
                position: center,
                velocity: CGPoint(x: cos(angle) * speed, y: sin(angle) * speed),
                radius: CGFloat.random(in: 1.2...4.8),
                color: colors.randomElement() ?? HUDPalette.cyan,
                life: maxLife,
                maxLife: maxLife,
                shape: Int.random(in: 0...2)
            ))
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        for index in particles.indices {
            var particle = particles[index]
            particle.life -= 1.0 / 60.0
            particle.position.x += particle.velocity.x
            particle.position.y += particle.velocity.y
            particle.velocity.y -= 0.018
            particle.velocity.x *= 0.992
            particle.velocity.y *= 0.992
            particles[index] = particle
        }
        particles.removeAll { $0.life <= 0 }
        setNeedsDisplay(bounds)
        if particles.isEmpty {
            stopBurst()
        }
    }

    private func stopBurst() {
        timer?.invalidate()
        timer = nil
        alphaValue = 0
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        for particle in particles {
            let alpha = max(0, min(1, particle.life / particle.maxLife))
            let color = particle.color.withAlphaComponent(alpha * 0.78)
            let rect = CGRect(x: particle.position.x - particle.radius, y: particle.position.y - particle.radius, width: particle.radius * 2, height: particle.radius * 2)
            color.setFill()
            if particle.shape == 1 {
                let path = NSBezierPath()
                path.move(to: CGPoint(x: particle.position.x, y: particle.position.y + particle.radius))
                path.line(to: CGPoint(x: particle.position.x + particle.radius, y: particle.position.y))
                path.line(to: CGPoint(x: particle.position.x, y: particle.position.y - particle.radius))
                path.line(to: CGPoint(x: particle.position.x - particle.radius, y: particle.position.y))
                path.close()
                path.fill()
            } else if particle.shape == 2 {
                let gradient = CGGradient(colorsSpace: nil, colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
                context.drawRadialGradient(gradient, startCenter: particle.position, startRadius: 0, endCenter: particle.position, endRadius: particle.radius * 4, options: [])
            } else {
                NSBezierPath(ovalIn: rect).fill()
            }
        }
        context.restoreGState()
    }
}

class CaptureEffectWindow: NSWindow {
    private let particleView = ParticleBurstView()

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingBackType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingBackType, defer: flag)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = particleView
    }

    func show(at rect: NSRect, mode: CaptureMode) {
        let padded = rect.insetBy(dx: -10, dy: -10)
        setFrame(padded, display: true)
        particleView.frame = contentView?.bounds ?? CGRect(origin: .zero, size: frame.size)
        particleView.startBurst(colors: mode == .area ? [HUDPalette.cyan, HUDPalette.mint, HUDPalette.amber] : [HUDPalette.violet, HUDPalette.rose, HUDPalette.cyan])
        orderFrontRegardless()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) { [weak self] in
            self?.close()
        }
    }
}

struct CaptureWindowInfo {
    let id: CGWindowID
    let frame: CGRect
    let ownerName: String
}

class CaptureSelectionView: NSView {
    var mode: CaptureMode = .area
    var windows: [CaptureWindowInfo] = []
    var hoveredWindow: CaptureWindowInfo?
    var anchorPoint: CGPoint?
    var currentPoint: CGPoint = .zero
    var onCancel: (() -> Void)?
    var onCaptureRect: ((CGRect) -> Void)?
    var onCaptureWindow: ((CGWindowID, CGRect) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        currentPoint = convert(NSEvent.mouseLocation, from: nil)
    }

    override func mouseMoved(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        hoveredWindow = findWindow(at: currentPoint)
        setNeedsDisplay(bounds)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if mode == .window || mode == .scroll {
            if let window = findWindow(at: point) {
                onCaptureWindow?(window.id, window.frame)
            } else {
                onCancel?()
            }
        } else {
            anchorPoint = point
            currentPoint = point
            setNeedsDisplay(bounds)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
        guard mode == .area, let start = anchorPoint else { return }
        let end = convert(event.locationInWindow, from: nil)
        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        if rect.width < 10 || rect.height < 10 {
            onCancel?()
            return
        }
        onCaptureRect?(rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.58).setFill()
        NSBezierPath(rect: bounds).fill()

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()

        drawGrid(in: bounds, context: context)

        if mode == .area, let start = anchorPoint {
            let rect = CGRect(x: min(start.x, currentPoint.x), y: min(start.y, currentPoint.y), width: abs(currentPoint.x - start.x), height: abs(currentPoint.y - start.y))
            drawSelection(rect, context: context)
        }

        if mode == .window, let window = hoveredWindow {
            drawWindowHighlight(window.frame, context: context)
        }

        if mode == .scroll, let window = hoveredWindow {
            drawScrollHighlight(window.frame, context: context)
        }

        let mouse = currentPoint
        context.setStrokeColor(HUDPalette.cyan.withAlphaComponent(0.78).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 6])
        context.beginPath()
        context.move(to: CGPoint(x: mouse.x, y: bounds.minY))
        context.addLine(to: CGPoint(x: mouse.x, y: bounds.maxY))
        context.move(to: CGPoint(x: bounds.minX, y: mouse.y))
        context.addLine(to: CGPoint(x: bounds.maxX, y: mouse.y))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        let crosshairSize: CGFloat = 18
        context.setStrokeColor(HUDPalette.mint.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(2)
        context.beginPath()
        context.move(to: CGPoint(x: mouse.x - crosshairSize, y: mouse.y))
        context.addLine(to: CGPoint(x: mouse.x - 5, y: mouse.y))
        context.move(to: CGPoint(x: mouse.x + 5, y: mouse.y))
        context.addLine(to: CGPoint(x: mouse.x + crosshairSize, y: mouse.y))
        context.move(to: CGPoint(x: mouse.x, y: mouse.y - crosshairSize))
        context.addLine(to: CGPoint(x: mouse.x, y: mouse.y - 5))
        context.move(to: CGPoint(x: mouse.x, y: mouse.y + 5))
        context.addLine(to: CGPoint(x: mouse.x, y: mouse.y + crosshairSize))
        context.strokePath()

        context.restoreGState()
    }

    private func drawGrid(in rect: NSRect, context: CGContext) {
        context.saveGState()
        context.setLineWidth(0.5)
        var x = rect.minX.truncatingRemainder(dividingBy: 28)
        while x <= rect.maxX {
            context.setStrokeColor(HUDPalette.cyan.withAlphaComponent(0.045).cgColor)
            context.beginPath()
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            context.strokePath()
            x += 28
        }
        var y = rect.minY.truncatingRemainder(dividingBy: 28)
        while y <= rect.maxY {
            context.setStrokeColor(HUDPalette.violet.withAlphaComponent(0.04).cgColor)
            context.beginPath()
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.strokePath()
            y += 28
        }
        context.restoreGState()
    }

    private func drawSelection(_ rect: CGRect, context: CGContext) {
        let fill = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.08)
        fill.setFill()
        NSBezierPath(rect: rect).fill()

        context.setStrokeColor(HUDPalette.cyan.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(2)
        context.setShadow(offset: .zero, blur: 14, color: HUDPalette.cyan.cgColor)
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        path.stroke()
        context.setShadow(offset: .zero, blur: 0)

        context.setStrokeColor(HUDPalette.mint.withAlphaComponent(0.9).cgColor)
        context.setLineWidth(1)
        path.lineWidth = 1
        path.stroke()
    }

    private func drawWindowHighlight(_ rect: CGRect, context: CGContext) {
        let fill = NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 0.1)
        fill.setFill()
        NSBezierPath(rect: rect).fill()

        context.setStrokeColor(HUDPalette.violet.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(2)
        context.setShadow(offset: .zero, blur: 18, color: HUDPalette.violet.cgColor)
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        path.stroke()
        context.setShadow(offset: .zero, blur: 0)
    }

    private func drawScrollHighlight(_ rect: CGRect, context: CGContext) {
        let fill = NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.22, alpha: 0.1)
        fill.setFill()
        NSBezierPath(rect: rect).fill()

        context.setStrokeColor(HUDPalette.amber.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(3)
        context.setShadow(offset: .zero, blur: 22, color: HUDPalette.amber.cgColor)
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        path.stroke()
        context.setShadow(offset: .zero, blur: 0)

        let label = "SCROLL"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: HUDPalette.amber
        ]
        let size = label.size(withAttributes: attributes)
        let labelRect = NSRect(x: rect.midX - size.width / 2, y: rect.minY - 24, width: size.width, height: size.height)
        label.draw(in: labelRect, withAttributes: attributes)
    }

    private func findWindow(at point: CGPoint) -> CaptureWindowInfo? {
        let screenHeight = NSScreen.screens.first?.frame.maxY ?? point.y
        let topY = screenHeight - point.y
        let cursor = CGPoint(x: point.x, y: topY)
        return windows.first { $0.frame.contains(cursor) }
    }
}

class CaptureOverlayController {
    static let shared = CaptureOverlayController()

    private var overlayWindow: NSWindow?
    private var selectionView: CaptureSelectionView?
    private var eventMonitor: Any?
    private var onCapture: ((NSImage?) -> Void)?
    private var mode: CaptureMode = .area

    private init() {}

    func start(mode: CaptureMode, onCapture: @escaping (NSImage?) -> Void) {
        cancel(silent: true)
        self.mode = mode
        self.onCapture = onCapture

        let screens = NSScreen.screens
        guard let first = screens.first else {
            onCapture(nil)
            return
        }
        var frame = first.frame
        screens.dropFirst().forEach { frame = frame.union($0.frame) }

        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.hidesOnDeactivate = false

        let view = CaptureSelectionView(frame: frame)
        view.mode = mode
        view.windows = queryWindows()
        view.onCancel = { [weak self] in self?.cancel() }
        view.onCaptureRect = { [weak self] rect in self?.captureArea(rect) }

        if mode == .scroll {
            view.onCaptureWindow = { [weak self] id, frame in
                self?.startScrollCapture(windowID: id, frame: frame)
            }
        } else if mode == .stream {
            view.onCaptureWindow = { [weak self] _, frame in
                self?.startStreamCapture(rect: frame)
            }
        } else if mode == .camera {
            cancel(silent: true)
            startCameraCapture()
        } else {
            view.onCaptureWindow = { [weak self] id, frame in self?.captureWindow(id, frame) }
        }
        window.contentView = view

        overlayWindow = window
        selectionView = view

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 {
                self?.cancel()
                return nil
            }
            return event
        }

        window.orderFrontRegardless()
        window.makeKey()
        UXSoundPlayer.shared.play(.arm)
    }

    func cancel(silent: Bool = false) {
        if !silent {
            UXSoundPlayer.shared.play(.cancel)
        }
        eventMonitor.flatMap { NSEvent.removeMonitor($0) }
        eventMonitor = nil
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        selectionView = nil
        onCapture = nil
    }

    private func captureArea(_ rect: CGRect) {
        guard let window = overlayWindow else { return }
        let image = captureAreaImage(rect, from: window)
        finish(with: image, effectRect: screenRectToBottomLeft(rect))
    }

    private func captureWindow(_ id: CGWindowID, _ fallbackRect: CGRect) {
        guard let window = overlayWindow else { return }
        let image = captureWindowImage(id, fallbackRect: fallbackRect, from: window)
        finish(with: image, effectRect: screenRectToBottomLeft(fallbackRect))
    }

    private func startScrollCapture(windowID: CGWindowID, frame: CGRect) {
        let originalOnCapture = onCapture
        onCapture = nil
        cancel(silent: true)

        ScrollCaptureController.shared.startCapture(windowID: windowID, frame: frame) { [weak self] progress, fraction in
        } onComplete: { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    let effectRect = self?.screenRectToBottomLeft(frame) ?? .zero
                    if SettingsManager.shared.effectsEnabled {
                        CaptureEffectWindow().show(at: effectRect, mode: .scroll)
                    }
                }
                originalOnCapture?(image)
            }
        }
    }

    private func finish(with image: NSImage?, effectRect: NSRect) {
        let capturedImage = image
        eventMonitor.flatMap { NSEvent.removeMonitor($0) }
        eventMonitor = nil
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        selectionView = nil

        if SettingsManager.shared.effectsEnabled, let _ = capturedImage {
            CaptureEffectWindow().show(at: effectRect, mode: mode)
        }
        UXSoundPlayer.shared.play(.capture)
        onCapture?(capturedImage)
        onCapture = nil
    }

    private func startStreamCapture(rect: CGRect) {
        cancel(silent: true)
        guard let screen = NSScreen.main else { return }
        let displayID = screen.displayID
        Task { @MainActor in
            do {
                try await CaptureStreamController.shared.startStream(displayID: displayID)
                var frameCount = 0
                let maxFrames = 5
                let semaphore = DispatchSemaphore(value: 0)
                let originalOnFrame = CaptureStreamController.shared.onFrameCaptured
                CaptureStreamController.shared.onFrameCaptured = { [weak self] image, _ in
                    frameCount += 1
                    if frameCount >= maxFrames {
                        _ = CaptureStreamController.shared.stopStream()
                        CaptureStreamController.shared.onFrameCaptured = originalOnFrame
                        let effectRect = self?.screenRectToBottomLeft(rect) ?? .zero
                        if SettingsManager.shared.effectsEnabled {
                            CaptureEffectWindow().show(at: effectRect, mode: .stream)
                        }
                        self?.onCapture?(image)
                        semaphore.signal()
                    }
                }
                semaphore.wait()
            } catch {
                onCapture?(nil)
            }
        }
    }

    private func startCameraCapture() {
        cancel(silent: true)
        guard let window = NSApp.windows.first(where: { $0 != overlayWindow }) else { return }
        let preview = LiveOCRPreview(frame: window.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 800, height: 600))
        window.contentView?.addSubview(preview)
        preview.translatesAutoresizingMaskIntoConstraints = false
        if let contentView = window.contentView {
            NSLayoutConstraint.activate([
                preview.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                preview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                preview.topAnchor.constraint(equalTo: contentView.topAnchor),
                preview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        Task { @MainActor in
            do {
                let session = try await CameraCaptureController.shared.startCaptureSession(previewView: preview)
                preview.attachPreviewLayer(AVCaptureVideoPreviewLayer(session: session))
                preview.startLiveOCR()
                CameraCaptureController.shared.startLiveOCR { [weak preview] text, observations in
                    preview?.onTextDetected?(text, observations)
                }
                if let onCapture = onCapture {
                    preview.onCaptureTriggered = {
                        onCapture(nil)
                    }
                }
            } catch {
                onCapture?(nil)
            }
        }
    }

    private func captureAreaImage(_ rect: CGRect, from window: NSWindow) -> NSImage? {
        let screenRect = window.convertToScreen(rect)
        let mainScreenHeight = NSScreen.screens.first?.frame.maxY ?? screenRect.maxY
        let cgRect = CGRect(x: screenRect.minX, y: mainScreenHeight - screenRect.maxY, width: screenRect.width, height: screenRect.height)
        guard let cgImage = CGWindowListCreateImage(cgRect, [.optionOnScreenOnly], kCGNullWindowID, [.bestResolution]) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    private func captureWindowImage(_ id: CGWindowID, fallbackRect: CGRect, from window: NSWindow) -> NSImage? {
        if let cgImage = CGWindowListCreateImage(.null, [.optionIncludingWindow], id, [.boundsIgnoreFraming, .nominalResolution]) {
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
        return captureAreaImage(fallbackRect, from: window)
    }

    private func queryWindows() -> [CaptureWindowInfo] {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return list.compactMap { info -> CaptureWindowInfo? in
            guard let idNumber = info[kCGWindowNumber as String] as? NSNumber else { return nil }
            let id = CGWindowID(idNumber.uint32Value)
            let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue ?? 0
            let alpha = (info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1
            let owner = info[kCGWindowOwnerName as String] as? String ?? ""
            guard layer == 0, alpha > 0.01, !owner.isEmpty, owner != "Window Server" else { return nil }
            guard let bounds = cgRect(from: info) else { return nil }
            guard bounds.width > 20, bounds.height > 20 else { return nil }
            return CaptureWindowInfo(id: id, frame: bounds, ownerName: owner)
        }
    }

    private func cgRect(from info: [String: Any]) -> CGRect? {
        guard let dict = info[kCGWindowBounds as String] as? NSDictionary else { return nil }
        guard let x = number(forKey: "X", in: dict),
              let y = number(forKey: "Y", in: dict),
              let width = number(forKey: "Width", in: dict),
              let height = number(forKey: "Height", in: dict) else { return nil }
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func number(forKey key: String, in dict: NSDictionary) -> CGFloat? {
        if let value = dict[key] as? CGFloat { return value }
        if let value = dict[key] as? Double { return CGFloat(value) }
        if let value = dict[key] as? NSNumber { return CGFloat(value.doubleValue) }
        return nil
    }

    private func screenRectToBottomLeft(_ rect: CGRect) -> NSRect {
        let height = NSScreen.screens.first?.frame.maxY ?? rect.maxY
        return NSRect(x: rect.minX, y: height - rect.maxY, width: rect.width, height: rect.height)
    }
}


class LanguageAvatarButton: NSButton {
    var languageCode: String = "en-US" { didSet { updateTitle(); setNeedsDisplay(bounds) } }

    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        wantsLayer = true
        layer?.masksToBounds = false
        updateTitle()
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        trackingArea = area
        addTrackingArea(area)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isBordered = false
        wantsLayer = true
        layer?.masksToBounds = false
        updateTitle()
    }

    private func updateTitle() {
        let def = LocalizedText.languageDefinition(for: languageCode)
        attributedTitle = NSAttributedString(string: def.flag, attributes: [
            .font: NSFont.systemFont(ofSize: 16, weight: .bold),
            .paragraphStyle: centeredParagraph()
        ])
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        UXSoundPlayer.shared.play(.hover)
        animateHover()
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        animateHover()
    }

    private func animateHover() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.allowsImplicitAnimation = true
            layer?.shadowOpacity = isHovered ? 0.65 : 0.35
            layer?.shadowRadius = isHovered ? 18 : 12
            layer?.transform = CATransform3DMakeScale(isHovered ? 1.06 : 1.0, isHovered ? 1.06 : 1.0, 1)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = dirtyRect.insetBy(dx: 1, dy: 1)
        let gradient = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.28),
            NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.22),
            NSColor(calibratedRed: 0.72, green: 0.45, blue: 1.0, alpha: 0.24)
        ])
        gradient?.draw(in: rect, angle: 125)

        let border = NSBezierPath(ovalIn: rect)
        border.lineWidth = 1.4
        NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 0.72).setStroke()
        border.stroke()

        let highlight = NSBezierPath(ovalIn: NSRect(x: rect.minX + 3, y: rect.maxY - 10, width: rect.width - 6, height: 8))
        NSColor.white.withAlphaComponent(0.22).setFill()
        highlight.fill()

        super.draw(dirtyRect)
    }
}

class LanguageFlagButton: NSButton {
    var language: LanguageDefinition
    var isSelected = false
    private var isHovered = false

    init(frame: NSRect, language: LanguageDefinition) {
        self.language = language
        super.init(frame: frame)
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = false
        updateTitle()
    }

    required init?(coder: NSCoder) {
        language = LocalizedText.languageDefinition(for: "en-US")
        super.init(coder: coder)
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = false
    }

    func setSelected(_ selected: Bool) {
        isSelected = selected
        updateStyle()
    }

    private func updateTitle() {
        attributedTitle = NSAttributedString(string: "\(language.flag)  \(language.nativeName)", attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: centeredParagraph()
        ])
    }

    private func updateStyle() {
        layer?.borderColor = (isSelected ? HUDPalette.mint : NSColor.white.withAlphaComponent(0.18)).cgColor
        layer?.borderWidth = isSelected ? 1.6 : 1
        layer?.shadowColor = (isSelected ? HUDPalette.mint : HUDPalette.cyan).cgColor
        layer?.shadowRadius = isSelected ? 16 : 8
        layer?.shadowOpacity = isSelected ? 0.55 : 0.2
        layer?.backgroundColor = isSelected ? NSColor(calibratedRed: 0.0, green: 0.25, blue: 0.18, alpha: 0.55).cgColor : NSColor(white: 0.08, alpha: 0.62).cgColor
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        UXSoundPlayer.shared.play(.hover)
        updateHover()
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        updateHover()
    }

    private func updateHover() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.allowsImplicitAnimation = true
            layer?.transform = CATransform3DMakeScale(isHovered ? 1.035 : 1.0, isHovered ? 1.035 : 1.0, 1)
            layer?.shadowRadius = isHovered ? 14 : (isSelected ? 16 : 8)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let gradient = NSGradient(colors: [
            NSColor(white: 0.16, alpha: 0.72),
            NSColor(white: 0.05, alpha: 0.72)
        ])
        gradient?.draw(in: dirtyRect, angle: 105)
        super.draw(dirtyRect)
    }
}

class LanguagePickerViewController: NSViewController {
    var onLanguageSelected: ((LanguageDefinition) -> Void)?

    private var selectedButton: LanguageFlagButton?

    override func loadView() {
        view = CyberpunkCard(frame: NSRect(x: 0, y: 0, width: 420, height: 360))
        (view as? CyberpunkCard)?.glowColor = HUDPalette.violet
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        view.alphaValue = 0
        view.animator().alphaValue = 1
    }

    private func setupUI() {
        let background = HUDGridBackgroundView(frame: view.bounds)
        view.addSubview(background)
        background.autoresizingMask = [.width, .height]

        let title = label(LocalizedText.value("languageTitle"), y: 326, size: 18, weight: .bold, color: .white)
        view.addSubview(title)
        let subtitle = label(LocalizedText.value("languageSubtitle"), y: 304, size: 11, weight: .regular, color: HUDPalette.mutedText)
        view.addSubview(subtitle)

        let languages = LocalizedText.languages
        let columns = 2
        let itemWidth: CGFloat = 178
        let itemHeight: CGFloat = 38
        let startX: CGFloat = 24
        var y: CGFloat = 258
        for (index, language) in languages.enumerated() {
            if index > 0 && index % columns == 0 {
                y -= itemHeight + 8
            }
            let column = index % columns
            let x = startX + CGFloat(column) * (itemWidth + 12)
            let button = LanguageFlagButton(frame: NSRect(x: x, y: y, width: itemWidth, height: itemHeight), language: language)
            button.target = self
            button.action = #selector(languageButtonClicked(_:))
            button.setSelected(language.code == SettingsManager.shared.languageCode)
            if button.isSelected { selectedButton = button }
            view.addSubview(button)
        }
    }

    private func label(_ text: String, y: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let label = NSTextField()
        label.stringValue = text
        label.font = NSFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.backgroundColor = .clear
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.frame = NSRect(x: 24, y: y, width: 372, height: size + 8)
        return label
    }

    @objc private func languageButtonClicked(_ sender: LanguageFlagButton) {
        UXSoundPlayer.shared.play(.select)
        onLanguageSelected?(sender.language)
    }
}

class LanguageConfirmationWindowController {
    private var window: NSWindow?
    private var confirmAction: (() -> Void)?
    private var cancelAction: (() -> Void)?

    init(language: LanguageDefinition, confirm: @escaping () -> Void, cancel: @escaping () -> Void) {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 430, height: 250))
        let card = CyberpunkCard(frame: content.bounds)
        card.glowColor = language.code == SettingsManager.shared.languageCode ? HUDPalette.mint : HUDPalette.violet
        content.addSubview(card)

        let icon = NSTextField(frame: NSRect(x: 34, y: 178, width: 58, height: 58))
        icon.stringValue = language.flag
        icon.font = NSFont.systemFont(ofSize: 34, weight: .bold)
        icon.alignment = .center
        icon.wantsLayer = true
        icon.layer?.cornerRadius = 22
        icon.layer?.borderColor = HUDPalette.mint.withAlphaComponent(0.55).cgColor
        icon.layer?.borderWidth = 1.2
        icon.layer?.backgroundColor = NSColor(white: 0.08, alpha: 0.72).cgColor
        content.addSubview(icon)

        let title = NSTextField(frame: NSRect(x: 104, y: 202, width: 292, height: 28))
        title.stringValue = LocalizedText.value("confirmLanguageTitle")
        title.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        title.textColor = .white
        title.isBordered = false
        title.isEditable = false
        title.isSelectable = false
        content.addSubview(title)

        let body = NSTextField(frame: NSRect(x: 104, y: 176, width: 292, height: 42))
        body.stringValue = String(format: LocalizedText.value("confirmLanguageBody"), language.nativeName)
        body.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        body.textColor = HUDPalette.mutedText
        body.isBordered = false
        body.isEditable = false
        body.isSelectable = false
        body.lineBreakMode = .byWordWrapping
        content.addSubview(body)

        let green = CyberpunkButton(frame: NSRect(x: 226, y: 34, width: 150, height: 36))
        green.title = "✓ " + LocalizedText.value("confirm")
        green.glowColor = HUDPalette.mint
        content.addSubview(green)

        let red = CyberpunkButton(frame: NSRect(x: 54, y: 34, width: 150, height: 36))
        red.title = "✕ " + LocalizedText.value("goBack")
        red.glowColor = NSColor(calibratedRed: 1.0, green: 0.28, blue: 0.42, alpha: 1.0)
        content.addSubview(red)

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 430, height: 250), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = language.nativeName
        window.contentViewController = NSViewController()
        window.contentViewController?.view = content
        window.center()
        window.isReleasedWhenClosed = true
        self.window = window
        green.target = self
        green.action = #selector(confirmClicked)
        red.target = self
        red.action = #selector(cancelClicked)
        confirmAction = confirm
        cancelAction = cancel
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func confirmClicked() {
        UXSoundPlayer.shared.play(.complete)
        confirmAction?()
        window?.close()
    }

    @objc private func cancelClicked() {
        UXSoundPlayer.shared.play(.cancel)
        cancelAction?()
        window?.close()
    }
}

func centeredParagraph() -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    return style
}


class AnimatedHeroView: NSView {
    private var trackingArea: NSTrackingArea?
    private var mouseX: CGFloat = 0.5
    private var mouseY: CGFloat = 0.5
    private var targetX: CGFloat = 0.5
    private var targetY: CGFloat = 0.5
    private let orb1 = CALayer()
    private let orb2 = CALayer()
    private let orb3 = CALayer()
    private let sheen = CALayer()
    private var displayLink: CVDisplayLink?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 22
        setupLayers()
        let area = NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        trackingArea = area
        addTrackingArea(area)
        startDisplayLink()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupLayers()
    }

    private func setupLayers() {
        layer?.backgroundColor = NSColor(white: 0.025, alpha: 0.72).cgColor

        orb1.frame = NSRect(x: -20, y: 24, width: 90, height: 90)
        orb1.cornerRadius = 45
        orb1.backgroundColor = HUDPalette.cyan.withAlphaComponent(0.22).cgColor
        orb1.shadowColor = HUDPalette.cyan.cgColor
        orb1.shadowRadius = 28
        orb1.shadowOpacity = 0.75
        layer?.addSublayer(orb1)

        orb2.frame = NSRect(x: 210, y: 10, width: 120, height: 120)
        orb2.cornerRadius = 60
        orb2.backgroundColor = HUDPalette.violet.withAlphaComponent(0.24).cgColor
        orb2.shadowColor = HUDPalette.violet.cgColor
        orb2.shadowRadius = 30
        orb2.shadowOpacity = 0.65
        layer?.addSublayer(orb2)

        orb3.frame = NSRect(x: 112, y: -30, width: 76, height: 76)
        orb3.cornerRadius = 38
        orb3.backgroundColor = HUDPalette.mint.withAlphaComponent(0.18).cgColor
        orb3.shadowColor = HUDPalette.mint.cgColor
        orb3.shadowRadius = 22
        orb3.shadowOpacity = 0.5
        layer?.addSublayer(orb3)

        sheen.frame = bounds
        sheen.cornerRadius = 22
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [
            NSColor.white.withAlphaComponent(0.0).cgColor,
            NSColor.white.withAlphaComponent(0.22).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        sheen.addSublayer(gradient)
        layer?.addSublayer(sheen)

        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.duration = 18
        rotate.repeatCount = .infinity
        rotate.fromValue = 0
        rotate.toValue = CGFloat.pi * 2
        orb2.add(rotate, forKey: "rotate")
    }

    private func startDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let link = displayLink else { return }
        CVDisplayLinkSetOutputHandler(link) { [weak self] _, _, _, _, _ in
            guard let self else { return kCVReturnSuccess }
            DispatchQueue.main.async {
                self.tick()
            }
            return kCVReturnSuccess
        }
        CVDisplayLinkStart(link)
    }

    private func tick() {
        mouseX += (targetX - mouseX) * 0.06
        mouseY += (targetY - mouseY) * 0.06
        let dx = (mouseX - 0.5) * 26
        let dy = (mouseY - 0.5) * 26
        let time = CACurrentMediaTime()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            context.allowsImplicitAnimation = true
            orb1.position = CGPoint(x: bounds.midX - 120 + dx * 0.9, y: bounds.midY + 8 + sin(time) * 7)
            orb2.position = CGPoint(x: bounds.midX + 120 + dx * 0.55, y: bounds.midY - 8 + cos(time * 0.8) * 8)
            orb3.position = CGPoint(x: bounds.midX + dx * 0.3, y: bounds.midY + 42 + dy * 0.3 + sin(time * 1.4) * 6)
            sheen.position = CGPoint(x: (mouseX - 0.5) * 260, y: (mouseY - 0.5) * 180)
            layer?.transform = CATransform3DMakeRotation((mouseY - 0.5) * -0.035, 1, 0, 0)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        updateTarget(from: event)
    }

    override func mouseEntered(with event: NSEvent) {
        updateTarget(from: event)
    }

    override func mouseExited(with event: NSEvent) {
        targetX = 0.5
        targetY = 0.5
    }

    private func updateTarget(from event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        targetX = max(0, min(1, point.x / max(bounds.width, 1)))
        targetY = max(0, min(1, point.y / max(bounds.height, 1)))
    }

    override func draw(_ dirtyRect: NSRect) {
        let grid = HUDGridBackgroundView(frame: bounds)
        grid.draw(dirtyRect)
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 22, yRadius: 22)
        border.lineWidth = 1
        NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 0.34).setStroke()
        border.stroke()
    }
}

class StatPillView: NSView {
    var valueText = "0" { didSet { updateLabels() } }
    var labelText = "Stat" { didSet { updateLabels() } }

    private let valueLabel = NSTextField()
    private let captionLabel = NSTextField()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 13
        layer?.borderColor = HUDPalette.cyan.withAlphaComponent(0.22).cgColor
        layer?.borderWidth = 1
        layer?.backgroundColor = NSColor(white: 0.06, alpha: 0.58).cgColor
        setupLabels()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabels()
    }

    private func setupLabels() {
        valueLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.backgroundColor = .clear
        valueLabel.isBordered = false
        valueLabel.isEditable = false
        valueLabel.isSelectable = false
        valueLabel.frame = NSRect(x: 10, y: 15, width: bounds.width - 20, height: 18)
        addSubview(valueLabel)

        captionLabel.font = NSFont.monospacedSystemFont(ofSize: 8.5, weight: .semibold)
        captionLabel.textColor = HUDPalette.mutedText
        captionLabel.backgroundColor = .clear
        captionLabel.isBordered = false
        captionLabel.isEditable = false
        captionLabel.isSelectable = false
        captionLabel.frame = NSRect(x: 10, y: 4, width: bounds.width - 20, height: 10)
        addSubview(captionLabel)
        updateLabels()
    }

    private func updateLabels() {
        valueLabel.stringValue = valueText
        captionLabel.stringValue = labelText
    }
}

class FeatureCardView: CyberpunkCard {
    private let iconLabel = NSTextField()
    private let titleLabel = NSTextField()
    private let bodyLabel = NSTextField()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        glowColor = HUDPalette.cyan
        setupLabels()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabels()
    }

    func configure(icon: String, title: String, body: String, glow: NSColor = HUDPalette.cyan) {
        glowColor = glow
        iconLabel.stringValue = icon
        titleLabel.stringValue = title
        bodyLabel.stringValue = body
    }

    private func setupLabels() {
        iconLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        iconLabel.textColor = .white
        iconLabel.backgroundColor = .clear
        iconLabel.isBordered = false
        iconLabel.isEditable = false
        iconLabel.isSelectable = false
        iconLabel.frame = NSRect(x: 10, y: 18, width: 26, height: 24)
        addSubview(iconLabel)

        titleLabel.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.backgroundColor = .clear
        titleLabel.isBordered = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.frame = NSRect(x: 42, y: 28, width: bounds.width - 52, height: 14)
        addSubview(titleLabel)

        bodyLabel.font = NSFont.systemFont(ofSize: 8.5, weight: .regular)
        bodyLabel.textColor = HUDPalette.mutedText
        bodyLabel.backgroundColor = .clear
        bodyLabel.isBordered = false
        bodyLabel.isEditable = false
        bodyLabel.isSelectable = false
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.frame = NSRect(x: 42, y: 12, width: bounds.width - 52, height: 14)
        addSubview(bodyLabel)
    }
}

class FlagMenuView: NSView {
    var onCaptureArea: (() -> Void)?
    var onCaptureWindow: (() -> Void)?
    var onCaptureFullScreen: (() -> Void)?
    var onCaptureScroll: (() -> Void)?
    var onCaptureBatch: (() -> Void)?
    var onCaptureStream: (() -> Void)?
    var onCaptureCamera: (() -> Void)?
    var buttonTitle: String = "⚑ Flag Menu" {
        didSet { button.title = buttonTitle }
    }

    private let button: CyberpunkButton
    private let captureMenu: NSMenu

    override init(frame frameRect: NSRect) {
        button = CyberpunkButton(frame: NSRect(origin: .zero, size: frameRect.size))
        captureMenu = NSMenu()
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        button = CyberpunkButton(frame: .zero)
        captureMenu = NSMenu()
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        button.frame = bounds
        buttonTitle = "⚑ Flag Menu"
        button.glowColor = HUDPalette.violet
        button.target = self
        button.action = #selector(showMenu)
        addSubview(button)

        let areaItem = NSMenuItem(title: "Crosshair Capture ⌃⌘⌥1", action: #selector(areaSelected), keyEquivalent: "")
        areaItem.tag = 1
        captureMenu.addItem(areaItem)
        let windowItem = NSMenuItem(title: "Window Capture ⌃⌘⌥2", action: #selector(windowSelected), keyEquivalent: "")
        windowItem.tag = 2
        captureMenu.addItem(windowItem)
        let fullScreenItem = NSMenuItem(title: "Full Screen Capture ⌃⌘⌥3", action: #selector(fullScreenSelected), keyEquivalent: "")
        fullScreenItem.tag = 3
        captureMenu.addItem(fullScreenItem)
        let scrollItem = NSMenuItem(title: "Scroll Capture ⌃⌘⌥4", action: #selector(scrollSelected), keyEquivalent: "")
        scrollItem.tag = 4
        captureMenu.addItem(scrollItem)
        let batchItem = NSMenuItem(title: "Batch Capture ⌃⌘⌥5", action: #selector(batchSelected), keyEquivalent: "")
        batchItem.tag = 5
        captureMenu.addItem(batchItem)
        let streamItem = NSMenuItem(title: "Stream Capture ⌃⌘⌥6", action: #selector(streamSelected), keyEquivalent: "")
        streamItem.tag = 6
        captureMenu.addItem(streamItem)
        let cameraItem = NSMenuItem(title: "Camera Capture ⌃⌘⌥7", action: #selector(cameraSelected), keyEquivalent: "")
        cameraItem.tag = 7
        captureMenu.addItem(cameraItem)
        captureMenu.delegate = self
    }

    override func layout() {
        super.layout()
        button.frame = bounds
    }

    func updateSelected(mode: CaptureMode) {
        button.isSelected = true
        switch mode {
        case .area:
            button.glowColor = HUDPalette.cyan
        case .window:
            button.glowColor = HUDPalette.violet
        case .scroll:
            button.glowColor = HUDPalette.amber
        case .fullScreen:
            button.glowColor = NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 1.0)
        case .batch:
            button.glowColor = HUDPalette.rose
        case .stream:
            button.glowColor = HUDPalette.cyan
        case .camera:
            button.glowColor = NSColor(calibratedRed: 0.0, green: 0.92, blue: 1.0, alpha: 1.0)
        }
    }

    @objc private func showMenu() {
        UXSoundPlayer.shared.play(.select)
        captureMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: bounds.minY - 4), in: button)
    }

    @objc private func areaSelected() {
        onCaptureArea?()
    }

    @objc private func windowSelected() {
        onCaptureWindow?()
    }

    @objc private func fullScreenSelected() {
        onCaptureFullScreen?()
    }

    @objc private func scrollSelected() {
        onCaptureScroll?()
    }

    @objc private func batchSelected() {
        onCaptureBatch?()
    }

    @objc private func streamSelected() {
        onCaptureStream?()
    }

    @objc private func cameraSelected() {
        onCaptureCamera?()
    }
}

extension FlagMenuView: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        button.isHovered = true
        button.updateGlowForMenuOpen()
    }

    func menuDidClose(_ menu: NSMenu) {
        button.isHovered = false
        button.updateGlowForMenuOpen()
    }
}

private extension CyberpunkButton {
    func updateGlowForMenuOpen() {
        updateGlow()
    }
}

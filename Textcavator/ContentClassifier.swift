import Foundation

enum ContentCategory: String, Codable, CaseIterable {
    case code = "code"
    case document = "document"
    case email = "email"
    case chat = "chat"
    case socialMedia = "social_media"
    case financial = "financial"
    case legal = "legal"
    case medical = "medical"
    case personal = "personal"
    case technical = "technical"
    case academic = "academic"
    case news = "news"
    case other = "other"

    var displayName: String {
        switch self {
        case .code: return "Code"
        case .document: return "Document"
        case .email: return "Email"
        case .chat: return "Chat"
        case .socialMedia: return "Social Media"
        case .financial: return "Financial"
        case .legal: return "Legal"
        case .medical: return "Medical"
        case .personal: return "Personal"
        case .technical: return "Technical"
        case .academic: return "Academic"
        case .news: return "News"
        case .other: return "Other"
        }
    }
}

struct ClassificationResult: Codable, Identifiable {
    let id: UUID
    let category: ContentCategory
    let confidence: Double
    let tags: [String]
    let createdAt: Date

    init(id: UUID = UUID(), category: ContentCategory, confidence: Double, tags: [String]) {
        self.id = id
        self.category = category
        self.confidence = confidence
        self.tags = tags
        self.createdAt = Date()
    }
}

class ContentClassifier {
    static let shared = ContentClassifier()

    private init() {}

    func classify(text: String) -> ClassificationResult {
        let lowercased = text.lowercased()
        var scores: [ContentCategory: Double] = [:]
        var matchedTags: [String] = []

        let patterns: [(ContentCategory, [String])] = [
            (.code, ["function", "var", "let", "const", "import", "class", "def ", "return", "if ", "else", "for ", "while ", "print", "console.log", "git ", "npm ", "cargo ", "python", "javascript", "typescript", "java ", "swift", "rust ", "go ", "docker", "kubernetes", "api ", "http ", "json", "xml", "html", "css", "react", "vue ", "angular", "database", "sql ", "select", "insert", "update", "delete"]),
            (.financial, ["invoice", "payment", "balance", "transaction", "account", "bank", "credit", "debit", "price", "cost", "revenue", "profit", "tax", "salary", "budget", "expense", "income", "fee", "refund", "billing", "subscription", "$", "€", "£", "¥", "bitcoin", "ethereum", "crypto", "stock", "market", "invest"]),
            (.legal, ["contract", "agreement", "court", "judge", "law", "legal", "attorney", "plaintiff", "defendant", "clause", "terms", "conditions", "liability", "warranty", "compliance", "regulation", "statute", "verdict", "settlement", "litigation", "patent", "copyright", "trademark"]),
            (.medical, ["patient", "diagnosis", "prescription", "doctor", "hospital", "medical", "health", "symptom", "treatment", "medication", "disease", "vaccine", "clinical", "pharmacy", "dosage", "prognosis", "therapy", "surgery", "blood ", "heart ", "cancer ", "diabetes"]),
            (.email, ["subject:", "from:", "to:", "cc:", "bcc:", "dear ", "sincerely", "regards", "best regards", "hello ", "hi ", "thanks", "thank you", "unsubscribe", "email ", "@gmail", "@yahoo", "@outlook", "@company", "sent from", "forwarded", "reply"]),
            (.chat, ["hey", "hi ", "lol", "brb", "gtg", "ttyl", "omg", "wtf", "lmao", "rofl", "sent ", "delivered", "read", "typing", "emoji", "reaction", "thread", "dm ", "pm ", "message", "chat ", "conversation", "reply ", "online", "offline", "last seen"]),
            (.socialMedia, ["post", "like", "share", "follow", "follower", "tweet", "retweet", "hashtag", "#", "@username", "profile", "feed", "story", "reels", "tiktok", "instagram", "facebook", "twitter", "linkedin", "reddit ", "subreddit", "upvote", "downvote", "pin ", "board"]),
            (.academic, ["abstract", "introduction", "methodology", "conclusion", "references", "bibliography", "thesis", "dissertation", "research", "study", "experiment", "hypothesis", "analysis", "data", "results", "discussion", "journal", "conference", "paper", "citation", "doi:", "arxiv"]),
            (.news, ["breaking", "news", "report", "journalist", "article", "headline", "press release", "officials", "government", "president", "election", "vote", "democracy", "protest", "climate", "economy", "market", "war", "peace", "international", "national"]),
            (.document, ["page 1", "page 2", "table of contents", "chapter ", "section ", "appendix", "revised", "draft", "final", "confidential", "public", "report", "memo", " memorandum", "letter", "fax", "scan", "ocr"]),
            (.personal, ["appointment", "reminder", "birthday", "anniversary", "vacation", "travel", "flight", "hotel", "reservation", "restaurant", "dinner", "lunch", "meeting", "calendar", "todo", "shopping", "grocery", "list", "call ", "phone ", "text "])
        ]

        for (category, keywords) in patterns {
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    scores[category, default: 0] += 1.0
                    if matchedTags.count < 5 && !matchedTags.contains(keyword.trimmingCharacters(in: .whitespaces)) {
                        matchedTags.append(keyword.trimmingCharacters(in: .whitespaces))
                    }
                }
            }
        }

        let best = scores.max { $0.value < $1.value }
        let topCategory = best?.key ?? .other
        let maxScore = best?.value ?? 0
        let totalScore = scores.values.reduce(0, +)
        let confidence = totalScore > 0 ? min(maxScore / totalScore, 1.0) : 0.0

        return ClassificationResult(category: topCategory, confidence: confidence, tags: Array(matchedTags.prefix(5)))
    }
}

import Foundation

class ExtractiveSummarizer: SummarizationPlugin {
    static let shared = ExtractiveSummarizer()

    let name = "Extractive Summarizer"
    let isAvailable = true
    let priority = 1

    private init() {}

    func summarize(_ text: String, maxLength: Int = 200) async throws -> SummaryResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        let sentences = text.split(separator: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard sentences.count > 1 else {
            if text.count <= maxLength {
                return SummaryResult(summary: text, originalLength: text.count, summaryLength: text.count, compressionRatio: 1.0, modelVersion: name, processingTime: CFAbsoluteTimeGetCurrent() - startTime)
            }
            throw SummarizationError.textTooShort
        }

        let wordFreq = calculateWordFrequency(sentences.joined(separator: " "))
        let scored = sentences.map { sentence -> (String, Double) in
            let words = sentence.lowercased().split(separator: " ").map(String.init)
            let score = words.reduce(0.0) { $0 + (wordFreq[$1] ?? 0) }
            return (sentence, score / Double(max(words.count, 1)))
        }

        let sorted = scored.sorted { $0.1 > $1.1 }
        let topSentences = sorted.prefix(max(2, min(5, sentences.count / 2)))
        let summary = topSentences.map { $0.0 }.joined(separator: ". ")
        let trimmed = String(summary.prefix(maxLength))

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        return SummaryResult(summary: trimmed, originalLength: text.count, summaryLength: trimmed.count, compressionRatio: Double(trimmed.count) / Double(max(text.count, 1)), modelVersion: name, processingTime: elapsed)
    }

    func summarizeBatch(_ texts: [String], maxLength: Int = 200) async throws -> [SummaryResult] {
        var results: [SummaryResult] = []
        for text in texts {
            results.append(try await summarize(text, maxLength: maxLength))
        }
        return results
    }

    private func calculateWordFrequency(_ text: String) -> [String: Double] {
        let stopWords: Set<String> = ["the", "a", "an", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "shall", "can", "to", "of", "in", "for", "on", "with", "at", "by", "from", "as", "into", "through", "during", "before", "after", "above", "below", "between", "out", "off", "over", "under", "again", "further", "then", "once", "here", "there", "when", "where", "why", "how", "all", "each", "every", "both", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very", "just", "because", "but", "and", "or", "if", "while", "about", "it", "its", "this", "that", "these", "those", "i", "me", "my", "myself", "we", "our", "ours", "you", "your", "yours", "he", "him", "his", "she", "her", "hers", "they", "them", "their", "what", "which", "who", "whom"]
        let words = text.lowercased().split(separator: " ").map(String.init)
        var freq: [String: Double] = [:]
        for word in words where !stopWords.contains(word) && word.count > 2 {
            freq[word, default: 0] += 1.0
        }
        return freq
    }
}

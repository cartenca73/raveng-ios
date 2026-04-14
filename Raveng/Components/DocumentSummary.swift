import Foundation
import PDFKit
import NaturalLanguage

/// On-device document summarization using Apple NaturalLanguage framework.
/// Per ora estrae metriche e le top-N frasi salienti (TextRank-like),
/// pronto a essere upgradato a Foundation Models quando l'utente ha iOS 18.1+ Intelligence.
enum DocumentSummary {

    struct Summary {
        let totalWords: Int
        let estimatedReadMinutes: Int
        let sentences: [String]     // frasi chiave ordinate per rilevanza
        let keyPhrases: [String]    // entità/termini ricorrenti
        let language: String?
    }

    static func summarize(pdfURL: URL, maxSentences: Int = 5) -> Summary {
        guard let doc = PDFDocument(url: pdfURL) else {
            return .init(totalWords: 0, estimatedReadMinutes: 0, sentences: [], keyPhrases: [], language: nil)
        }
        var fullText = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let txt = page.string {
                fullText += txt + "\n"
            }
        }
        return summarize(text: fullText, maxSentences: maxSentences)
    }

    static func summarize(text: String, maxSentences: Int = 5) -> Summary {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .init(totalWords: 0, estimatedReadMinutes: 0, sentences: [], keyPhrases: [], language: nil)
        }

        let totalWords = trimmed
            .split { $0.isWhitespace || $0.isNewline }.count
        let readMin = max(1, totalWords / 220)

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        let lang = recognizer.dominantLanguage?.rawValue

        // Tokenize sentences
        var sentences: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = trimmed
        tokenizer.enumerateTokens(in: trimmed.startIndex..<trimmed.endIndex) { range, _ in
            let s = String(trimmed[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty, s.count > 30 { sentences.append(s) }
            return true
        }

        // Score sentences by presence of key tokens (simple TF weighting)
        let wordFreq = computeFrequency(in: trimmed)
        let scored: [(String, Double)] = sentences.map { s in
            let tokens = s.lowercased().split { $0.isWhitespace || $0.isPunctuation }.map(String.init)
            let score = tokens.reduce(0.0) { acc, t in acc + Double(wordFreq[t] ?? 0) }
            let norm = tokens.isEmpty ? 0 : score / Double(tokens.count)
            return (s, norm)
        }
        let topSentences = scored.sorted { $0.1 > $1.1 }.prefix(maxSentences).map { $0.0 }

        // Key phrases: named entities + most frequent non-stopword tokens
        var entities: [String] = []
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = trimmed
        tagger.enumerateTags(in: trimmed.startIndex..<trimmed.endIndex,
                              unit: .word, scheme: .nameType,
                              options: [.omitWhitespace, .omitPunctuation, .joinNames]) { tag, range in
            if let tag, [.personalName, .organizationName, .placeName].contains(tag) {
                let w = String(trimmed[range])
                if w.count >= 3 && !entities.contains(w) { entities.append(w) }
            }
            return entities.count < 8
        }

        return Summary(
            totalWords: totalWords,
            estimatedReadMinutes: readMin,
            sentences: Array(topSentences),
            keyPhrases: entities,
            language: lang
        )
    }

    private static let stopwords: Set<String> = [
        "il","lo","la","i","gli","le","un","una","uno","e","di","a","da","in","con","su","per","tra","fra",
        "che","non","si","ma","se","o","al","del","dei","delle","della","dello","alla","alle","agli","nel",
        "nella","nelle","ne","vi","ci","ho","ha","hai","hanno","sono","sei","era","erano","stato","stata",
        "the","a","an","of","and","or","in","to","for","is","are","was","were","be","been","with","on","by","as","this","that"
    ]

    private static func computeFrequency(in text: String) -> [String: Int] {
        var freq: [String: Int] = [:]
        let lowered = text.lowercased()
        for t in lowered.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }) {
            let w = String(t)
            if w.count < 3 || stopwords.contains(w) { continue }
            freq[w, default: 0] += 1
        }
        return freq
    }
}

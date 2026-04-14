import Foundation
import Vision
import PDFKit
import UIKit

/// Scans a PDF with Apple Vision and detects common Italian form labels.
/// Each detection has page index + bounding box in PDF points + suggested field type.
struct DetectedField: Identifiable, Codable {
    let id: UUID
    let label: String
    let fieldType: String   // text, date, signature, checkbox
    let page: Int
    // bounding box in PDF points (origin: bottom-left)
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(label: String, fieldType: String, page: Int,
         x: Double, y: Double, width: Double, height: Double) {
        self.id = UUID()
        self.label = label
        self.fieldType = fieldType
        self.page = page
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

enum PDFOCRScanner {

    // Patterns for Italian common labels -> field types (validated at init).
    private static let patterns: [(NSRegularExpression, String)] = {
        let sources: [(String, String)] = [
            (#"\b(nome|cognome|nominativo|ragione\s+sociale)\s*[:_]?"#,                 "text"),
            (#"\b(e[- ]?mail|posta)\s*[:_]?"#,                                          "text"),
            (#"\b(telefono|cellulare|mobile|phone|tel\.?)\s*[:_]?"#,                    "text"),
            (#"\b(indirizzo|via|piazza|corso)\s*[:_]?"#,                                "text"),
            (#"\b(citt[àa]|comune|localit[àa])\s*[:_]?"#,                               "text"),
            (#"\b(cap)\s*[:_]?"#,                                                       "text"),
            (#"\b(codice\s+fiscale|c\.?f\.?|partita\s+iva|p\.?iva)\s*[:_]?"#,           "text"),
            (#"\b(data)\s*[:_]?"#,                                                      "date"),
            (#"\b(luogo\s+e\s+data|data\s+e\s+luogo)\s*[:_]?"#,                         "date"),
            (#"\b(firma|signature|sottoscrizione)\s*[:_]?"#,                            "signature"),
            (#"\b(accetto|dichiaro|conferma|acconsento|consento)\b"#,                   "checkbox")
        ]
        return sources.compactMap { (p, kind) in
            (try? NSRegularExpression(pattern: p, options: .caseInsensitive)).map { ($0, kind) }
        }
    }()

    /// Scans each page of the PDF and returns detected fields.
    /// Call in background. Uses DataScannerViewController-free fallback (Vision text recognition).
    static func scan(pdfURL: URL) async throws -> [DetectedField] {
        guard let doc = PDFDocument(url: pdfURL) else { return [] }

        var results: [DetectedField] = []

        for idx in 0..<doc.pageCount {
            guard let page = doc.page(at: idx) else { continue }

            // Render page to UIImage
            let pageRect = page.bounds(for: .mediaBox)
            let img = UIGraphicsImageRenderer(size: pageRect.size).image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            guard let cg = img.cgImage else { continue }

            let req = VNRecognizeTextRequest()
            req.recognitionLevel = .accurate
            req.recognitionLanguages = ["it-IT", "en-US"]
            req.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            try handler.perform([req])

            guard let observations = req.results else { continue }

            for obs in observations {
                guard let top = obs.topCandidates(1).first else { continue }
                let text = top.string.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { continue }

                for (pattern, kind) in patterns {
                    let range = NSRange(text.startIndex..<text.endIndex, in: text)
                    if pattern.firstMatch(in: text, range: range) != nil {
                        // obs.boundingBox is in normalized coordinates (0-1, origin bottom-left)
                        let bb = obs.boundingBox
                        let W = pageRect.size.width
                        let H = pageRect.size.height

                        // Position field to the right of the label (heuristic)
                        let labelX = bb.minX * W
                        let labelY = bb.minY * H
                        let labelW = bb.width * W
                        let labelH = bb.height * H

                        let fieldX = labelX + labelW + 6
                        let fieldY = labelY
                        let fieldW = max(120, W - fieldX - 20)
                        let fieldH = max(18, labelH * 1.1)

                        results.append(.init(
                            label: text,
                            fieldType: kind,
                            page: idx,
                            x: fieldX, y: fieldY,
                            width: fieldW, height: fieldH
                        ))
                        break // one pattern per obs
                    }
                }
            }
        }

        return results
    }
}

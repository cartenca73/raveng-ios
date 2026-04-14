import SwiftUI
import VisionKit
import PDFKit

/// Wrapper SwiftUI per VNDocumentCameraViewController.
/// Restituisce un PDF multipagina pronto da caricare.
struct DocumentCameraView: UIViewControllerRepresentable {
    let onComplete: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let ctrl = VNDocumentCameraViewController()
        ctrl.delegate = context.coordinator
        return ctrl
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(onComplete: onComplete) }

    final class Coord: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: (Result<URL, Error>) -> Void
        init(onComplete: @escaping (Result<URL, Error>) -> Void) { self.onComplete = onComplete }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                           didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            // Convert scanned images to a single PDF
            let pdf = PDFDocument()
            for i in 0..<scan.pageCount {
                let img = scan.imageOfPage(at: i)
                if let page = PDFPage(image: img) {
                    pdf.insert(page, at: pdf.pageCount)
                }
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Scan-\(Int(Date().timeIntervalSince1970)).pdf")
            if pdf.write(to: url) {
                onComplete(.success(url))
            } else {
                onComplete(.failure(NSError(domain: "DocCam", code: 1,
                                            userInfo: [NSLocalizedDescriptionKey: "Impossibile salvare PDF"])))
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                           didFailWithError error: Error) {
            controller.dismiss(animated: true)
            onComplete(.failure(error))
        }
    }
}

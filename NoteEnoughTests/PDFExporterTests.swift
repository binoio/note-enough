import XCTest
import PencilKit
@testable import NoteEnough

final class PDFExporterTests: XCTestCase {

    override func tearDownWithError() throws {
        // Clean up temp files
        let tempDir = FileManager.default.temporaryDirectory
        let contents = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        for file in contents ?? [] where file.pathExtension == "pdf" {
            try? FileManager.default.removeItem(at: file)
        }
    }

    func testSinglePageExport() throws {
        let drawing = PKDrawing()
        let url = try PDFExporter.export(
            name: "Test",
            drawings: [drawing],
            paperType: .plain,
            paperSize: .usLetter,
            orientation: .portrait
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        guard let pdf = CGPDFDocument(url as CFURL) else {
            XCTFail("Could not open PDF")
            return
        }
        XCTAssertEqual(pdf.numberOfPages, 1)

        guard let pdfPage = pdf.page(at: 1) else {
            XCTFail("Could not get page 1")
            return
        }
        let mediaBox = pdfPage.getBoxRect(.mediaBox)
        XCTAssertEqual(mediaBox.width, 612, accuracy: 1)
        XCTAssertEqual(mediaBox.height, 792, accuracy: 1)
    }

    func testMultiPageExport() throws {
        let drawings = [PKDrawing(), PKDrawing(), PKDrawing()]
        let url = try PDFExporter.export(
            name: "MultiPage",
            drawings: drawings,
            paperType: .graph,
            paperSize: .usLetter,
            orientation: .portrait
        )

        guard let pdf = CGPDFDocument(url as CFURL) else {
            XCTFail("Could not open PDF")
            return
        }
        XCTAssertEqual(pdf.numberOfPages, 3)
    }

    func testLandscapeOrientation() throws {
        let url = try PDFExporter.export(
            name: "Landscape",
            drawings: [PKDrawing()],
            paperType: .plain,
            paperSize: .usLetter,
            orientation: .landscape
        )

        guard let pdf = CGPDFDocument(url as CFURL),
              let pdfPage = pdf.page(at: 1) else {
            XCTFail("Could not open PDF")
            return
        }
        let mediaBox = pdfPage.getBoxRect(.mediaBox)
        // Landscape: width=792, height=612
        XCTAssertEqual(mediaBox.width, 792, accuracy: 1)
        XCTAssertEqual(mediaBox.height, 612, accuracy: 1)
    }

    func testA4PaperSize() throws {
        let url = try PDFExporter.export(
            name: "A4Test",
            drawings: [PKDrawing()],
            paperType: .textured,
            paperSize: .a4,
            orientation: .portrait
        )

        guard let pdf = CGPDFDocument(url as CFURL),
              let pdfPage = pdf.page(at: 1) else {
            XCTFail("Could not open PDF")
            return
        }
        let mediaBox = pdfPage.getBoxRect(.mediaBox)
        XCTAssertEqual(mediaBox.width, 595, accuracy: 1)
        XCTAssertEqual(mediaBox.height, 842, accuracy: 1)
    }
}

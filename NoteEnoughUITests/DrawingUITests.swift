import XCTest

@MainActor
final class DrawingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func createAndOpenStack(named name: String) {
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["stackNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)

        app.buttons["confirmButton"].tap()

        // Wait for stack to appear in heap
        let stackText = app.staticTexts[name]
        XCTAssertTrue(stackText.waitForExistence(timeout: 5))

        // Try tapping via button identifier first, then fall back to static text
        let stackButton = app.buttons["stack_\(name)"]
        if stackButton.waitForExistence(timeout: 3) {
            stackButton.tap()
        } else {
            stackText.tap()
        }
    }

    func testOpenStackShowsCanvas() {
        createAndOpenStack(named: "Drawing Test")

        let addPageButton = app.buttons["addPageButton"]
        XCTAssertTrue(addPageButton.waitForExistence(timeout: 10))
    }

    func testAddPage() {
        createAndOpenStack(named: "Multi Page")

        // Page label is now a button
        let pageButton = app.buttons["pagePickerButton"]
        XCTAssertTrue(pageButton.waitForExistence(timeout: 10))

        let addPageButton = app.buttons["addPageButton"]
        XCTAssertTrue(addPageButton.waitForExistence(timeout: 5))
        addPageButton.tap()

        // Verify page picker button still exists after adding page
        XCTAssertTrue(pageButton.waitForExistence(timeout: 10))
    }

    func testShareButtonExists() {
        createAndOpenStack(named: "Share Test")

        let shareButton = app.buttons["shareButton"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 10))
    }

    func testPagePickerOpens() {
        createAndOpenStack(named: "Picker Test")

        let pageButton = app.buttons["pagePickerButton"]
        XCTAssertTrue(pageButton.waitForExistence(timeout: 10))
        pageButton.tap()

        // Verify the popover list appears with at least one page item
        let pageItem = app.buttons["pageItem_0"]
        XCTAssertTrue(pageItem.waitForExistence(timeout: 5))
    }

    func testPagePickerNavigates() {
        createAndOpenStack(named: "Nav Test")

        // Add a second page
        let addPageButton = app.buttons["addPageButton"]
        XCTAssertTrue(addPageButton.waitForExistence(timeout: 10))
        addPageButton.tap()

        // Open page picker
        let pageButton = app.buttons["pagePickerButton"]
        XCTAssertTrue(pageButton.waitForExistence(timeout: 5))
        pageButton.tap()

        // Tap on page 1 (index 0)
        let pageItem0 = app.buttons["pageItem_0"]
        XCTAssertTrue(pageItem0.waitForExistence(timeout: 5))
        pageItem0.tap()

        // Popover should dismiss - verify picker button still accessible
        XCTAssertTrue(pageButton.waitForExistence(timeout: 5))
    }
}

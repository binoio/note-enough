import XCTest

@MainActor
final class HeapUITests: XCTestCase {

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

    func testEmptyStateShowsMessage() {
        XCTAssertTrue(app.staticTexts["No Stacks Yet"].waitForExistence(timeout: 5))
    }

    func testAddStackButtonExists() {
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    }

    func testCreateStack() {
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["stackNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("My Test Stack")

        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertTrue(app.staticTexts["My Test Stack"].waitForExistence(timeout: 5))
    }

    func testSelectAndDeleteStack() {
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["stackNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Delete Me")

        app.buttons["confirmButton"].tap()

        XCTAssertTrue(app.staticTexts["Delete Me"].waitForExistence(timeout: 5))

        let selectButton = app.buttons["selectButton"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 5))
        selectButton.tap()

        let stackCell = app.buttons["stack_Delete Me"]
        XCTAssertTrue(stackCell.waitForExistence(timeout: 5))
        stackCell.tap()

        let deleteButton = app.buttons["deleteButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        XCTAssertTrue(app.staticTexts["No Stacks Yet"].waitForExistence(timeout: 5))
    }

    func testCancelAddStack() {
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        XCTAssertTrue(app.staticTexts["No Stacks Yet"].waitForExistence(timeout: 5))
    }

    func testStackThumbnailExists() {
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["stackNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Thumbnail Test")

        app.buttons["confirmButton"].tap()

        // Verify the stack card appears (placeholder since no strokes drawn)
        XCTAssertTrue(app.staticTexts["Thumbnail Test"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 page"].waitForExistence(timeout: 5))
    }

    func testSettingsButtonOpensSettings() {
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        let doneButton = app.buttons["settingsDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
    }

    func testStackContextMenuExists() {
        // Create a stack first
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["stackNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Menu Test")

        app.buttons["confirmButton"].tap()

        XCTAssertTrue(app.staticTexts["Menu Test"].waitForExistence(timeout: 5))

        // Tap the context menu button
        let menuButton = app.buttons["stackMenuButton_Menu Test"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        // Verify menu items appear
        XCTAssertTrue(app.buttons["Rename"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Duplicate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 5))
    }

    func testRenameStack() {
        // Create a stack
        let addButton = app.buttons["addStackButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["stackNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Old Name")

        app.buttons["confirmButton"].tap()

        XCTAssertTrue(app.staticTexts["Old Name"].waitForExistence(timeout: 5))

        // Open context menu and tap Rename
        let menuButton = app.buttons["stackMenuButton_Old Name"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        let renameButton = app.buttons["Rename"]
        XCTAssertTrue(renameButton.waitForExistence(timeout: 5))
        renameButton.tap()

        // Alert should appear with text field
        let alertTextField = app.textFields["Stack Name"]
        XCTAssertTrue(alertTextField.waitForExistence(timeout: 5))
        alertTextField.tap()
        // Select all and replace
        alertTextField.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) {
            app.menuItems["Select All"].tap()
        }
        alertTextField.typeText("New Name")

        // Confirm rename
        app.buttons["Rename"].tap()

        // Verify new name is displayed
        XCTAssertTrue(app.staticTexts["New Name"].waitForExistence(timeout: 5))
    }
}

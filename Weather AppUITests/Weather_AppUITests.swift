//
//  Weather_AppUITests.swift
//  Weather AppUITests
//
//  Created by Banka Rajesh on 10/27/26.
//

import XCTest

/// End-to-end UI flows against stubbed services (`-uiTesting`), so no network or
/// location prompt is involved and results are deterministic.
final class Weather_AppUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    @MainActor
    private func search(_ city: String) {
        let field = app.searchFields[AccessibilityID.Weather.searchField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(city + "\n")
    }

    @MainActor
    func testShowsSearchPromptOnFirstLaunch() {
        XCTAssertTrue(app.staticTexts[AccessibilityID.Weather.emptyState].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSearchShowsWeather() {
        search("Austin")

        XCTAssertTrue(app.staticTexts[AccessibilityID.Weather.locationName].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts[AccessibilityID.Weather.locationName].label, "Austin, Texas")
        XCTAssertEqual(app.staticTexts[AccessibilityID.Weather.temperature].label, "72°F")
    }

    @MainActor
    func testPickingSuggestionDismissesListAndShowsWeather() {
        let field = app.searchFields[AccessibilityID.Weather.searchField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()

        // The list appears on tap, before typing.
        XCTAssertTrue(app.staticTexts[AccessibilityID.CitySearch.prompt].waitForExistence(timeout: 5))

        field.typeText("Aus")
        let suggestion = app.staticTexts["Austin, TX"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Austell, GA"].exists)
        XCTAssertFalse(app.staticTexts["Springfield, IL"].exists) // filtered out by the search term

        suggestion.tap()

        XCTAssertTrue(app.staticTexts[AccessibilityID.Weather.locationName].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts[AccessibilityID.Weather.locationName].label, "Austin, TX")
        XCTAssertFalse(app.otherElements[AccessibilityID.CitySearch.suggestions].exists) // list dismissed
    }

    @MainActor
    func testUnknownCityShowsFriendlyErrorWithoutRetry() {
        search("Nowhere")

        XCTAssertTrue(app.staticTexts[AccessibilityID.Weather.errorMessage].waitForExistence(timeout: 5))
        // Searching the same unknown name again would fail the same way, so no Try Again.
        XCTAssertFalse(app.buttons[AccessibilityID.Weather.retryButton].exists)
    }

    @MainActor
    func testUnitToggleSwitchesToCelsius() {
        search("Austin")
        XCTAssertTrue(app.staticTexts[AccessibilityID.Weather.temperature].waitForExistence(timeout: 5))

        // "°C" is the segment title (TemperatureUnit.symbol), not translatable copy.
        app.segmentedControls[AccessibilityID.Weather.unitToggle].buttons["°C"].tap()

        let celsius = NSPredicate(format: "label == '22°C'")
        expectation(for: celsius, evaluatedWith: app.staticTexts[AccessibilityID.Weather.temperature])
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testDeniedLocationOffersSettings() {
        app.buttons[AccessibilityID.Weather.currentLocationButton].tap()

        XCTAssertTrue(app.buttons[AccessibilityID.Weather.openSettingsButton].waitForExistence(timeout: 5))
    }

    @MainActor
    func testWorksInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        search("Austin")

        XCTAssertTrue(app.staticTexts[AccessibilityID.Weather.temperature].waitForExistence(timeout: 5))
    }
}

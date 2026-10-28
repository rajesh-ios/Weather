//
//  WeatherDisplay.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation

/// View-ready weather: every value is already formatted and localized,
/// so views stay dumb and formatting is unit-testable.
struct WeatherDisplay: Equatable {
    struct Detail: Equatable, Identifiable {
        var id: String { title }
        let title: String
        let value: String
        let systemImage: String
    }

    let locationName: String
    let temperature: String
    let highLow: String
    let condition: String
    let iconURL: URL?
    let details: [Detail]
}

/// Maps the domain `Weather` into a `WeatherDisplay`.
/// `locale` is injectable so tests get deterministic output regardless of device settings.
struct WeatherFormatter {
    var locale: Locale = .autoupdatingCurrent

    func display(for weather: Weather, title: String?) -> WeatherDisplay {
        // Prefer our geocoded title ("Austin, Texas"); fall back to the API's station name.
        let name = [title, weather.stationName].compactMap { $0 }.first { !$0.isEmpty }
            ?? Strings.Weather.currentLocation
        let unit = weather.unit

        return WeatherDisplay(
            locationName: name,
            temperature: temperature(weather.temperature, unit, width: .abbreviated),
            highLow: Strings.Weather.highLow(high: temperature(weather.high, unit), low: temperature(weather.low, unit)),
            condition: weather.conditionDescription.capitalized(with: locale),
            iconURL: weather.iconCode.flatMap { Self.iconURL(for: $0) },
            details: details(for: weather)
        )
    }

    /// Icon catalog: https://openweathermap.org/weather-conditions
    static func iconURL(for code: String) -> URL? {
        guard !code.isEmpty, code.allSatisfy({ $0.isLetter || $0.isNumber }) else { return nil }
        return URL(string: "https://openweathermap.org/img/wn/\(code)@2x.png")
    }

    // MARK: - Private

    private func details(for weather: Weather) -> [WeatherDisplay.Detail] {
        typealias Detail = WeatherDisplay.Detail
        let unit = weather.unit
        var details = [
            Detail(title: Strings.Details.feelsLike,
                   value: temperature(weather.feelsLike, unit),
                   systemImage: SFSymbol.feelsLike)
        ]
        // Optional fields are skipped rather than shown as "--".
        if let humidity = weather.humidity {
            details.append(Detail(title: Strings.Details.humidity,
                                  value: percent(humidity),
                                  systemImage: SFSymbol.humidity))
        }
        if let speed = weather.windSpeed {
            details.append(Detail(title: Strings.Details.wind,
                                  value: measurement(speed, unit.speed),
                                  systemImage: SFSymbol.wind))
        }
        if let pressure = weather.pressure {
            details.append(Detail(title: Strings.Details.pressure,
                                  value: measurement(pressure, UnitPressure.hectopascals),
                                  systemImage: SFSymbol.pressure))
        }
        if let visibility = weather.visibility {
            let converted = Measurement(value: visibility, unit: UnitLength.meters).converted(to: unit.distance)
            details.append(Detail(title: Strings.Details.visibility,
                                  value: measurement(converted.value, unit.distance),
                                  systemImage: SFSymbol.visibility))
        }
        if let clouds = weather.cloudCover {
            details.append(Detail(title: Strings.Details.cloudCover,
                                  value: percent(clouds),
                                  systemImage: SFSymbol.cloudCover))
        }
        let timeZone = weather.timeZone ?? .current
        if let sunrise = weather.sunrise {
            details.append(Detail(title: Strings.Details.sunrise,
                                  value: time(sunrise, in: timeZone),
                                  systemImage: SFSymbol.sunrise))
        }
        if let sunset = weather.sunset {
            details.append(Detail(title: Strings.Details.sunset,
                                  value: time(sunset, in: timeZone),
                                  systemImage: SFSymbol.sunset))
        }
        return details
    }

    /// `.narrow` → "72°", `.abbreviated` → "72°F". `.asProvided` stops Foundation from
    /// converting to the locale's unit — the API already returned the user's chosen unit.
    private func temperature(
        _ value: Double,
        _ unit: TemperatureUnit,
        width: Measurement<UnitTemperature>.FormatStyle.UnitWidth = .narrow
    ) -> String {
        Measurement(value: value, unit: unit.temperature).formatted(
            .measurement(width: width, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))
                .locale(locale)
        )
    }

    private func measurement<U: Dimension>(_ value: Double, _ unit: U) -> String {
        Measurement(value: value, unit: unit).formatted(
            .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))
                .locale(locale)
        )
    }

    /// 0–100 → "40%".
    private func percent(_ value: Double) -> String {
        (value / 100).formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }

    /// Sunrise/sunset in the city's own time zone, not the device's.
    private func time(_ date: Date, in timeZone: TimeZone) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = timeZone
        style.locale = locale
        return date.formatted(style)
    }
}

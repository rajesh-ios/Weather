//
//  CurrentWeatherDataModel.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation

/// Response data model for the OpenWeather Current Weather API (`/data/2.5/weather`).
/// Only `main` and `name` are required; everything else is optional because the API
/// omits fields for some stations, and one missing field shouldn't hide the whole screen.
struct CurrentWeatherDataModel: Decodable, Equatable {
    struct Condition: Decodable, Equatable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    struct Main: Decodable, Equatable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let pressure: Double?
        let humidity: Double?
    }

    struct Wind: Decodable, Equatable {
        let speed: Double?
        let deg: Double?
    }

    struct Clouds: Decodable, Equatable {
        let all: Double?
    }

    struct Sys: Decodable, Equatable {
        let country: String?
        let sunrise: TimeInterval?
        let sunset: TimeInterval?
    }

    let weather: [Condition]
    let main: Main
    let visibility: Double?
    let wind: Wind?
    let clouds: Clouds?
    let sys: Sys?
    /// Shift in seconds from UTC for the city — used to show sunrise/sunset in local city time.
    let timezone: Int?
    let name: String

    /// The API returns an array; the first entry is the primary condition.
    var primaryCondition: Condition? { weather.first }

    private enum CodingKeys: String, CodingKey {
        case weather, main, visibility, wind, clouds, sys, timezone, name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Treat a missing `weather` array as empty instead of failing the whole decode.
        weather = try container.decodeIfPresent([Condition].self, forKey: .weather) ?? []
        main = try container.decode(Main.self, forKey: .main)
        visibility = try container.decodeIfPresent(Double.self, forKey: .visibility)
        wind = try container.decodeIfPresent(Wind.self, forKey: .wind)
        clouds = try container.decodeIfPresent(Clouds.self, forKey: .clouds)
        sys = try container.decodeIfPresent(Sys.self, forKey: .sys)
        timezone = try container.decodeIfPresent(Int.self, forKey: .timezone)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    }
}

// MARK: - Domain mapping

extension CurrentWeatherDataModel {
    /// Data → domain. `unit` is the unit the request was made in; OpenWeather
    /// doesn't echo it back, so the caller must supply it.
    func toDomain(unit: TemperatureUnit) -> Weather {
        Weather(
            unit: unit,
            stationName: name,
            conditionDescription: primaryCondition?.description ?? "",
            iconCode: primaryCondition?.icon,
            temperature: main.temp,
            feelsLike: main.feelsLike,
            low: main.tempMin,
            high: main.tempMax,
            humidity: main.humidity,
            windSpeed: wind?.speed,
            pressure: main.pressure,
            visibility: visibility,
            cloudCover: clouds?.all,
            sunrise: sys?.sunrise.map(Date.init(timeIntervalSince1970:)),
            sunset: sys?.sunset.map(Date.init(timeIntervalSince1970:)),
            timeZone: timezone.flatMap(TimeZone.init(secondsFromGMT:))
        )
    }
}

//
//  Strings.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Every user-facing string in the app, grouped by feature (see the `Strings+*.swift` extensions).

 - Keys are dotted and semantic (`weather.error.tryAgain`), not the English text, so copy can
   change without losing translations.
 - `defaultValue` is the English source text; translations live in `Localizable.xcstrings`.
 - `comment` gives translators context.
 - Computed (`static var`), so each read resolves against the current language.
 */
enum Strings {}

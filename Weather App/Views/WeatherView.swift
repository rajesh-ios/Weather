//
//  WeatherView.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import SwiftUI

/// SwiftUI content for the weather screen. Renders `WeatherViewModel.state`;
/// all user actions are forwarded to the ViewModel.
struct WeatherView: View {
    /// `@Observable` ViewModel: SwiftUI tracks the properties read in `body` automatically.
    let viewModel: WeatherViewModel
    let imageLoader: ImageLoader

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                ContentUnavailableView {
                    Label(Strings.Weather.emptyTitle, systemImage: SFSymbol.search)
                        .accessibilityIdentifier(AccessibilityID.Weather.emptyState)
                } description: {
                    Text(Strings.Weather.emptyMessage)
                }
            case .loading:
                ProgressView(Strings.Weather.loading)
                    .accessibilityIdentifier(AccessibilityID.Weather.loadingIndicator)
            case .loaded(let display):
                WeatherContentView(display: display, imageLoader: imageLoader)
            case .failed(let error):
                errorView(for: error)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.state)
    }

    private func errorView(for error: WeatherError) -> some View {
        ContentUnavailableView {
            Label(error.localizedDescription, systemImage: SFSymbol.warning)
                .accessibilityIdentifier(AccessibilityID.Weather.errorMessage)
        } description: {
            Text(error.recoverySuggestion ?? "")
        } actions: {
            if error.opensSettings {
                Button(Strings.Weather.openSettings) { viewModel.openSettings() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(AccessibilityID.Weather.openSettingsButton)
            } else if error.isRetryable {
                Button(Strings.Weather.tryAgain) {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AccessibilityID.Weather.retryButton)
            }
        }
    }
}

/// The loaded state. Adapts to size classes:
/// - compact width, regular height (iPhone portrait): stacked vertically
/// - compact height (iPhone landscape) or regular width (iPad): summary beside details
struct WeatherContentView: View {
    let display: WeatherDisplay
    let imageLoader: ImageLoader

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isSideBySide: Bool {
        verticalSizeClass == .compact || horizontalSizeClass == .regular
    }

    var body: some View {
        let layout = isSideBySide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 32))
            : AnyLayout(VStackLayout(spacing: 24))

        ScrollView {
            layout {
                summary
                    .frame(maxWidth: isSideBySide ? 320 : .infinity)
                details
            }
            .padding()
            .frame(maxWidth: 960) // keeps lines readable on large iPads
            .frame(maxWidth: .infinity)
        }
    }

    private var summary: some View {
        VStack(spacing: 8) {
            Text(display.locationName)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(AccessibilityID.Weather.locationName)

            WeatherIconView(url: display.iconURL, imageLoader: imageLoader)
                .frame(width: 120, height: 120)

            Text(display.temperature)
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .minimumScaleFactor(0.5)
                .accessibilityIdentifier(AccessibilityID.Weather.temperature)

            Text(display.condition)
                .font(.title3)
            Text(display.highLow)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        // VoiceOver reads the summary as one sentence instead of five stops.
        .accessibilityElement(children: .combine)
    }

    private var details: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(display.details) { detail in
                VStack(alignment: .leading, spacing: 6) {
                    Label(detail.title, systemImage: detail.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(detail.value)
                        .font(.title3.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Async icon with cache-backed loading and an SF Symbol fallback on failure.
struct WeatherIconView: View {
    let url: URL?
    let imageLoader: ImageLoader

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if failed || url == nil {
                Image(systemName: SFSymbol.weatherPlaceholder)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(24)
            } else {
                ProgressView()
            }
        }
        // `.task(id:)` cancels and restarts if the URL changes (e.g. a new search).
        .task(id: url) {
            image = nil
            failed = false
            guard let url else { return }
            do {
                image = try await imageLoader.image(for: url)
            } catch {
                failed = true
            }
        }
        // Decorative: the condition text next to it already describes the weather.
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

/// Formats a mock the same way the view model does.
private func previewDisplay(
    _ weather: Weather = Weather.Mocks.austinImperial,
    title: String? = Place.Mocks.austin.displayName
) -> WeatherDisplay {
    WeatherFormatter().display(for: weather, title: title)
}

// MARK: Screen states (driven through a real view model with stubbed dependencies)

#Preview("Idle – first launch") {
    WeatherView(viewModel: .preview(), imageLoader: ImageLoader.Stubs.icon)
}

#Preview("Loading") {
    let viewModel = WeatherViewModel.preview(.loading)
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.search("Austin") }
}

#Preview("Loaded – searched city") {
    let viewModel = WeatherViewModel.preview()
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.search("Austin") }
}

#Preview("Loaded – saved city on relaunch") {
    let viewModel = WeatherViewModel.preview(lastSearchedPlace: Place.Mocks.longName)
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.start() }
}

#Preview("Loaded – current location, no station name") {
    let viewModel = WeatherViewModel.preview(
        .success(Weather.Mocks.minimal),
        location: StubLocationProvider(permission: .granted, coordinate: .success(Coordinate.Mocks.newYork))
    )
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.useCurrentLocation() }
}

#Preview("Loaded – metric") {
    let viewModel = WeatherViewModel.preview(.success(Weather.Mocks.austinMetric), unit: .metric)
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.search("Austin") }
}

#Preview("Error – offline (Try Again)") {
    let viewModel = WeatherViewModel.preview(.failure(URLError(.notConnectedToInternet)))
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.search("Austin") }
}

#Preview("Error – server trouble (Try Again)") {
    let viewModel = WeatherViewModel.preview(.failure(WebServiceError.statusCode(503)))
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.search("Austin") }
}

#Preview("Error – location denied (Open Settings)") {
    let viewModel = WeatherViewModel.preview()
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.useCurrentLocation() }
}

#Preview("Error – city not found (no button)") {
    let viewModel = WeatherViewModel.preview(.failure(WeatherError.cityNotFound("Atlantis")))
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.search("Atlantis") }
}

#Preview("Error – missing API key (no button)") {
    let viewModel = WeatherViewModel.preview(.failure(WeatherError.missingAPIKey))
    WeatherView(viewModel: viewModel, imageLoader: ImageLoader.Stubs.icon)
        .task { await viewModel.search("Austin") }
}

// MARK: Loaded layout edge cases (content view rendered directly)

#Preview("Content – portrait") {
    WeatherContentView(display: previewDisplay(), imageLoader: ImageLoader.Stubs.icon)
}

#Preview("Content – iPhone landscape (side by side)", traits: .landscapeLeft) {
    WeatherContentView(display: previewDisplay(), imageLoader: ImageLoader.Stubs.icon)
}

#Preview("Content – iPad, regular width", traits: .fixedLayout(width: 1024, height: 768)) {
    WeatherContentView(display: previewDisplay(), imageLoader: ImageLoader.Stubs.icon)
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("Content – dark mode") {
    WeatherContentView(display: previewDisplay(), imageLoader: ImageLoader.Stubs.icon)
        .preferredColorScheme(.dark)
}

#Preview("Content – largest Dynamic Type") {
    WeatherContentView(display: previewDisplay(), imageLoader: ImageLoader.Stubs.icon)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Content – extreme values, long name and condition") {
    WeatherContentView(
        display: previewDisplay(Weather.Mocks.blizzard, title: Place.Mocks.longName.displayName),
        imageLoader: ImageLoader.Stubs.icon
    )
}

#Preview("Content – missing optional data") {
    WeatherContentView(display: previewDisplay(Weather.Mocks.minimal, title: nil), imageLoader: ImageLoader.Stubs.icon)
}

#Preview("Content – icon download failed") {
    WeatherContentView(display: previewDisplay(), imageLoader: ImageLoader.Stubs.failing)
}

#Preview("Content – icon still loading") {
    WeatherContentView(display: previewDisplay(), imageLoader: ImageLoader.Stubs.loading)
}

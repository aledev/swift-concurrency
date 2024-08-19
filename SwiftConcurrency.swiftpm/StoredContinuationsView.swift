//
//  StoredContinuationsView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 17/8/24.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct StoredContinuationsView: View {
    @StateObject var locationManager = LocationManager()
    @State var locationInfo: Result<CLLocationCoordinate2D?, LocationError>?
    @State var loading = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 10) {
                    LocationButton {
                        Task {
                            defer { loading = false }
                            loading = true

                            do {
                                let location = try await locationManager.requestLocation()
                                locationInfo = .success(location)
                            } catch(let error) {
                                locationInfo = .failure(LocationError.unknownLocation(error))
                            }
                        }
                    }
                    .frame(height: 44)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding()

                    if let locationInfo {
                        switch locationInfo {
                        case .success(let success):
                            Text("\(success?.latitude ?? 0),\(success?.longitude ?? 0)")
                        case .failure(let failure):
                            Text("Location Error. Detail: \(failure)")
                        }
                    } else {
                        Text("Unknown location")
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )

                if loading {
                    VStack {
                        VStack {
                            ProgressView(label: {
                                Text("Loading...")
                            })
                            .font(.title3)
                            .tint(.white)
                            .foregroundColor(.white)
                            .progressViewStyle(.circular)
                        }
                        .padding()
                        .background(
                            Color(.black)
                                .opacity(0.5)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 10
                            )
                        )
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .background {
                        Color(.gray)
                            .opacity(0.5)
                    }
                }
            }
        }
    }
}

// MARK: - Internal objects
extension StoredContinuationsView {
    enum LocationError: Error {
        case unknownLocation(Error)
    }

    @MainActor
    class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
        var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Error>?
        var manager: CLLocationManager?

        override init() {
            super.init()
            manager = CLLocationManager()
            manager?.delegate = self
        }

        deinit {
            debugPrint("Deinit was invoked!")
            manager?.delegate = nil
            manager?.stopUpdatingLocation()
            manager = nil
        }

        func requestLocation() async throws -> CLLocationCoordinate2D? {
            try await withCheckedThrowingContinuation { continuation in
                locationContinuation = continuation
                manager?.requestLocation()
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            debugPrint("LocationManager > didUpdatedLocations!")
            locationContinuation?.resume(returning: locations.first?.coordinate)
            // Resets the continuation object, otherwise the app will crash.
            // Comment the following line to double check it.
            locationContinuation = nil
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
            debugPrint("LocationManager > didFailWithError!")
            locationContinuation?.resume(throwing: LocationError.unknownLocation(error))
            // Resets the continuation object
            locationContinuation = nil
        }
    }
}

// MARK: - Previews
#Preview {
    StoredContinuationsView()
}

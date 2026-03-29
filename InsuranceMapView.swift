import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Facility Type
enum FacilityType: String, CaseIterable, Equatable {
    case hospital     = "Hospital"
    case urgentCare   = "Urgent Care"
    case primaryCare  = "Primary Care"
    case specialist   = "Specialist"
    case dentist      = "Dentist"
    case orthodontist = "Orthodontist"
    case optometrist  = "Optometrist"
    case eyewear      = "Eyewear"
    case pharmacy     = "Pharmacy"

    var icon: String {
        switch self {
        case .hospital:     return "cross.fill"
        case .urgentCare:   return "staroflife.fill"
        case .primaryCare:  return "person.fill"
        case .specialist:   return "stethoscope"
        case .dentist:      return "mouth.fill"
        case .orthodontist: return "mouth.fill"
        case .optometrist:  return "eye.fill"
        case .eyewear:      return "eyeglasses"
        case .pharmacy:     return "pills.fill"
        }
    }

    var color: Color {
        switch self {
        case .hospital:     return .red
        case .urgentCare:   return .orange
        case .primaryCare:  return .blue
        case .specialist:   return .purple
        case .dentist:      return .purple
        case .orthodontist: return .indigo
        case .optometrist:  return .teal
        case .eyewear:      return .cyan
        case .pharmacy:     return .green
        }
    }
}

// MARK: - Facility Pin Model
struct FacilityPin: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
    var facilityType: FacilityType
    var insuranceCategory: InsuranceCategory
    var isInNetwork: Bool
    var tier: Int = 1
    var phone: String = ""
    var address: String = ""
    var isER24_7: Bool = false
    var estimatedCopay: String = ""
    var distance: Double = 0.0
    var rating: Double = 0.0
    var acceptingNewPatients: Bool = true
    
    static func == (lhs: FacilityPin, rhs: FacilityPin) -> Bool {
            lhs.id == rhs.id
    }
}

// MARK: - Facility Annotation (MapKit)
class FacilityAnnotation: NSObject, MKAnnotation {
    let facility: FacilityPin
    var coordinate: CLLocationCoordinate2D { facility.coordinate }
    var title: String? { facility.name }
    var subtitle: String? {
        facility.isInNetwork ? "✅ In-Network" : "🔴 Out-of-Network"
    }

    init(facility: FacilityPin) {
        self.facility = facility
    }
}

// MARK: - Network Overlay (Polygon)
class NetworkOverlay: MKPolygon {
    var insuranceCategory: InsuranceCategory = .health
    var isInNetwork: Bool = true
    var tier: Int = 1
}

// MARK: - Location Manager
// CLLocationCoordinate2D does not conform to Equatable,
// so @Published var userLocation cannot be used directly
// in onChange. We expose a separate Equatable signal instead.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationName: String = "Your Location"

    // ✅ Equatable proxy — onChange watches this Double instead
    // of the raw CLLocationCoordinate2D
    @Published var locationUpdateTick: Int = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last?.coordinate
        locationUpdateTick += 1  // ✅ Triggers onChange safely
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}


// MARK: - Map View Representable
struct InsuranceMapViewRepresentable: UIViewRepresentable {

    @Binding var selectedFacility: FacilityPin?
    @Binding var region: MKCoordinateRegion
    var facilities: [FacilityPin]
    var overlays: [NetworkOverlay]
    var activeCategory: InsuranceCategory
    var showNetworkZones: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .includingAll
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region smoothly
        mapView.setRegion(region, animated: true)

        // Remove old annotations
        let existing = mapView.annotations.filter {
            $0 is FacilityAnnotation
        }
        mapView.removeAnnotations(existing)

        // Add filtered annotations
        let filtered = facilities.filter {
            $0.insuranceCategory == activeCategory
        }
        let annotations = filtered.map { FacilityAnnotation(facility: $0) }
        mapView.addAnnotations(annotations)

        // Remove old overlays
        mapView.removeOverlays(mapView.overlays)

        // Add network zone overlays
        if showNetworkZones {
            let activeOverlays = overlays.filter {
                $0.insuranceCategory == activeCategory
            }
            mapView.addOverlays(activeOverlays, level: .aboveRoads)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: InsuranceMapViewRepresentable

        init(_ parent: InsuranceMapViewRepresentable) {
            self.parent = parent
        }

        // MARK: Custom Annotation View
        func mapView(_ mapView: MKMapView,
                     viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let facilityAnnotation = annotation as? FacilityAnnotation
            else { return nil }

            let identifier = "FacilityPin"
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(
                annotation: facilityAnnotation,
                reuseIdentifier: identifier
            )

            let facility = facilityAnnotation.facility
            view.annotation = facilityAnnotation
            view.canShowCallout = true
            view.glyphImage = UIImage(
                systemName: facility.facilityType.icon
            )
            view.markerTintColor = facility.isInNetwork
                ? UIColor(facility.facilityType.color)
                : .systemGray

            // Callout accessory
            let detailButton = UIButton(type: .detailDisclosure)
            view.rightCalloutAccessoryView = detailButton

            // Distance badge
            if facility.distance > 0 {
                let distLabel = UILabel()
                distLabel.text = String(
                    format: "%.1f mi", facility.distance
                )
                distLabel.font = .systemFont(ofSize: 11, weight: .medium)
                distLabel.textColor = .secondaryLabel
                view.leftCalloutAccessoryView = distLabel
            }

            // Priority sizing
            view.displayPriority = facility.isER24_7
                ? .required
                : (facility.isInNetwork ? .defaultHigh : .defaultLow)

            return view
        }

        // MARK: Callout Tap → Show Detail Sheet
        func mapView(_ mapView: MKMapView,
                     annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            guard let facilityAnnotation = view.annotation
                    as? FacilityAnnotation else { return }
            parent.selectedFacility = facilityAnnotation.facility
        }

        // MARK: Annotation Tap → Select
        func mapView(_ mapView: MKMapView,
                     didSelect view: MKAnnotationView) {
            guard let facilityAnnotation = view.annotation
                    as? FacilityAnnotation else { return }
            parent.selectedFacility = facilityAnnotation.facility
        }

        // MARK: Network Zone Overlay Renderer
        func mapView(_ mapView: MKMapView,
                     rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let networkOverlay = overlay as? NetworkOverlay else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolygonRenderer(polygon: networkOverlay)

            let category = networkOverlay.insuranceCategory
            let inNetwork = networkOverlay.isInNetwork

            switch category {
            case .health:
                renderer.fillColor = inNetwork
                    ? UIColor.systemBlue.withAlphaComponent(0.15)
                    : UIColor.systemBlue.withAlphaComponent(0.05)
                renderer.strokeColor = inNetwork
                    ? UIColor.systemBlue.withAlphaComponent(0.55)
                    : UIColor.systemBlue.withAlphaComponent(0.2)
            case .dental:
                renderer.fillColor = inNetwork
                    ? UIColor.systemPurple.withAlphaComponent(0.15)
                    : UIColor.systemPurple.withAlphaComponent(0.05)
                renderer.strokeColor = inNetwork
                    ? UIColor.systemPurple.withAlphaComponent(0.55)
                    : UIColor.systemPurple.withAlphaComponent(0.2)
            case .vision:
                renderer.fillColor = inNetwork
                    ? UIColor.systemTeal.withAlphaComponent(0.15)
                    : UIColor.systemTeal.withAlphaComponent(0.05)
                renderer.strokeColor = inNetwork
                    ? UIColor.systemTeal.withAlphaComponent(0.55)
                    : UIColor.systemTeal.withAlphaComponent(0.2)
            }

            renderer.lineWidth = inNetwork ? 2.0 : 1.0
            renderer.lineDashPattern = inNetwork ? nil : [6, 4]

            return renderer
        }
    }
}

// MARK: - Sample Data Builder
struct MapSampleData {

    // MARK: Sample Facilities
    static func facilities() -> [FacilityPin] {
        [
            FacilityPin(
                name: "St. Mary's Medical Center",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.338, longitude: -122.025
                ),
                facilityType: .hospital,
                insuranceCategory: .health,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 234-5678",
                address: "123 Medical Dr, Cupertino, CA",
                isER24_7: true,
                estimatedCopay: "$250 ER copay",
                distance: 2.4,
                rating: 4.3,
                acceptingNewPatients: true
            ),
            FacilityPin(
                name: "QuickCare Urgent Care",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.325, longitude: -122.040
                ),
                facilityType: .urgentCare,
                insuranceCategory: .health,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 345-6789",
                address: "456 Health Blvd, Sunnyvale, CA",
                isER24_7: false,
                estimatedCopay: "$50 copay",
                distance: 1.1,
                rating: 4.6,
                acceptingNewPatients: true
            ),
            FacilityPin(
                name: "Valley Primary Care",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.320, longitude: -122.018
                ),
                facilityType: .primaryCare,
                insuranceCategory: .health,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 456-7890",
                address: "789 Wellness Ave, Santa Clara, CA",
                isER24_7: false,
                estimatedCopay: "$30 copay",
                distance: 3.7,
                rating: 4.8,
                acceptingNewPatients: true
            ),
            FacilityPin(
                name: "Westside Specialist Group",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.350, longitude: -122.050
                ),
                facilityType: .specialist,
                insuranceCategory: .health,
                isInNetwork: false,
                tier: 2,
                phone: "(555) 567-8901",
                address: "321 Specialist Row, San Jose, CA",
                isER24_7: false,
                estimatedCopay: "$80 copay (out-of-network)",
                distance: 5.2,
                rating: 3.9,
                acceptingNewPatients: false
            ),
            FacilityPin(
                name: "Bright Smiles Dental",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.330, longitude: -122.035
                ),
                facilityType: .dentist,
                insuranceCategory: .dental,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 678-9012",
                address: "654 Dental Ave, Cupertino, CA",
                isER24_7: false,
                estimatedCopay: "100% preventive",
                distance: 0.8,
                rating: 4.9,
                acceptingNewPatients: true
            ),
            FacilityPin(
                name: "Perfect Smiles Orthodontics",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.345, longitude: -122.022
                ),
                facilityType: .orthodontist,
                insuranceCategory: .dental,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 789-0123",
                address: "987 Ortho Blvd, Sunnyvale, CA",
                isER24_7: false,
                estimatedCopay: "50% after deductible",
                distance: 4.1,
                rating: 4.7,
                acceptingNewPatients: true
            ),
            FacilityPin(
                name: "ClearVision Eye Care",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.342, longitude: -122.028
                ),
                facilityType: .optometrist,
                insuranceCategory: .vision,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 890-1234",
                address: "159 Vision Way, Cupertino, CA",
                isER24_7: false,
                estimatedCopay: "$10 exam copay",
                distance: 3.2,
                rating: 4.5,
                acceptingNewPatients: true
            ),
            FacilityPin(
                name: "LensCrafters — Valley Fair",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.315, longitude: -121.945
                ),
                facilityType: .eyewear,
                insuranceCategory: .vision,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 901-2345",
                address: "2855 Stevens Creek Blvd, Santa Clara, CA",
                isER24_7: false,
                estimatedCopay: "$150 frame allowance",
                distance: 6.8,
                rating: 4.2,
                acceptingNewPatients: true
            ),
            FacilityPin(
                name: "CVS Pharmacy",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.332, longitude: -122.030
                ),
                facilityType: .pharmacy,
                insuranceCategory: .health,
                isInNetwork: true,
                tier: 1,
                phone: "(555) 012-3456",
                address: "753 Main St, Cupertino, CA",
                isER24_7: false,
                estimatedCopay: "$10 generic / $35 brand",
                distance: 1.5,
                rating: 4.1,
                acceptingNewPatients: true
            )
        ]
    }

    // MARK: Sample Network Overlays
    static func overlays() -> [NetworkOverlay] {
        var result: [NetworkOverlay] = []

        // Health — In-Network zone
        let healthInCoords = circleCoordinates(
            center: CLLocationCoordinate2D(
                latitude: 37.3318, longitude: -122.0312
            ),
            radiusDegrees: 0.12,
            points: 60
        )
        let healthIn = NetworkOverlay(
            coordinates: healthInCoords,
            count: healthInCoords.count
        )
        healthIn.insuranceCategory = .health
        healthIn.isInNetwork = true
        result.append(healthIn)

        // Health — Tier 2 zone (larger)
        let healthT2Coords = circleCoordinates(
            center: CLLocationCoordinate2D(
                latitude: 37.3318, longitude: -122.0312
            ),
            radiusDegrees: 0.22,
            points: 60
        )
        let healthT2 = NetworkOverlay(
            coordinates: healthT2Coords,
            count: healthT2Coords.count
        )
        healthT2.insuranceCategory = .health
        healthT2.isInNetwork = false
        result.append(healthT2)

        // Dental — In-Network zone
        let dentalCoords = circleCoordinates(
            center: CLLocationCoordinate2D(
                latitude: 37.3318, longitude: -122.0312
            ),
            radiusDegrees: 0.10,
            points: 60
        )
        let dentalIn = NetworkOverlay(
            coordinates: dentalCoords,
            count: dentalCoords.count
        )
        dentalIn.insuranceCategory = .dental
        dentalIn.isInNetwork = true
        result.append(dentalIn)

        // Vision — In-Network zone
        let visionCoords = circleCoordinates(
            center: CLLocationCoordinate2D(
                latitude: 37.3318, longitude: -122.0312
            ),
            radiusDegrees: 0.09,
            points: 60
        )
        let visionIn = NetworkOverlay(
            coordinates: visionCoords,
            count: visionCoords.count
        )
        visionIn.insuranceCategory = .vision
        visionIn.isInNetwork = true
        result.append(visionIn)

        return result
    }

    // MARK: Circle Coordinate Generator
    static func circleCoordinates(
        center: CLLocationCoordinate2D,
        radiusDegrees: Double,
        points: Int
    ) -> [CLLocationCoordinate2D] {
        (0..<points).map { i in
            let angle = (Double(i) / Double(points)) * 2.0 * .pi
            return CLLocationCoordinate2D(
                latitude:  center.latitude  + radiusDegrees * cos(angle),
                longitude: center.longitude + radiusDegrees * sin(angle)
            )
        }
    }
}

// MARK: - Insurance Map Tab View
struct InsuranceMapTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var locationManager = LocationManager()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 37.3318, longitude: -122.0312
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.15,
            longitudeDelta: 0.15
        )
    )

    @State private var selectedFacility: FacilityPin? = nil
    @State private var showFacilitySheet: Bool = false
    @State private var showNetworkZones: Bool = true
    @State private var showFilters: Bool = false
    @State private var filterInNetworkOnly: Bool = false
    @State private var filterFacilityType: FacilityType? = nil
    @State private var searchText: String = ""
    @State private var mapType: MKMapType = .standard

    let allFacilities = MapSampleData.facilities()
    let allOverlays   = MapSampleData.overlays()

    // MARK: - Filtered Facilities
    var filteredFacilities: [FacilityPin] {
        var result = allFacilities.filter {
            $0.insuranceCategory == appState.activeInsuranceTab
        }
        if filterInNetworkOnly {
            result = result.filter { $0.isInNetwork }
        }
        if let type = filterFacilityType {
            result = result.filter { $0.facilityType == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText) ||
                $0.facilityType.rawValue
                    .localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {

                InsuranceMapViewRepresentable(
                    selectedFacility: $selectedFacility,
                    region: $region,
                    facilities: filteredFacilities,
                    overlays: allOverlays,
                    activeCategory: appState.activeInsuranceTab,
                    showNetworkZones: showNetworkZones
                )
                .ignoresSafeArea(edges: .top)

                // ✅ FacilityPin is now Equatable — this compiles cleanly
                .onChange(of: selectedFacility) { oldValue, newValue in
                    if newValue != nil {
                        showFacilitySheet = true
                    }
                }

                // ✅ Watching Int tick instead of CLLocationCoordinate2D
                .onChange(of: locationManager.locationUpdateTick) { _, _ in
                    if let loc = locationManager.userLocation {
                        withAnimation {
                            region.center = loc
                        }
                    }
                }


                VStack(spacing: 0) {

                    // MARK: Top Controls Bar
                    VStack(spacing: 10) {

                        // Search Bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField(
                                "Search hospitals, dentists...",
                                text: $searchText
                            )
                            .autocapitalization(.none)
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Insurance Category Switcher
                        HStack(spacing: 0) {
                            ForEach(
                                InsuranceCategory.allCases,
                                id: \.self
                            ) { cat in
                                Button {
                                    withAnimation(.spring(
                                        response: 0.35,
                                        dampingFraction: 0.75
                                    )) {
                                        appState.activeInsuranceTab = cat
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(
                                            systemName: categoryIcon(cat)
                                        )
                                        .font(.caption)
                                        Text(cat.rawValue)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(
                                        appState.activeInsuranceTab == cat
                                        ? categoryColor(cat)
                                        : Color.clear
                                    )
                                    .foregroundColor(
                                        appState.activeInsuranceTab == cat
                                        ? .white : .primary
                                    )
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)

                    Spacer()

                    // MARK: Bottom Controls Row
                    HStack(spacing: 12) {

                        // Network Zone Toggle
                        MapControlButton(
                            icon: showNetworkZones
                                ? "map.fill" : "map",
                            label: "Zones",
                            isActive: showNetworkZones,
                            color: categoryColor(appState.activeInsuranceTab)
                        ) {
                            withAnimation {
                                showNetworkZones.toggle()
                            }
                        }

                        // Filter Toggle
                        MapControlButton(
                            icon: "line.3.horizontal.decrease.circle"
                                + (filterInNetworkOnly ? ".fill" : ""),
                            label: "Filter",
                            isActive: filterInNetworkOnly
                                || filterFacilityType != nil,
                            color: .orange
                        ) {
                            showFilters = true
                        }

                        // Map Type Toggle
                        MapControlButton(
                            icon: mapType == .standard
                                ? "globe" : "map",
                            label: mapType == .standard
                                ? "Satellite" : "Standard",
                            isActive: mapType == .satellite,
                            color: .gray
                        ) {
                            mapType = mapType == .standard
                                ? .satellite : .standard
                        }

                        // Re-center on user
                        MapControlButton(
                            icon: "location.fill",
                            label: "My Location",
                            isActive: false,
                            color: .blue
                        ) {
                            if let loc = locationManager.userLocation {
                                withAnimation {
                                    region = MKCoordinateRegion(
                                        center: loc,
                                        span: MKCoordinateSpan(
                                            latitudeDelta: 0.08,
                                            longitudeDelta: 0.08
                                        )
                                    )
                                }
                            } else {
                                locationManager.requestPermission()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // MARK: Nearby Facilities Horizontal Scroll
                    NearbyFacilitiesScroll(
                        facilities: filteredFacilities
                            .sorted { $0.distance < $1.distance }
                            .prefix(8)
                            .map { $0 },
                        activeCategory: appState.activeInsuranceTab
                    ) { facility in
                        selectedFacility = facility
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: facility.coordinate,
                                span: MKCoordinateSpan(
                                    latitudeDelta: 0.04,
                                    longitudeDelta: 0.04
                                )
                            )
                        }
                        showFacilitySheet = true
                    }
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("🗺️ Coverage Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NetworkLegendButton(
                        category: appState.activeInsuranceTab
                    )
                }
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
        // MARK: Facility Detail Sheet
        .sheet(isPresented: $showFacilitySheet,
               onDismiss: { selectedFacility = nil }) {
            if let facility = selectedFacility {
                FacilityDetailSheet(
                    facility: facility,
                    activeCategory: appState.activeInsuranceTab
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        // MARK: Filter Sheet
        .sheet(isPresented: $showFilters) {
            MapFilterSheet(
                filterInNetworkOnly: $filterInNetworkOnly,
                filterFacilityType: $filterFacilityType,
                activeCategory: appState.activeInsuranceTab
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helpers
    func categoryIcon(_ cat: InsuranceCategory) -> String {
        switch cat {
        case .health: return "heart.fill"
        case .dental: return "mouth.fill"
        case .vision: return "eye.fill"
        }
    }

    func categoryColor(_ cat: InsuranceCategory) -> Color {
        switch cat {
        case .health: return .blue
        case .dental: return .purple
        case .vision: return .teal
        }
    }
}

// MARK: - Map Control Button
struct MapControlButton: View {
    var icon: String
    var label: String
    var isActive: Bool
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? .white : color)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isActive ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isActive
                ? color
                : Color(.systemBackground).opacity(0.92)
            )
            .cornerRadius(12)
            .shadow(
                color: .black.opacity(0.08),
                radius: 4, x: 0, y: 2
            )
        }
    }
}

// MARK: - Nearby Facilities Scroll
struct NearbyFacilitiesScroll: View {
    var facilities: [FacilityPin]
    var activeCategory: InsuranceCategory
    var onSelect: (FacilityPin) -> Void

    var color: Color {
        switch activeCategory {
        case .health: return .blue
        case .dental: return .purple
        case .vision: return .teal
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby Providers")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(facilities) { facility in
                        NearbyFacilityChip(
                            facility: facility,
                            color: color,
                            onTap: { onSelect(facility) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Nearby Facility Chip
struct NearbyFacilityChip: View {
    var facility: FacilityPin
    var color: Color
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: facility.facilityType.icon)
                        .font(.caption)
                        .foregroundColor(
                            facility.isInNetwork ? color : .gray
                        )
                    Text(facility.facilityType.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    if facility.isER24_7 {
                        Text("24/7")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }

                Text(facility.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(
                        String(format: "%.1f mi", facility.distance),
                        systemImage: "location.fill"
                    )
                    .font(.caption2)
                    .foregroundColor(.secondary)

                    Text(facility.isInNetwork ? "In-Network" : "Out-of-Network")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(
                            facility.isInNetwork ? .green : .red
                        )
                }
            }
            .padding(10)
            .frame(width: 180)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(
                color: .black.opacity(0.06),
                radius: 4, x: 0, y: 2
            )
        }
    }
}

// MARK: - Facility Detail Sheet
struct FacilityDetailSheet: View {
    var facility: FacilityPin
    var activeCategory: InsuranceCategory
    @Environment(\.dismiss) var dismiss

    var color: Color {
        switch activeCategory {
        case .health: return .blue
        case .dental: return .purple
        case .vision: return .teal
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [
                                        facility.facilityType.color,
                                        facility.facilityType.color.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            Image(systemName: facility.facilityType.icon)
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)

                        Text(facility.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            NetworkStatusBadge(
                                isInNetwork: facility.isInNetwork,
                                tier: facility.tier
                            )
                            if facility.isER24_7 {
                                ERBadge()
                            }
                            if facility.acceptingNewPatients {
                                AcceptingBadge()
                            }
                        }
                    }

                    // MARK: Details
                    VStack(spacing: 12) {
                        FacilityDetailRow(
                            icon: "mappin.circle.fill",
                            label: "Address",
                            value: facility.address,
                            color: .red
                        )
                        FacilityDetailRow(
                            icon: "phone.fill",
                            label: "Phone",
                            value: facility.phone,
                            color: .green,
                            isPhone: true
                        )
                        FacilityDetailRow(
                            icon: "dollarsign.circle.fill",
                            label: "Est. Cost",
                            value: facility.estimatedCopay.isEmpty
                                ? "Contact for pricing"
                                : facility.estimatedCopay,
                            color: .orange
                        )
                        FacilityDetailRow(
                            icon: "location.fill",
                            label: "Distance",
                            value: String(
                                format: "%.1f miles away",
                                facility.distance
                            ),
                            color: .blue
                        )
                        if facility.rating > 0 {
                            FacilityDetailRow(
                                icon: "star.fill",
                                label: "Rating",
                                value: String(
                                    format: "%.1f / 5.0",
                                    facility.rating
                                ),
                                color: .yellow
                            )
                        }
                    }
                    .padding(.horizontal)

                    // MARK: Action Buttons
                    VStack(spacing: 10) {
                        if !facility.phone.isEmpty {
                            Link(destination: URL(
                                string: "tel:\(facility.phone.filter { $0.isNumber })"
                            )!) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call Now")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                        }

                        Button {
                            openInMaps(facility: facility)
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Get Directions")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(color)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Provider Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: Open in Apple Maps
    func openInMaps(facility: FacilityPin) {
        let placemark = MKPlacemark(
            coordinate: facility.coordinate
        )
        let item = MKMapItem(placemark: placemark)
        item.name = facility.name
        item.phoneNumber = facility.phone
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey:
                MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Network Status Badge
struct NetworkStatusBadge: View {
    var isInNetwork: Bool
    var tier: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(
                systemName: isInNetwork
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.caption2)
            Text(isInNetwork
                 ? (tier == 1 ? "Tier 1 In-Network" : "Tier 2 In-Network")
                 : "Out-of-Network")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isInNetwork
            ? Color.green.opacity(0.15)
            : Color.red.opacity(0.15)
        )
        .foregroundColor(isInNetwork ? .green : .red)
        .cornerRadius(8)
    }
}

// MARK: - ER Badge
struct ERBadge: View {
    var body: some View {
        Text("ER 24/7")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.15))
            .foregroundColor(.red)
            .cornerRadius(8)
    }
}

// MARK: - Accepting Badge
struct AcceptingBadge: View {
    var body: some View {
        Text("Accepting Patients")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

// MARK: - Facility Detail Row
struct FacilityDetailRow: View {
    var icon: String
    var label: String
    var value: String
    var color: Color
    var isPhone: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if isPhone {
                    Link(value, destination: URL(
                        string: "tel:\(value.filter { $0.isNumber })"
                    )!)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                } else {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Map Filter Sheet
struct MapFilterSheet: View {
    @Binding var filterInNetworkOnly: Bool
    @Binding var filterFacilityType: FacilityType?
    var activeCategory: InsuranceCategory
    @Environment(\.dismiss) var dismiss

    var relevantTypes: [FacilityType] {
        switch activeCategory {
        case .health:
            return [.hospital, .urgentCare, .primaryCare,
                    .specialist, .pharmacy]
        case .dental:
            return [.dentist, .orthodontist]
        case .vision:
            return [.optometrist, .eyewear]
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // In-Network Toggle
                Toggle(isOn: $filterInNetworkOnly) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("In-Network Only")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .tint(.green)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Facility Type Filter
                VStack(alignment: .leading, spacing: 10) {
                    Text("Provider Type")
                        .font(.headline)
                        .fontWeight(.semibold)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 10
                    ) {
                        // All option
                        Button {
                            filterFacilityType = nil
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.subheadline)
                                Text("All Types")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                filterFacilityType == nil
                                ? Color.blue
                                : Color(.secondarySystemBackground)
                            )
                            .foregroundColor(
                                filterFacilityType == nil
                                ? .white : .primary
                            )
                            .cornerRadius(10)
                        }

                        ForEach(relevantTypes, id: \.self) { type in
                            Button {
                                filterFacilityType = (
                                    filterFacilityType == type
                                ) ? nil : type
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: type.icon)
                                        .font(.subheadline)
                                    Text(type.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(
                                    filterFacilityType == type
                                    ? type.color
                                    : Color(.secondarySystemBackground)
                                )
                                .foregroundColor(
                                    filterFacilityType == type
                                    ? .white : .primary
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                }

                Spacer()

                // Reset Button
                Button {
                    filterInNetworkOnly = false
                    filterFacilityType = nil
                    dismiss()
                } label: {
                    Text("Reset Filters")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.secondary)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Filter Providers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Network Legend Button
struct NetworkLegendButton: View {
    var category: InsuranceCategory
    @State private var showLegend: Bool = false

    var color: Color {
        switch category {
        case .health: return .blue
        case .dental: return .purple
        case .vision: return .teal
        }
    }

    var body: some View {
        Button {
            showLegend = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(color)
        }
        .sheet(isPresented: $showLegend) {
            NetworkLegendSheet(category: category, color: color)
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Network Legend Sheet
struct NetworkLegendSheet: View {
    var category: InsuranceCategory
    var color: Color
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Map Legend")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 8)

            LegendRow(
                color: color.opacity(0.6),
                label: "Tier 1 In-Network Zone",
                description: "Lowest cost — preferred providers"
            )
            LegendRow(
                color: color.opacity(0.25),
                label: "Tier 2 / Extended Zone",
                description: "Higher cost — still covered"
            )
            LegendRow(
                color: .gray.opacity(0.4),
                label: "Out-of-Network",
                description: "Not covered or very limited"
            )

            Divider()

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    Text("In-Network Pin")
                        .font(.caption)
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 12, height: 12)
                    Text("Out-of-Network Pin")
                        .font(.caption)
                }
                HStack(spacing: 6) {
                    Text("🔴")
                        .font(.caption)
                    Text("ER / 24-7")
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Legend Row
struct LegendRow: View {
    var color: Color
    var label: String
    var description: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 32, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(2), lineWidth: 1.5)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    InsuranceMapTabView()
        .environmentObject(AppState())
}


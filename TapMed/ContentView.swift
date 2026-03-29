import SwiftUI
import CoreLocation
import Combine
import LocalAuthentication
import HealthKit
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Codable {
    case system   = "System"
    case light    = "Light"
    case dark     = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Accent Color Option
enum AccentColorOption: String, CaseIterable, Codable {
    case blue   = "Blue"
    case indigo = "Indigo"
    case purple = "Purple"
    case pink   = "Pink"
    case red    = "Red"
    case orange = "Orange"
    case green  = "Green"
    case teal   = "Teal"

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink:   return .pink
        case .red:    return .red
        case .orange: return .orange
        case .green:  return .green
        case .teal:   return .teal
        }
    }
}

// MARK: - Card Style
enum CardStyle: String, CaseIterable, Codable {
    case rounded  = "Rounded"
    case sharp    = "Sharp"
    case floating = "Floating"

    var cornerRadius: CGFloat {
        switch self {
        case .rounded:  return 16
        case .sharp:    return 6
        case .floating: return 20
        }
    }
    var shadowRadius: CGFloat {
        switch self {
        case .rounded:  return 8
        case .sharp:    return 2
        case .floating: return 16
        }
    }
    var shadowOpacity: Double {
        switch self {
        case .rounded:  return 0.06
        case .sharp:    return 0.03
        case .floating: return 0.12
        }
    }
}

// MARK: - Font Size Option
enum FontSizeOption: String, CaseIterable, Codable {
    case small   = "Small"
    case medium  = "Medium"
    case large   = "Large"

    var scale: CGFloat {
        switch self {
        case .small:  return 0.88
        case .medium: return 1.0
        case .large:  return 1.14
        }
    }
}

// MARK: - App Settings
class AppSettings: ObservableObject {
    @Published var theme: AppTheme = .system
    @Published var accentColor: AccentColorOption = .blue
    @Published var cardStyle: CardStyle = .rounded
    @Published var fontSize: FontSizeOption = .medium
    @Published var showAnimations: Bool = true
    @Published var compactMode: Bool = false
    @Published var showHealthKitBanner: Bool = true
    @Published var dashboardShowBenefits: Bool = true
    @Published var dashboardShowQuickActions: Bool = true
    @Published var dashboardShowInsuranceCards: Bool = true
    @Published var hapticFeedback: Bool = true
    @Published var idCardShowPhoto: Bool = true
    @Published var idCardShowQRCode: Bool = false
    @Published var notificationReminders: Bool = false
    @Published var autoLockOnBackground: Bool = true
}

// MARK: - Onboarding State
enum OnboardingState: String, Codable {
    case notStarted
    case skipped
    case completed
}

// MARK: - Profile Completion Status
struct ProfileCompletionStatus: Codable {
    var personalInfo: Bool = false
    var healthInsurance: Bool = false
    var dentalInsurance: Bool = false
    var visionInsurance: Bool = false
    var medicalRecords: Bool = false
    var securitySetup: Bool = false

    var completionFraction: Double {
        let flags = [personalInfo, healthInsurance, dentalInsurance,
                     visionInsurance, medicalRecords, securitySetup]
        return Double(flags.filter { $0 }.count) / Double(flags.count)
    }
    var completionPercentage: Int { Int(completionFraction * 100) }
}

// MARK: - Emergency Contact
struct EmergencyContact: Identifiable, Codable {
    var id: UUID = UUID()
    var givenName: String = ""
    var fullName: String = ""
    var phoneNumber: String = ""
    var relationship: String = ""
}

// MARK: - Attached Document
struct AttachedDocument: Identifiable, Codable {
    var id: UUID = UUID()
    var fileName: String
    var fileType: String
    var dateAdded: Date = Date()
    var data: Data
    var sourceApp: String? = nil
}

// MARK: - Connected App
struct ConnectedApp: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var isConnected: Bool = false
    var lastSynced: Date? = nil
    var urlScheme: String? = nil
}

extension ConnectedApp {
    static var defaults: [ConnectedApp] {[
        ConnectedApp(name: "Epic MyChart",  icon: "cross.fill",
                     urlScheme: "epicmychart://"),
        ConnectedApp(name: "Apple Health",  icon: "heart.fill",
                     urlScheme: "x-apple-health://"),
        ConnectedApp(name: "CommonHealth",  icon: "waveform.path.ecg",
                     urlScheme: "commonhealth://"),
        ConnectedApp(name: "Teladoc",       icon: "video.fill",
                     urlScheme: "teladoc://"),
        ConnectedApp(name: "GoodRx",        icon: "pills.fill",
                     urlScheme: "goodrx://"),
        ConnectedApp(name: "Oscar Health",  icon: "staroflife.fill",
                     urlScheme: "oscar://"),
    ]}
}

// MARK: - Recording Interval
enum RecordingInterval: Int, CaseIterable, Codable {
    case off   = 0
    case one   = 1
    case two   = 2
    case three = 3
    case five  = 5
    case ten   = 10
    var label: String { rawValue == 0 ? "Off" : "\(rawValue) min" }
}

// MARK: - Video Quality
enum VideoQuality: String, CaseIterable, Codable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
    case uhd    = "4K"
}

// MARK: - Aspect Ratio
enum AspectRatioOption: String, CaseIterable, Codable {
    case widescreen = "16:9"
    case square     = "1:1"
    case portrait   = "9:16"
    case standard   = "4:3"
}

// MARK: - Resuscitation Preference
enum ResuscitationPreference: String, CaseIterable, Codable {
    case fullCode = "Full Code"
    case dnr      = "DNR – Do Not Resuscitate"
    case dnar     = "DNAR – Do Not Attempt Resuscitation"
    case dni      = "DNI – Do Not Intubate"

    var color: Color {
        switch self {
        case .fullCode: return .green
        case .dnr:      return .red
        case .dnar:     return .orange
        case .dni:      return .purple
        }
    }
    var icon: String {
        switch self {
        case .fullCode: return "heart.fill"
        case .dnr:      return "heart.slash.fill"
        case .dnar:     return "exclamationmark.heart.fill"
        case .dni:      return "lungs.fill"
        }
    }
    var shortLabel: String {
        switch self {
        case .fullCode: return "Full Code"
        case .dnr:      return "DNR"
        case .dnar:     return "DNAR"
        case .dni:      return "DNI"
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date = Date()
    var phoneNumber: String = ""
    var profileImageData: Data? = nil
    var height: String = ""
    var weight: String = ""
    var bloodType: String = ""
    var resuscitationPreference: ResuscitationPreference = .fullCode
    var emergencyContacts: [EmergencyContact] = []
    var attachedDocuments: [AttachedDocument] = []
    var attachedPhotoIDs: [String] = []
    var connectedApps: [ConnectedApp] = ConnectedApp.defaults

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    var initials: String {
        let f = firstName.first.map { String($0).uppercased() } ?? ""
        let l = lastName.first.map  { String($0).uppercased() } ?? ""
        return f + l
    }
}

// MARK: - Insurance Category
enum InsuranceCategory: String, CaseIterable, Codable, Equatable {
    case health = "Health"
    case dental = "Dental"
    case vision = "Vision"
}

// MARK: - Plan Type
enum PlanType: String, CaseIterable, Codable {
    case ppo  = "PPO"
    case hmo  = "HMO"
    case epo  = "EPO"
    case hdhp = "HDHP"
    case dhmo = "DHMO"
    case dppo = "DPPO"
}

// MARK: - Coverage Status
enum CoverageStatus: String, Codable {
    case covered    = "Covered"
    case partial    = "Partial"
    case notCovered = "Not Covered"

    var color: Color {
        switch self {
        case .covered:    return .green
        case .partial:    return .orange
        case .notCovered: return .red
        }
    }
    var icon: String {
        switch self {
        case .covered:    return "checkmark.circle.fill"
        case .partial:    return "exclamationmark.circle.fill"
        case .notCovered: return "xmark.circle.fill"
        }
    }
}

// MARK: - Coverage Item
struct CoverageItem: Identifiable, Codable {
    var id: UUID = UUID()
    var category: String
    var serviceName: String
    var coverageStatus: CoverageStatus
    var costDetail: String
    var requiresReferral: Bool = false
    var requiresPreAuth: Bool = false
    var annualLimit: String? = nil
    var lifetimeMax: String? = nil
    var notes: String? = nil
}

// MARK: - Urgency Level
enum UrgencyLevel: Int, Codable, Comparable {
    case administrative = 0
    case standard       = 1
    case urgent         = 2
    case critical       = 3

    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    var color: Color {
        switch self {
        case .critical:       return .red
        case .urgent:         return .orange
        case .standard:       return .yellow
        case .administrative: return .blue
        }
    }
    var label: String {
        switch self {
        case .critical:       return "Critical"
        case .urgent:         return "Urgent"
        case .standard:       return "Standard"
        case .administrative: return "Administrative"
        }
    }
}

// MARK: - Contact Entry
struct ContactEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var departmentName: String
    var phoneNumber: String
    var extension_: String? = nil
    var ttyNumber: String? = nil
    var availabilityHours: String
    var averageWaitTime: String? = nil
    var callPurpose: String
    var urgencyLevel: UrgencyLevel
    var supportsCallback: Bool = false
    var supportsChat: Bool = false
    var portalURL: String? = nil
    var faxNumber: String? = nil
    var notes: String? = nil
}

// MARK: - Digital Contact Entry
struct DigitalContactEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var label: String
    var url: String? = nil
    var supportsDocUpload: Bool = false
    var supportsChatBot: Bool = false
    var supportsLiveAgent: Bool = false
}

// MARK: - Insurance Contact Directory
struct InsuranceContactDirectory: Codable {
    var urgentContacts: [ContactEntry] = []
    var claimsContacts: [ContactEntry] = []
    var coverageContacts: [ContactEntry] = []
    var billingContacts: [ContactEntry] = []
    var providerNetworkContacts: [ContactEntry] = []
    var pharmacyContacts: [ContactEntry] = []
    var appealContacts: [ContactEntry] = []
    var digitalContacts: [DigitalContactEntry] = []
    var stateCommissionerPhone: String = ""

    var allContacts: [ContactEntry] {
        (urgentContacts + claimsContacts + coverageContacts +
         billingContacts + providerNetworkContacts +
         pharmacyContacts + appealContacts)
        .sorted { $0.urgencyLevel > $1.urgencyLevel }
    }
}

// MARK: - Insurance Plan
struct InsurancePlan: Identifiable, Codable {
    var id: UUID = UUID()
    var category: InsuranceCategory
    var providerName: String = ""
    var planName: String = ""
    var planType: PlanType = .ppo
    var memberID: String = ""
    var groupNumber: String = ""
    var effectiveDate: Date = Date()
    var expirationDate: Date = Calendar.current.date(
        byAdding: .year, value: 1, to: Date()) ?? Date()
    var coverageItems: [CoverageItem] = []
    var contacts: InsuranceContactDirectory = InsuranceContactDirectory()
    var deductibleTotal: Double = 0
    var deductibleMet: Double = 0
    var outOfPocketMax: Double = 0
    var outOfPocketMet: Double = 0
}

// MARK: - Medical Record
struct MedicalRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var age: String
    var bloodType: String
    var conditions: String
    var medications: String
    var allergies: String = ""
    var dateAdded: Date = Date()
}

// MARK: - Profile Section
enum ProfileSection {
    case personalInfo, healthInsurance, dentalInsurance
    case visionInsurance, medicalRecords, securitySetup
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var onboardingState: OnboardingState = .notStarted
    @Published var profile: UserProfile = UserProfile()
    @Published var completionStatus: ProfileCompletionStatus = ProfileCompletionStatus()
    @Published var healthPlan: InsurancePlan = InsurancePlan(category: .health)
    @Published var dentalPlan: InsurancePlan  = InsurancePlan(category: .dental)
    @Published var visionPlan: InsurancePlan  = InsurancePlan(category: .vision)
    @Published var records: [MedicalRecord] = []
    @Published var isBiometricEnabled: Bool = false
    @Published var isAppLocked: Bool = false
    @Published var usePasskey: Bool = false
    @Published var isRecordingEnabled: Bool = false
    @Published var recordingInterval: RecordingInterval = .off
    @Published var videoQuality: VideoQuality = .high
    @Published var aspectRatio: AspectRatioOption = .widescreen
    @Published var audioEnabled: Bool = true
    @Published var locationEnabled: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var healthKitEnabled: Bool = false
    @Published var activeInsuranceTab: InsuranceCategory = .health

    let healthStore = HKHealthStore()

    func plan(for category: InsuranceCategory) -> InsurancePlan {
        switch category {
        case .health: return healthPlan
        case .dental: return dentalPlan
        case .vision: return visionPlan
        }
    }

    func authenticateWithBiometrics(
        reason: String = "Unlock TapMed",
        completion: @escaping (Bool) -> Void
    ) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &error
        ) else { completion(false); return }
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, _ in
            DispatchQueue.main.async {
                if success { self.isAppLocked = false }
                completion(success)
            }
        }
    }

    func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .bloodType)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) {
            success, _ in
            DispatchQueue.main.async {
                self.healthKitEnabled = success
                if success { self.syncFromHealthKit() }
            }
        }
    }

    func syncFromHealthKit() {
        if let bt = try? healthStore.bloodType() {
            let map: [HKBloodType: String] = [
                .aPositive:"A+",.aNegative:"A-",
                .bPositive:"B+",.bNegative:"B-",
                .abPositive:"AB+",.abNegative:"AB-",
                .oPositive:"O+",.oNegative:"O-"
            ]
            profile.bloodType = map[bt.bloodType] ?? profile.bloodType
        }
        if let dob = try? healthStore.dateOfBirthComponents().date {
            profile.dateOfBirth = dob
        }
        let heightType = HKQuantityType.quantityType(forIdentifier: .height)!
        let hq = HKSampleQuery(
            sampleType: heightType, predicate: nil, limit: 1,
            sortDescriptors: [NSSortDescriptor(
                key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { [weak self] _, s, _ in
            if let s = s?.first as? HKQuantitySample {
                let cm = s.quantity.doubleValue(
                    for: HKUnit.meterUnit(with: .centi))
                DispatchQueue.main.async {
                    self?.profile.height = String(format: "%.0f cm", cm)
                }
            }
        }
        healthStore.execute(hq)
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let wq = HKSampleQuery(
            sampleType: weightType, predicate: nil, limit: 1,
            sortDescriptors: [NSSortDescriptor(
                key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { [weak self] _, s, _ in
            if let s = s?.first as? HKQuantitySample {
                let lbs = s.quantity.doubleValue(for: HKUnit.pound())
                DispatchQueue.main.async {
                    self?.profile.weight = String(format: "%.0f lbs", lbs)
                }
            }
        }
        healthStore.execute(wq)
    }

    func markComplete(_ section: ProfileSection) {
        switch section {
        case .personalInfo:    completionStatus.personalInfo    = true
        case .healthInsurance: completionStatus.healthInsurance = true
        case .dentalInsurance: completionStatus.dentalInsurance = true
        case .visionInsurance: completionStatus.visionInsurance = true
        case .medicalRecords:  completionStatus.medicalRecords  = true
        case .securitySetup:   completionStatus.securitySetup   = true
        }
    }
}

// MARK: - App Lock Gate
struct AppLockGate<Content: View>: View {
    @EnvironmentObject var appState: AppState
    @State private var isUnlocked: Bool = false
    @State private var authFailed: Bool = false
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        Group {
            if !appState.isBiometricEnabled || isUnlocked {
                content
            } else {
                LockScreenView(isUnlocked: $isUnlocked,
                               authFailed: $authFailed)
            }
        }
        .onAppear {
            if appState.isBiometricEnabled {
                appState.authenticateWithBiometrics { success in
                    isUnlocked = success
                    authFailed = !success
                }
            }
        }
    }
}

// MARK: - Lock Screen
struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isUnlocked: Bool
    @Binding var authFailed: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.9), .indigo],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 72)).foregroundColor(.white)
                VStack(spacing: 8) {
                    Text("TapMed")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Your health, secured.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                }
                if authFailed {
                    Text("Authentication failed. Try again.")
                        .font(.caption).foregroundColor(.red.opacity(0.9))
                        .padding(10).background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                Spacer()
                Button {
                    appState.authenticateWithBiometrics { success in
                        isUnlocked = success
                        authFailed = !success
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "faceid").font(.title2)
                        Text("Unlock with Face ID / Touch ID")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding(16)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white).cornerRadius(16)
                    .padding(.horizontal, 32)
                }
                Text("Protected with Apple ID & Biometrics")
                    .font(.caption2).foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var appState   = AppState()
    @StateObject private var appSettings = AppSettings()
    @State private var selectedTab: Int = 0

    var body: some View {
        AppLockGate {
            MainTabView(selectedTab: $selectedTab)
                .environmentObject(appState)
                .environmentObject(appSettings)
        }
        .environmentObject(appState)
        .environmentObject(appSettings)
        .preferredColorScheme(appSettings.theme.colorScheme)
        .accentColor(appSettings.accentColor.color)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @Binding var selectedTab: Int
    @State private var showSettings: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab,
                          showSettings: $showSettings)
                .environmentObject(appState)
                .environmentObject(appSettings)
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            InsuranceMapTabView()
                .environmentObject(appState)
                .environmentObject(appSettings)
                .tabItem { Label("Coverage", systemImage: "map.fill") }
                .tag(1)

            MedicalRecordsTabView(showSettings: $showSettings)
                .environmentObject(appState)
                .environmentObject(appSettings)
                .tabItem { Label("Records", systemImage: "cross.case.fill") }
                .tag(2)

            DigitalIDView(showSettings: $showSettings)
                .environmentObject(appState)
                .environmentObject(appSettings)
                .tabItem { Label("ID Card", systemImage: "creditcard.fill") }
                .tag(3)

        
        }
        .accentColor(appSettings.accentColor.color)
        .sheet(isPresented: $showSettings) {
            AppSettingsSheet()
                .environmentObject(appState)
                .environmentObject(appSettings)
        }
    }
}

struct SectionHeader: View {
    var title: String
    var icon: String
    var color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(color)
        }
        .padding()
        .background(Color.white) // You can change the background color as needed
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// MARK: - Medical Records Tab View
struct MedicalRecordsTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @Binding var showSettings: Bool
    @State private var showingForm: Bool = false
    @State private var selectedRecord: MedicalRecord? = nil
    @State private var searchText: String = ""

    var filteredRecords: [MedicalRecord] {
        if searchText.isEmpty { return appState.records }
        return appState.records.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bloodType.localizedCaseInsensitiveContains(searchText) ||
            $0.conditions.localizedCaseInsensitiveContains(searchText) ||
            $0.medications.localizedCaseInsensitiveContains(searchText) ||
            $0.allergies.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [appSettings.accentColor.color.opacity(0.05),
                             Color(.systemBackground)],
                    startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Stats Row ─────────────────────────────
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Total Records",
                            value: "\(appState.records.count)",
                            icon: "person.3.fill",
                            color: appSettings.accentColor.color)
                        StatCard(
                            title: "Latest Entry",
                            value: appState.records.isEmpty
                                ? "None"
                                : shortDate(appState.records.last!.dateAdded),
                            icon: "calendar",
                            color: .green)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // ── Search Bar ────────────────────────────
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search name, blood type, condition...",
                                  text: $searchText)
                        .autocapitalization(.none)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // ── Records List or Empty State ───────────
                    if filteredRecords.isEmpty {
                        Spacer()
                        RecordsEmptyStateView(
                            hasRecords: !appState.records.isEmpty,
                            onAdd: { showingForm = true })
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredRecords) { record in
                                RecordRowView(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedRecord = record }
                                    .listRowBackground(
                                        Color(.secondarySystemBackground)
                                            .cornerRadius(12))
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 6, leading: 16,
                                        bottom: 6, trailing: 16))
                            }
                            .onDelete(perform: deleteRecord)
                        }
                        .listStyle(.plain)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("🏥 Health Records")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SettingsToolbarButton(showSettings: $showSettings)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingForm = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(appSettings.accentColor.color)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !appState.records.isEmpty { EditButton() }
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            AddMedicalRecordSheet(records: $appState.records,
                                  isPresented: $showingForm)
            .environmentObject(appSettings)
        }
        .sheet(item: $selectedRecord) { record in
            RecordDetailView(record: record, records: $appState.records)
                .environmentObject(appSettings)
        }
    }

    func deleteRecord(at offsets: IndexSet) {
        appState.records.remove(atOffsets: offsets)
    }
    func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Records Empty State
struct RecordsEmptyStateView: View {
    var hasRecords: Bool
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasRecords
                  ? "magnifyingglass" : "cross.case.fill")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.4))
            Text(hasRecords ? "No matching records" : "No health records yet")
                .font(.title3).fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(hasRecords
                 ? "Try a different search term."
                 : "Tap + to add your first medical record.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            if !hasRecords {
                Button(action: onAdd) {
                    Label("Add Record", systemImage: "plus")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Record Row View
struct RecordRowView: View {
    var record: MedicalRecord

    var body: some View {
        HStack(spacing: 14) {
            // Blood type badge
            ZStack {
                Circle()
                    .fill(bloodTypeColor(record.bloodType).opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(record.bloodType.isEmpty ? "?" : record.bloodType)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(bloodTypeColor(record.bloodType))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name).font(.subheadline).fontWeight(.semibold)
                if !record.conditions.isEmpty {
                    Text(record.conditions)
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    if !record.age.isEmpty {
                        Label(record.age + " yrs", systemImage: "person.fill")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    if !record.allergies.isEmpty {
                        Label("Allergies", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2).foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(shortDate(record.dateAdded))
                    .font(.caption2).foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    func bloodTypeColor(_ type: String) -> Color {
        switch type {
        case "A+", "A-":  return .blue
        case "B+", "B-":  return .green
        case "AB+","AB-": return .purple
        case "O+", "O-":  return .red
        default:          return .gray
        }
    }
    func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Add Medical Record Sheet
struct AddMedicalRecordSheet: View {
    @EnvironmentObject var appSettings: AppSettings
    @Binding var records: [MedicalRecord]
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var bloodType: String = "Unknown"
    @State private var conditions: String = ""
    @State private var medications: String = ""
    @State private var allergies: String = ""
    let bloodTypes = ["A+","A-","B+","B-","AB+","AB-","O+","O-","Unknown"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Full Name", text: $name)
                    TextField("Age", text: $age).keyboardType(.numberPad)
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(bloodTypes, id: \.self) { Text($0).tag($0) }
                    }
                } header: { Text("Patient Info") }

                Section {
                    TextField("Conditions (e.g. Hypertension, Asthma)",
                              text: $conditions)
                    TextField("Medications (e.g. Lisinopril 10mg)",
                              text: $medications)
                    TextField("Allergies (e.g. Penicillin, Peanuts)",
                              text: $allergies)
                } header: { Text("Medical History") }
            }
            .navigationTitle("New Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !name.isEmpty else { return }
                        records.append(MedicalRecord(
                            name: name, age: age, bloodType: bloodType,
                            conditions: conditions, medications: medications,
                            allergies: allergies))
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(appSettings.accentColor.color)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Record Detail View
struct RecordDetailView: View {
    var record: MedicalRecord
    @Binding var records: [MedicalRecord]
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Hero Badge ────────────────────────────
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [bloodTypeColor(record.bloodType).opacity(0.2),
                                         bloodTypeColor(record.bloodType).opacity(0.05)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                        VStack(spacing: 2) {
                            Text(record.bloodType.isEmpty ? "?" : record.bloodType)
                                .font(.title).fontWeight(.bold)
                                .foregroundColor(bloodTypeColor(record.bloodType))
                            Text("Blood Type").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    // ── Info Cards ────────────────────────────
                    VStack(spacing: 12) {
                        RecordDetailRow(icon: "person.fill", label: "Full Name",
                                        value: record.name, color: .blue)
                        RecordDetailRow(icon: "calendar", label: "Age",
                                        value: record.age.isEmpty ? "Not specified" : "\(record.age) years",
                                        color: .green)
                        RecordDetailRow(icon: "clock.fill", label: "Date Added",
                                        value: formattedDate(record.dateAdded), color: .orange)
                    }
                    .padding(.horizontal)

                    if !record.conditions.isEmpty {
                        RecordDetailSection(
                            title: "Conditions",
                            icon: "stethoscope",
                            color: .purple,
                            content: record.conditions)
                        .padding(.horizontal)
                    }

                    if !record.medications.isEmpty {
                        RecordDetailSection(
                            title: "Medications",
                            icon: "pills.fill",
                            color: .blue,
                            content: record.medications)
                        .padding(.horizontal)
                    }

                    if !record.allergies.isEmpty {
                        RecordDetailSection(
                            title: "Allergies",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            content: record.allergies)
                        .padding(.horizontal)
                    }

                    // ── Delete Button ─────────────────────────
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Record")
                        }
                        .frame(maxWidth: .infinity).padding(14)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 30)
                }
            }
            .navigationTitle(record.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(appSettings.accentColor.color)
                }
            }
            .confirmationDialog("Delete this record?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    records.removeAll { $0.id == record.id }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    func bloodTypeColor(_ type: String) -> Color {
        switch type {
        case "A+","A-":  return .blue
        case "B+","B-":  return .green
        case "AB+","AB-": return .purple
        case "O+","O-":  return .red
        default:         return .gray
        }
    }
    func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Record Detail Row
struct RecordDetailRow: View {
    var icon: String
    var label: String
    var value: String
    var color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline).fontWeight(.medium)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Record Detail Section
struct RecordDetailSection: View {
    var title: String
    var icon: String
    var color: Color
    var content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color).font(.subheadline)
                Text(title).font(.subheadline).fontWeight(.semibold)
            }
            Text(content)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.subheadline)
                Spacer()
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value).font(.title3).fontWeight(.bold)
                    Text(title).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - File a Claim Sheet
struct FileAClaimSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: InsuranceCategory = .health
    @State private var claimDescription: String = ""
    @State private var claimDate: Date = Date()
    @State private var providerName: String = ""
    @State private var claimAmount: String = ""
    @State private var submitted: Bool = false

    var body: some View {
        NavigationView {
            if submitted {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 72)).foregroundColor(.green)
                    Text("Claim Submitted").font(.title2).fontWeight(.bold)
                    Text("Your \(selectedCategory.rawValue) claim has been recorded.")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                    Button("Done") { dismiss() }
                        .frame(maxWidth: .infinity).padding(14)
                        .background(Color.green).foregroundColor(.white)
                        .cornerRadius(14).padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                Form {
                    Section("Insurance Type") {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(InsuranceCategory.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Claim Details") {
                        DatePicker("Date of Service", selection: $claimDate,
                                   displayedComponents: .date)
                        TextField("Provider / Facility Name", text: $providerName)
                        TextField("Amount (e.g. $250.00)", text: $claimAmount)
                            .keyboardType(.decimalPad)
                    }
                    Section("Description") {
                        TextEditor(text: $claimDescription).frame(minHeight: 80)
                    }
                    Section {
                        Button {
                            submitted = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Submit Claim").fontWeight(.semibold).foregroundColor(.white)
                                Spacer()
                            }
                            .padding(12).background(Color.purple).cornerRadius(12)
                        }
                        .disabled(providerName.isEmpty)
                    }
                }
                .navigationTitle("File a Claim")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }
}

// MARK: - Digital ID View
struct DigitalIDView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @Binding var showSettings: Bool
    @State private var showEditSheet: Bool = false
    @State private var showDocPicker: Bool = false
    @State private var showConnectedApps: Bool = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isIDLocked: Bool = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Medical ID Card ───────────────────────
                    MedicalIDCardView(
                        profile: appState.profile,
                        appSettings: appSettings,
                        isLocked: $isIDLocked)
                    .padding(.horizontal)

                    // ── Insurance ID Cards ────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Insurance Cards",
                                      icon: "shield.fill",
                                      color: appSettings.accentColor.color)
                        .padding(.horizontal)
                        ForEach(InsuranceCategory.allCases, id: \.self) { cat in
                            InsuranceIDCard(
                                plan: appState.plan(for: cat),
                                profile: appState.profile,
                                category: cat,
                                appSettings: appSettings)
                            .padding(.horizontal)
                        }
                    }

                    // ── Attached Documents ────────────────────
                    AttachedDocumentsSection(
                        documents: $appState.profile.attachedDocuments,
                        showDocPicker: $showDocPicker,
                        appSettings: appSettings)
                    .padding(.horizontal)

                    // ── Attached Photos ───────────────────────
                    AttachedPhotosSection(
                        photoIDs: $appState.profile.attachedPhotoIDs,
                        selectedPhotos: $selectedPhotos,
                        appSettings: appSettings)
                    .padding(.horizontal)

                    // ── Connected Apps ────────────────────────
                    ConnectedAppsSection(
                        apps: $appState.profile.connectedApps,
                        showAll: $showConnectedApps,
                        appSettings: appSettings)
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
            .background(
                LinearGradient(
                    colors: [appSettings.accentColor.color.opacity(0.05),
                             Color(.systemBackground)],
                    startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea())
            .navigationTitle("🪪 Digital ID")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SettingsToolbarButton(showSettings: $showSettings)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        if isIDLocked {
                            appState.authenticateWithBiometrics(
                                reason: "View your Medical ID"
                            ) { success in if success { isIDLocked = false } }
                        } else {
                            isIDLocked = true
                        }
                    } label: {
                        Image(systemName: isIDLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(isIDLocked ? .red : .green)
                    }
                    Button { showEditSheet = true } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(appSettings.accentColor.color)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditProfileSheet().environmentObject(appState)
        }
        .fileImporter(
            isPresented: $showDocPicker,
            allowedContentTypes: [.pdf, .image, .data, .text],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url) {
                    appState.profile.attachedDocuments.append(
                        AttachedDocument(
                            fileName: url.lastPathComponent,
                            fileType: url.pathExtension.lowercased(),
                            data: data))
                }
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            for item in newItems {
                if let id = item.itemIdentifier,
                   !appState.profile.attachedPhotoIDs.contains(id) {
                    appState.profile.attachedPhotoIDs.append(id)
                }
            }
        }
    }
}

// MARK: - Medical ID Card View
struct MedicalIDCardView: View {
    var profile: UserProfile
    var appSettings: AppSettings
    @Binding var isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.1, blue: 0.1),
                             Color(red: 1.0, green: 0.4, blue: 0.1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                HStack(spacing: 12) {
                    Image(systemName: "staroflife.fill")
                        .font(.title2).foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Medical ID")
                            .font(.title3).fontWeight(.bold).foregroundColor(.white)
                        Text("TapMed Emergency Card")
                            .font(.caption2).foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.caption2)
                        Text(isLocked ? "Locked" : "Unlocked")
                            .font(.caption2).fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white).cornerRadius(8)
                }
                .padding(16)
            }
            .frame(height: 72)

            if isLocked {
                // Locked state
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Medical ID is locked")
                        .font(.headline).foregroundColor(.secondary)
                    Text("Tap the lock icon to authenticate and view your Medical ID.")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity).padding(32)
                .background(Color(.systemBackground))
            } else {
                VStack(spacing: 0) {
                    // Name + photo row
                    HStack(spacing: 16) {
                        ZStack {
                            if appSettings.idCardShowPhoto,
                               let data = profile.profileImageData,
                               let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.red.opacity(0.2), .orange.opacity(0.2)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 64, height: 64)
                                Text(profile.initials.isEmpty ? "?" : profile.initials)
                                    .font(.title2).fontWeight(.bold).foregroundColor(.red)
                            }
                        }
                        .overlay(Circle().stroke(Color.red.opacity(0.3), lineWidth: 2))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.fullName.isEmpty ? "Name Not Set" : profile.fullName)
                                .font(.title3).fontWeight(.bold)
                            Label(formattedDOB(profile.dateOfBirth), systemImage: "calendar")
                                .font(.caption).foregroundColor(.secondary)
                            if !profile.phoneNumber.isEmpty {
                                Label(profile.phoneNumber, systemImage: "phone.fill")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)

                    Divider().padding(.horizontal, 16)

                    // Stats row
                    HStack(spacing: 0) {
                        MedIDStatBlock(icon: "ruler", label: "Height",
                                       value: profile.height.isEmpty ? "—" : profile.height,
                                       color: .blue)
                        Divider().frame(height: 50)
                        MedIDStatBlock(icon: "scalemass.fill", label: "Weight",
                                       value: profile.weight.isEmpty ? "—" : profile.weight,
                                       color: .green)
                        Divider().frame(height: 50)
                        MedIDStatBlock(icon: "drop.fill", label: "Blood Type",
                                       value: profile.bloodType.isEmpty ? "—" : profile.bloodType,
                                       color: .red)
                    }
                    .padding(.vertical, 12)

                    Divider().padding(.horizontal, 16)

                    // Resuscitation preference
                    HStack(spacing: 12) {
                        Image(systemName: profile.resuscitationPreference.icon)
                            .foregroundColor(profile.resuscitationPreference.color)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Resuscitation Preference")
                                .font(.caption2).foregroundColor(.secondary)
                            Text(profile.resuscitationPreference.shortLabel)
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundColor(profile.resuscitationPreference.color)
                        }
                        Spacer()
                        // QR code placeholder
                        if appSettings.idCardShowQRCode {
                            Image(systemName: "qrcode")
                                .font(.system(size: 36))
                                .foregroundColor(.primary.opacity(0.6))
                        }
                    }
                    .padding(16)

                    // Emergency contacts strip
                    if !profile.emergencyContacts.isEmpty {
                        Divider().padding(.horizontal, 16)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Emergency Contacts")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            ForEach(profile.emergencyContacts.prefix(2)) { contact in
                                HStack(spacing: 10) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundColor(.red).font(.subheadline)
                                    Text(contact.givenName.isEmpty
                                         ? contact.fullName : contact.givenName)
                                        .font(.caption).fontWeight(.medium)
                                    if !contact.relationship.isEmpty {
                                        Text("· \(contact.relationship)")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if !contact.phoneNumber.isEmpty {
                                        Text(contact.phoneNumber)
                                            .font(.caption).foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(appSettings.cardStyle.cornerRadius)
        .shadow(color: .black.opacity(appSettings.cardStyle.shadowOpacity),
                radius: appSettings.cardStyle.shadowRadius, x: 0, y: 4)
    }

    func formattedDOB(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Med ID Stat Block
struct MedIDStatBlock: View {
    var icon: String
    var label: String
    var value: String
    var color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color).font(.subheadline)
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Insurance ID Card
struct InsuranceIDCard: View {
    var plan: InsurancePlan
    var profile: UserProfile
    var category: InsuranceCategory
    var appSettings: AppSettings

    var gradientColors: [Color] {
        switch category {
        case .health: return [Color(red: 0.1, green: 0.4, blue: 0.9),
                              Color(red: 0.2, green: 0.7, blue: 1.0)]
        case .dental: return [Color(red: 0.5, green: 0.1, blue: 0.8),
                              Color(red: 0.7, green: 0.3, blue: 1.0)]
        case .vision: return [Color(red: 0.0, green: 0.6, blue: 0.6),
                              Color(red: 0.1, green: 0.8, blue: 0.7)]
        }
    }
    var icon: String {
        switch category {
        case .health: return "heart.fill"
        case .dental: return "mouth.fill"
        case .vision: return "eye.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Card header
            ZStack {
                LinearGradient(colors: gradientColors,
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: icon).foregroundColor(.white).font(.subheadline)
                            Text("\(category.rawValue) Insurance")
                                .font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                        }
                        Text(plan.providerName.isEmpty ? "Provider Not Set" : plan.providerName)
                            .font(.caption).foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    Text(plan.planType.rawValue)
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white).cornerRadius(6)
                }
                .padding(14)
            }
            .frame(height: 64)

            // Card body
            if plan.memberID.isEmpty && plan.groupNumber.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.secondary)
                    Text("No insurance details added yet.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        InsuranceIDField(label: "Member ID",
                                         value: plan.memberID.isEmpty ? "—" : plan.memberID)
                        Divider().frame(height: 44)
                        InsuranceIDField(label: "Group #",
                                         value: plan.groupNumber.isEmpty ? "—" : plan.groupNumber)
                    }
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 16)

                    HStack(spacing: 0) {
                        InsuranceIDField(label: "Member Name",
                                         value: profile.fullName.isEmpty ? "—" : profile.fullName)
                        Divider().frame(height: 44)
                        InsuranceIDField(label: "Plan",
                                         value: plan.planName.isEmpty ? "—" : plan.planName)
                    }
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 16)

                    HStack(spacing: 0) {
                        InsuranceIDField(label: "Effective",
                                         value: shortDate(plan.effectiveDate))
                        Divider().frame(height: 44)
                        InsuranceIDField(label: "Expires",
                                         value: shortDate(plan.expirationDate))
                    }
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(appSettings.cardStyle.cornerRadius)
        .shadow(color: .black.opacity(appSettings.cardStyle.shadowOpacity),
                radius: appSettings.cardStyle.shadowRadius, x: 0, y: 3)
    }

    func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MM/dd/yy"
        return f.string(from: date)
    }
}

// MARK: - Insurance ID Field
struct InsuranceIDField: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.caption).fontWeight(.semibold).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
    }
}

// MARK: - Attached Documents Section
struct AttachedDocumentsSection: View {
    @Binding var documents: [AttachedDocument]
    @Binding var showDocPicker: Bool
    var appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Documents",
                              icon: "doc.fill",
                              color: appSettings.accentColor.color)
                Spacer()
                Button { showDocPicker = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(appSettings.accentColor.color)
                }
            }

            if documents.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .foregroundColor(.secondary).font(.title3)
                    Text("No documents attached. Tap + to add PDFs or files.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(documents) { doc in
                        HStack(spacing: 12) {
                            Image(systemName: docIcon(doc.fileType))
                                .foregroundColor(docColor(doc.fileType))
                                .font(.title3)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.fileName)
                                    .font(.caption).fontWeight(.medium).lineLimit(1)
                                Text(formattedDate(doc.dateAdded))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                documents.removeAll { $0.id == doc.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                    }
                }
            }
        }
    }

    func docIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "pdf":         return "doc.richtext.fill"
        case "png","jpg","jpeg","heic": return "photo.fill"
        case "txt":         return "doc.text.fill"
        default:            return "doc.fill"
        }
    }
    func docColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "pdf":         return .red
        case "png","jpg","jpeg","heic": return .blue
        case "txt":         return .gray
        default:            return .orange
        }
    }
    func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Attached Photos Section
struct AttachedPhotosSection: View {
    @Binding var photoIDs: [String]
    @Binding var selectedPhotos: [PhotosPickerItem]
    var appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Photos",
                              icon: "photo.fill",
                              color: appSettings.accentColor.color)
                Spacer()
                PhotosPicker(selection: $selectedPhotos,
                             maxSelectionCount: 10,
                             matching: .images) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(appSettings.accentColor.color)
                }
            }

            if photoIDs.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .foregroundColor(.secondary).font(.title3)
                    Text("No photos attached. Tap + to add images.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photoIDs, id: \.self) { id in
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.secondary)
                                    .font(.title2)
                                Button {
                                    photoIDs.removeAll { $0 == id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .padding(4)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Connected Apps Section
struct ConnectedAppsSection: View {
    @Binding var apps: [ConnectedApp]
    @Binding var showAll: Bool
    var appSettings: AppSettings

    var displayedApps: [ConnectedApp] {
        showAll ? apps : Array(apps.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Connected Apps",
                              icon: "app.connected.to.app.below.fill",
                              color: appSettings.accentColor.color)
                Spacer()
                Button { showAll.toggle() } label: {
                    Text(showAll ? "Show Less" : "See All")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(appSettings.accentColor.color)
                }
            }

            VStack(spacing: 8) {
                ForEach($apps) { $app in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(appSettings.accentColor.color.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: app.icon)
                                .foregroundColor(appSettings.accentColor.color)
                                .font(.system(size: 18))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name).font(.subheadline).fontWeight(.medium)
                            if app.isConnected, let synced = app.lastSynced {
                                Text("Synced \(shortDate(synced))")
                                    .font(.caption2).foregroundColor(.green)
                            } else {
                                Text("Not connected")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: $app.isConnected)
                            .labelsHidden()
                            .onChange(of: app.isConnected) { _, newValue in
                                if newValue { app.lastSynced = Date() }
                            }
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                }
            }
        }
    }

    func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dob: Date = Date()
    @State private var phone: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var bloodType: String = "Unknown"
    @State private var resuscPref: ResuscitationPreference = .fullCode
    @State private var selectedPhoto: PhotosPickerItem? = nil
    let bloodTypes = ["A+","A-","B+","B-","AB+","AB-","O+","O-","Unknown"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            ZStack {
                                if let data = appState.profile.profileImageData,
                                   let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Circle().fill(Color.blue.opacity(0.15))
                                        .frame(width: 80, height: 80)
                                    Text(appState.profile.initials.isEmpty
                                         ? "?" : appState.profile.initials)
                                        .font(.title).fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            PhotosPicker(selection: $selectedPhoto,
                                         matching: .images) {
                                Text("Change Photo")
                                    .font(.caption).foregroundColor(.blue)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: { Text("Profile Photo") }

                Section {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    DatePicker("Date of Birth", selection: $dob,
                               displayedComponents: .date)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                } header: { Text("Personal Info") }

                Section {
                    TextField("Height (e.g. 175 cm)", text: $height)
                    TextField("Weight (e.g. 160 lbs)", text: $weight)
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(bloodTypes, id: \.self) { Text($0).tag($0) }
                    }
                } header: { Text("Medical Info") }

                Section {
                    Picker("Resuscitation Preference", selection: $resuscPref) {
                        ForEach(ResuscitationPreference.allCases, id: \.self) { pref in
                            Label(pref.shortLabel, systemImage: pref.icon)
                                .tag(pref)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: { Text("Advance Directive") }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                firstName  = appState.profile.firstName
                lastName   = appState.profile.lastName
                dob        = appState.profile.dateOfBirth
                phone      = appState.profile.phoneNumber
                height     = appState.profile.height
                weight     = appState.profile.weight
                bloodType  = appState.profile.bloodType.isEmpty
                             ? "Unknown" : appState.profile.bloodType
                resuscPref = appState.profile.resuscitationPreference
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        appState.profile.firstName              = firstName
                        appState.profile.lastName               = lastName
                        appState.profile.dateOfBirth            = dob
                        appState.profile.phoneNumber            = phone
                        appState.profile.height                 = height
                        appState.profile.weight                 = weight
                        appState.profile.bloodType              = bloodType
                        appState.profile.resuscitationPreference = resuscPref
                        appState.markComplete(.personalInfo)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        appState.profile.profileImageData = data
                    }
                }
            }
        }
    }
}

// MARK: - Settings Button (reusable toolbar item)
struct SettingsToolbarButton: View {
    @Binding var showSettings: Bool

    var body: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.primary.opacity(0.7))
                .font(.system(size: 17, weight: .medium))
        }
    }
}

// MARK: - App Settings Sheet
struct AppSettingsSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {

                // ── APPEARANCE ──────────────────────────────────
                Section {
                    // Theme picker
                    VStack(alignment: .leading, spacing: 10) {
                        Label("App Theme", systemImage: "paintbrush.fill")
                            .font(.subheadline).fontWeight(.semibold)
                        HStack(spacing: 10) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button {
                                    appSettings.theme = theme
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: theme.icon)
                                            .font(.title2)
                                            .foregroundColor(
                                                appSettings.theme == theme
                                                ? appSettings.accentColor.color
                                                : .secondary)
                                        Text(theme.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(
                                                appSettings.theme == theme
                                                ? appSettings.accentColor.color
                                                : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        appSettings.theme == theme
                                        ? appSettings.accentColor.color.opacity(0.12)
                                        : Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                appSettings.theme == theme
                                                ? appSettings.accentColor.color
                                                : Color.clear,
                                                lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // Accent color
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Accent Color", systemImage: "circle.fill")
                            .font(.subheadline).fontWeight(.semibold)
                        LazyVGrid(columns: Array(
                            repeating: GridItem(.flexible()), count: 8
                        ), spacing: 10) {
                            ForEach(AccentColorOption.allCases, id: \.self) {
                                option in
                                Button {
                                    appSettings.accentColor = option
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(option.color)
                                            .frame(width: 32, height: 32)
                                        if appSettings.accentColor == option {
                                            Image(systemName: "checkmark")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // Card style
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Card Style", systemImage: "rectangle.stack.fill")
                            .font(.subheadline).fontWeight(.semibold)
                        HStack(spacing: 10) {
                            ForEach(CardStyle.allCases, id: \.self) { style in
                                Button {
                                    appSettings.cardStyle = style
                                } label: {
                                    Text(style.rawValue)
                                        .font(.caption)
                                        .fontWeight(
                                            appSettings.cardStyle == style
                                            ? .semibold : .regular)
                                        .foregroundColor(
                                            appSettings.cardStyle == style
                                            ? appSettings.accentColor.color
                                            : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            appSettings.cardStyle == style
                                            ? appSettings.accentColor.color.opacity(0.12)
                                            : Color(.secondarySystemBackground))
                                        .cornerRadius(style.cornerRadius / 2)
                                        .overlay(
                                            RoundedRectangle(
                                                cornerRadius: style.cornerRadius / 2)
                                            .stroke(
                                                appSettings.cardStyle == style
                                                ? appSettings.accentColor.color
                                                : Color.clear,
                                                lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // Font size
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Text Size", systemImage: "textformat.size")
                            .font(.subheadline).fontWeight(.semibold)
                        HStack(spacing: 10) {
                            ForEach(FontSizeOption.allCases, id: \.self) { size in
                                Button {
                                    appSettings.fontSize = size
                                } label: {
                                    Text(size.rawValue)
                                        .font(.system(size: 13 * size.scale))
                                        .fontWeight(
                                            appSettings.fontSize == size
                                            ? .semibold : .regular)
                                        .foregroundColor(
                                            appSettings.fontSize == size
                                            ? appSettings.accentColor.color
                                            : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            appSettings.fontSize == size
                                            ? appSettings.accentColor.color.opacity(0.12)
                                            : Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                appSettings.fontSize == size
                                                ? appSettings.accentColor.color
                                                : Color.clear,
                                                lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                } header: {
                    SettingsSectionHeader(title: "Appearance",
                                          icon: "paintpalette.fill",
                                          color: .purple)
                }

                // ── DISPLAY ─────────────────────────────────────
                Section {
                    SettingsToggleRow(
                        icon: "sparkles",
                        iconColor: .yellow,
                        title: "Animations",
                        subtitle: "Enable motion & transitions",
                        isOn: $appSettings.showAnimations)

                    SettingsToggleRow(
                        icon: "rectangle.compress.vertical",
                        iconColor: .blue,
                        title: "Compact Mode",
                        subtitle: "Reduce card padding & spacing",
                        isOn: $appSettings.compactMode)

                    SettingsToggleRow(
                        icon: "hand.tap.fill",
                        iconColor: .orange,
                        title: "Haptic Feedback",
                        subtitle: "Vibration on interactions",
                        isOn: $appSettings.hapticFeedback)

                } header: {
                    SettingsSectionHeader(title: "Display",
                                          icon: "display",
                                          color: .blue)
                }

                // ── DASHBOARD ───────────────────────────────────
                Section {
                    SettingsToggleRow(
                        icon: "shield.fill",
                        iconColor: .blue,
                        title: "Insurance Cards",
                        subtitle: "Show insurance overview on dashboard",
                        isOn: $appSettings.dashboardShowInsuranceCards)

                    SettingsToggleRow(
                        icon: "chart.bar.fill",
                        iconColor: .green,
                        title: "Benefit Tracker",
                        subtitle: "Show deductible progress bars",
                        isOn: $appSettings.dashboardShowBenefits)

                    SettingsToggleRow(
                        icon: "bolt.fill",
                        iconColor: .orange,
                        title: "Quick Actions",
                        subtitle: "Show shortcut buttons",
                        isOn: $appSettings.dashboardShowQuickActions)

                    SettingsToggleRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Apple Health Banner",
                        subtitle: "Show HealthKit sync prompt",
                        isOn: $appSettings.showHealthKitBanner)

                } header: {
                    SettingsSectionHeader(title: "Dashboard",
                                          icon: "house.fill",
                                          color: .orange)
                }

                // ── DIGITAL ID ──────────────────────────────────
                Section {
                    SettingsToggleRow(
                        icon: "person.crop.square.fill",
                        iconColor: .teal,
                        title: "Show Photo on ID Card",
                        subtitle: "Display profile photo on Medical ID",
                        isOn: $appSettings.idCardShowPhoto)

                    SettingsToggleRow(
                        icon: "qrcode",
                        iconColor: .indigo,
                        title: "Show QR Code",
                        subtitle: "Add scannable QR to Digital ID",
                        isOn: $appSettings.idCardShowQRCode)

                } header: {
                    SettingsSectionHeader(title: "Digital ID",
                                          icon: "creditcard.fill",
                                          color: .indigo)
                }

                // ── SECURITY ────────────────────────────────────
                Section {
                    SettingsToggleRow(
                        icon: "lock.fill",
                        iconColor: .green,
                        title: "Biometric Lock",
                        subtitle: "Face ID / Touch ID to open app",
                        isOn: $appState.isBiometricEnabled)

                    SettingsToggleRow(
                        icon: "moon.fill",
                        iconColor: .purple,
                        title: "Auto-Lock on Background",
                        subtitle: "Lock when app is backgrounded",
                        isOn: $appSettings.autoLockOnBackground)

                    SettingsToggleRow(
                        icon: "person.badge.key.fill",
                        iconColor: .blue,
                        title: "Passkey via Apple ID",
                        subtitle: "Passwordless authentication",
                        isOn: $appState.usePasskey)

                } header: {
                    SettingsSectionHeader(title: "Security",
                                          icon: "lock.shield.fill",
                                          color: .green)
                }

                // ── NOTIFICATIONS ───────────────────────────────
                Section {
                    SettingsToggleRow(
                        icon: "bell.fill",
                        iconColor: .red,
                        title: "Reminders",
                        subtitle: "Insurance renewal & benefit alerts",
                        isOn: $appSettings.notificationReminders)

                } header: {
                    SettingsSectionHeader(title: "Notifications",
                                          icon: "bell.badge.fill",
                                          color: .red)
                }

                // ── RECORDING ───────────────────────────────────
                Section {
                    SettingsToggleRow(
                        icon: "video.fill",
                        iconColor: .red,
                        title: "Loop Recording",
                        subtitle: "Camera & audio rolling buffer",
                        isOn: $appState.isRecordingEnabled)

                    if appState.isRecordingEnabled {
                        // Interval picker
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            Text("Loop Interval")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $appState.recordingInterval) {
                                ForEach(RecordingInterval.allCases, id: \.self) {
                                    Text($0.label).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(appSettings.accentColor.color)
                        }

                        // Quality picker
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text("Video Quality")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $appState.videoQuality) {
                                ForEach(VideoQuality.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(appSettings.accentColor.color)
                        }

                        // Aspect ratio picker
                        HStack {
                            Image(systemName: "aspectratio.fill")
                                .foregroundColor(.teal)
                                .frame(width: 28)
                            Text("Aspect Ratio")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $appState.aspectRatio) {
                                ForEach(AspectRatioOption.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(appSettings.accentColor.color)
                        }

                        // Audio toggle
                        SettingsToggleRow(
                            icon: "mic.fill",
                            iconColor: .purple,
                            title: "Record Audio",
                            subtitle: "Include microphone in loop",
                            isOn: $appState.audioEnabled)
                    }

                } header: {
                    SettingsSectionHeader(title: "Recording",
                                          icon: "video.circle.fill",
                                          color: .red)
                }

                // ── APPLE HEALTH ────────────────────────────────
                Section {
                    Button {
                        appState.requestHealthKitPermission()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.healthKitEnabled
                                     ? "Apple Health Connected"
                                     : "Connect Apple Health")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(appState.healthKitEnabled
                                     ? "Height, weight & blood type synced"
                                     : "Import health data automatically")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: appState.healthKitEnabled
                                  ? "checkmark.circle.fill" : "chevron.right")
                                .foregroundColor(appState.healthKitEnabled
                                                 ? .green : .secondary)
                        }
                    }

                } header: {
                    SettingsSectionHeader(title: "Apple Health",
                                          icon: "heart.fill",
                                          color: .red)
                }

                // ── ABOUT ───────────────────────────────────────
                Section {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(appSettings.accentColor.color)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TapMed")
                                .font(.subheadline).fontWeight(.semibold)
                            Text("Version 1.0.0")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    Button(role: .destructive) {
                        // Reset all settings to defaults
                        appSettings.theme = .system
                        appSettings.accentColor = .blue
                        appSettings.cardStyle = .rounded
                        appSettings.fontSize = .medium
                        appSettings.showAnimations = true
                        appSettings.compactMode = false
                        appSettings.hapticFeedback = true
                        appSettings.dashboardShowBenefits = true
                        appSettings.dashboardShowQuickActions = true
                        appSettings.dashboardShowInsuranceCards = true
                        appSettings.showHealthKitBanner = true
                        appSettings.idCardShowPhoto = true
                        appSettings.idCardShowQRCode = false
                        appSettings.notificationReminders = false
                        appSettings.autoLockOnBackground = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .frame(width: 28)
                            Text("Reset All Settings")
                        }
                    }

                } header: {
                    SettingsSectionHeader(title: "About",
                                          icon: "info.circle.fill",
                                          color: .gray)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(appSettings.accentColor.color)
                }
            }
        }
    }
}

// MARK: - Settings Section Header
struct SettingsSectionHeader: View {
    var title: String
    var icon: String
    var color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(nil)
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 15))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}



// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @Binding var selectedTab: Int
    @Binding var showSettings: Bool
    @State private var showProfileSetup: Bool = false
    @State private var showEmergencyContacts: Bool = false
    @State private var showFileClaim: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [appSettings.accentColor.color.opacity(0.05),
                             Color(.systemBackground)],
                    startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: appSettings.compactMode ? 12 : 20) {
                        if appState.completionStatus.completionFraction < 1.0
                            && appState.onboardingState == .skipped {
                            
                        }

                        if appSettings.dashboardShowInsuranceCards {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(
                                    title: "Insurance Overview",
                                    icon: "shield.fill",
                                    color: appSettings.accentColor.color)
                                .padding(.horizontal)
                                ScrollView(.horizontal,
                                           showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(InsuranceCategory.allCases,
                                                id: \.self) { cat in
                                            Button {
                                                appState.activeInsuranceTab = cat
                                                selectedTab = 1
                                            } label: {
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        if appSettings.dashboardShowBenefits {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(
                                    title: "Benefit Tracker",
                                    icon: "chart.bar.fill",
                                    color: .green)
                                .padding(.horizontal)
                            }
                        }

                        if appSettings.dashboardShowQuickActions {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(
                                    title: "Quick Actions",
                                    icon: "bolt.fill",
                                    color: .orange)
                                .padding(.horizontal)

                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 12
                                ) {
                                    QuickActionCard(
                                        title: "Emergency Contacts",
                                        icon: "phone.fill",
                                        color: .red,
                                        action: { showEmergencyContacts = true }
                                    )
                                    QuickActionCard(
                                        title: "Coverage Map",
                                        icon: "map.fill",
                                        color: appSettings.accentColor.color,
                                        action: { selectedTab = 1 }
                                    )
                                    QuickActionCard(
                                        title: "File a Claim",
                                        icon: "doc.fill",
                                        color: .purple,
                                        action: { showFileClaim = true }
                                    )
                                    QuickActionCard(
                                        title: "Digital ID",
                                        icon: "creditcard.fill",
                                        color: .green,
                                        action: { selectedTab = 3 }
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }


                        Spacer(minLength: 30)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("🏥 TapMed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsToolbarButton(showSettings: $showSettings)
                }
            }
        }
        .sheet(isPresented: $showProfileSetup) {
            EditProfileSheet().environmentObject(appState)
        }
        .sheet(isPresented: $showEmergencyContacts) {
            EmergencyContactsSheet().environmentObject(appState)
        }
        .sheet(isPresented: $showFileClaim) {
            FileAClaimSheet().environmentObject(appState)
        }
    }
}

// MARK: - Emergency Contacts Sheet
struct EmergencyContactsSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if !appState.profile.emergencyContacts.isEmpty {
                    Section("Personal Emergency Contacts") {
                        ForEach(appState.profile.emergencyContacts) { c in
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .foregroundColor(.red).font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(c.givenName.isEmpty
                                             ? c.fullName : c.givenName)
                                        .fontWeight(.semibold)
                                        if !c.relationship.isEmpty {
                                            Text("· \(c.relationship)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Text(c.phoneNumber)
                                        .font(.caption).foregroundColor(.blue)
                                }
                                Spacer()
                                if !c.phoneNumber.isEmpty {
                                    Link(destination: URL(string:
                                                            "tel:\(c.phoneNumber.filter { $0.isNumber })"
                                                         )!) {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



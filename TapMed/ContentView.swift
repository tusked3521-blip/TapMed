import SwiftUI
import CoreLocation
import Combine

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

    var completionPercentage: Int {
        Int(completionFraction * 100)
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var fullName: String = ""
    var dateOfBirth: Date = Date()
    var phoneNumber: String = ""
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""
    var profileImageData: Data? = nil

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0).uppercased() }.joined()
    }
}

// MARK: - Insurance Category
enum InsuranceCategory: String, CaseIterable, Codable, Equatable {
    case health  = "Health"
    case dental  = "Dental"
    case vision  = "Vision"
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

// MARK: - App State (ObservableObject)
class AppState: ObservableObject {
    @Published var onboardingState: OnboardingState = .notStarted
    @Published var profile: UserProfile = UserProfile()
    @Published var completionStatus: ProfileCompletionStatus = ProfileCompletionStatus()
    @Published var healthPlan: InsurancePlan = InsurancePlan(category: .health)
    @Published var dentalPlan: InsurancePlan = InsurancePlan(category: .dental)
    @Published var visionPlan: InsurancePlan = InsurancePlan(category: .vision)
    @Published var records: [MedicalRecord] = []
    @Published var isBiometricEnabled: Bool = false
    @Published var isRecordingEnabled: Bool = false
    @Published var recordingBufferMinutes: Int = 5
    @Published var locationEnabled: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var activeInsuranceTab: InsuranceCategory = .health

    // Convenience
    var plan: (InsuranceCategory) -> InsurancePlan {
        return { [weak self] cat in
            guard let self = self else {
                return InsurancePlan(category: cat)
            }
            switch cat {
            case .health: return self.healthPlan
            case .dental: return self.dentalPlan
            case .vision: return self.visionPlan
            }
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            if appState.onboardingState == .notStarted {
                MainTabView(selectedTab: $selectedTab)
                    .environmentObject(appState)
            } else {
                MainTabView(selectedTab: $selectedTab)
                    .environmentObject(appState)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.onboardingState)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {

            // Dashboard
            DashboardView()
                .environmentObject(appState)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            // Insurance Map
            InsuranceMapTabView()
                .environmentObject(appState)
                .tabItem {
                    Label("Coverage", systemImage: "map.fill")
                }
                .tag(1)

            // Medical Records
            MedicalRecordsTabView()
                .environmentObject(appState)
                .tabItem {
                    Label("Records", systemImage: "cross.case.fill")
                }
                .tag(2)

            // Digital ID
            DigitalIDView()
                .environmentObject(appState)
                .tabItem {
                    Label("ID Card", systemImage: "creditcard.fill")
                }
                .tag(3)

            // Profile
            ProfileTabView()
                .environmentObject(appState)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showProfileSetup: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBlue).opacity(0.05),
                             Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Profile Header Card
                        DashboardProfileCard(
                            profile: appState.profile,
                            completion: appState.completionStatus,
                            onSetupTap: { showProfileSetup = true }
                        )
                        .padding(.horizontal)

                        // Incomplete Profile Banner
                        if appState.completionStatus.completionFraction < 1.0
                            && appState.onboardingState == .skipped {
                            IncompleteProfileBanner {
                                showProfileSetup = true
                            }
                            .padding(.horizontal)
                        }

                        // Insurance Summary Cards
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Insurance Overview",
                                          icon: "shield.fill",
                                          color: .blue)
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(InsuranceCategory.allCases,
                                            id: \.self) { cat in
                                        InsuranceSummaryCard(
                                            plan: appState.plan(cat),
                                            category: cat
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Benefit Tracker
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Benefit Tracker",
                                          icon: "chart.bar.fill",
                                          color: .green)
                            .padding(.horizontal)

                            BenefitTrackerCard(
                                healthPlan: appState.healthPlan,
                                dentalPlan: appState.dentalPlan,
                                visionPlan: appState.visionPlan
                            )
                            .padding(.horizontal)
                        }

                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Quick Actions",
                                          icon: "bolt.fill",
                                          color: .orange)
                            .padding(.horizontal)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 12
                            ) {
                                QuickActionCard(
                                    title: "Emergency Contacts",
                                    icon: "phone.fill",
                                    color: .red
                                ) {}
                                QuickActionCard(
                                    title: "Coverage Map",
                                    icon: "map.fill",
                                    color: .blue
                                ) {}
                                QuickActionCard(
                                    title: "File a Claim",
                                    icon: "doc.fill",
                                    color: .purple
                                ) {}
                                QuickActionCard(
                                    title: "Digital ID",
                                    icon: "creditcard.fill",
                                    color: .green
                                ) {}
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("🏥 MediSafe")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showProfileSetup) {
        }
    }
}

// MARK: - Dashboard Profile Card
struct DashboardProfileCard: View {
    var profile: UserProfile
    var completion: ProfileCompletionStatus
    var onSetupTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ProfileRingView(
                completion: completion.completionFraction,
                initials: profile.initials.isEmpty ? "?" : profile.initials,
                profileImageData: profile.profileImageData,
                size: 64
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.fullName.isEmpty
                     ? "Set up your profile"
                     : profile.fullName)
                    .font(.headline)
                    .fontWeight(.bold)

                Text("\(completion.completionPercentage)% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if completion.completionFraction < 1.0 {
                    Button(action: onSetupTap) {
                        Text("Complete Profile →")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Profile Ring View
struct ProfileRingView: View {
    var completion: Double
    var initials: String
    var profileImageData: Data?
    var size: CGFloat = 64
    var isSecured: Bool = false

    private var strokeWidth: CGFloat { size * 0.07 }

    var body: some View {
        ZStack {
            // Ghost base ring (dashed)
            Circle()
                .stroke(
                    style: StrokeStyle(lineWidth: strokeWidth,
                                       dash: [5, 4])
                )
                .foregroundColor(.gray.opacity(0.25))

            // Background fill (appears after 50%)
            Circle()
                .fill(Color.blue.opacity(
                    completion > 0.5
                    ? (completion - 0.5) * 0.25
                    : 0
                ))
                .padding(strokeWidth / 2)

            // Filled arc
            Circle()
                .trim(from: 0, to: completion)
                .stroke(
                    AngularGradient(
                        colors: [.blue, .cyan, .purple,
                                 .teal, .orange, .green, .blue],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7),
                    value: completion
                )

            // Interior content
            Group {
                if let data = profileImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .padding(strokeWidth + 2)
                        .transition(.opacity)
                } else if completion > 0.15 {
                    Text(initials)
                        .font(.system(
                            size: size * 0.28,
                            weight: .bold
                        ))
                        .foregroundColor(.blue)
                        .transition(
                            .scale.combined(with: .opacity)
                        )
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.28))
                        .foregroundColor(.gray.opacity(0.35))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: completion)

            // Lock badge
            if isSecured {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.14))
                    .foregroundColor(.white)
                    .padding(size * 0.06)
                    .background(Color.green)
                    .clipShape(Circle())
                    .offset(
                        x: size * 0.3,
                        y: size * 0.3
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Incomplete Profile Banner
struct IncompleteProfileBanner: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .foregroundColor(.white)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Complete your profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("Unlock all features in 2 minutes")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
    }
}

// MARK: - Insurance Summary Card
struct InsuranceSummaryCard: View {
    var plan: InsurancePlan
    var category: InsuranceCategory

    var icon: String {
        switch category {
        case .health: return "heart.fill"
        case .dental: return "mouth.fill"
        case .vision: return "eye.fill"
        }
    }

    var color: Color {
        switch category {
        case .health: return .blue
        case .dental: return .purple
        case .vision: return .teal
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                Spacer()
                Text(category.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            if plan.providerName.isEmpty {
                Text("Not set up")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(plan.providerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(plan.planType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Image(systemName: "phone.fill")
                    .font(.caption2)
                    .foregroundColor(color)
                Text(plan.contacts.urgentContacts.first?.phoneNumber
                     ?? "No number")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Benefit Tracker Card
struct BenefitTrackerCard: View {
    var healthPlan: InsurancePlan
    var dentalPlan: InsurancePlan
    var visionPlan: InsurancePlan

    var body: some View {
        VStack(spacing: 14) {
            BenefitRow(
                label: "Health Deductible",
                current: healthPlan.deductibleMet,
                total: healthPlan.deductibleTotal,
                color: .blue
            )
            BenefitRow(
                label: "Dental Annual Max",
                current: dentalPlan.deductibleMet,
                total: dentalPlan.deductibleTotal == 0
                    ? 1500 : dentalPlan.deductibleTotal,
                color: .purple
            )
            BenefitRow(
                label: "Vision Allowance",
                current: visionPlan.deductibleMet,
                total: visionPlan.deductibleTotal == 0
                    ? 150 : visionPlan.deductibleTotal,
                color: .teal
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    var label: String
    var current: Double
    var total: Double
    var color: Color

    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(current / total, 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(Int(current)) / $\(Int(total))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * fraction,
                            height: 8
                        )
                        .animation(.spring(), value: fraction)
                }
            }
            .frame(height: 8)
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
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    var title: String
    var icon: String
    var color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Medical Records Tab View
struct MedicalRecordsTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingForm: Bool = false
    @State private var selectedRecord: MedicalRecord? = nil
    @State private var searchText: String = ""

    var filteredRecords: [MedicalRecord] {
        if searchText.isEmpty { return appState.records }
        return appState.records.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bloodType.localizedCaseInsensitiveContains(searchText) ||
            $0.conditions.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBlue).opacity(0.05),
                             Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Total Records",
                            value: "\(appState.records.count)",
                            icon: "person.3.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Latest Entry",
                            value: appState.records.isEmpty
                                ? "None"
                                : shortDate(appState.records.last!.dateAdded),
                            icon: "calendar",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField(
                            "Search by name, blood type, condition...",
                            text: $searchText
                        )
                        .autocapitalization(.none)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 12)

                    if filteredRecords.isEmpty {
                        Spacer()
                        EmptyStateView(hasRecords: !appState.records.isEmpty)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredRecords) { record in
                                RecordRowView(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedRecord = record }
                                    .listRowBackground(
                                        Color(.secondarySystemBackground)
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 6, leading: 16,
                                        bottom: 6, trailing: 16
                                    ))
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingForm = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !appState.records.isEmpty { EditButton() }
                }
            }
            .sheet(isPresented: $showingForm) {
                ConnectionSettingsView(
                    records: $appState.records,
                    isPresented: $showingForm
                )
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(
                    record: record,
                    records: $appState.records
                )
            }
        }
    }

    func deleteRecord(at offsets: IndexSet) {
        appState.records.remove(atOffsets: offsets)
    }

    func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Digital ID View
struct DigitalIDView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(InsuranceCategory.allCases, id: \.self) { cat in
                        InsuranceIDCard(
                            plan: appState.plan(cat),
                            profile: appState.profile,
                            category: cat
                        )
                        .padding(.horizontal)
                    }
                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
            .navigationTitle("🪪 Digital ID")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [Color(.systemBlue).opacity(0.05),
                             Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Insurance ID Card
struct InsuranceIDCard: View {
    var plan: InsurancePlan
    var profile: UserProfile
    var category: InsuranceCategory

    var gradientColors: [Color] {
        switch category {
        case .health: return [.blue, .cyan]
        case .dental: return [.purple, .indigo]
        case .vision: return [.teal, .green]
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
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title3)
                Text("\(category.rawValue) Insurance")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                if !plan.providerName.isEmpty {
                    Text(plan.providerName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // Card Body
            VStack(spacing: 12) {
                if plan.providerName.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.dashed")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Add \(category.rawValue) Insurance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(24)
                } else {
                    VStack(spacing: 10) {
                        IDCardRow(label: "Member Name",
                                  value: profile.fullName.isEmpty
                                    ? "—" : profile.fullName)
                        IDCardRow(label: "Member ID",
                                  value: plan.memberID.isEmpty
                                    ? "—" : plan.memberID)
                        IDCardRow(label: "Group #",
                                  value: plan.groupNumber.isEmpty
                                    ? "—" : plan.groupNumber)
                        IDCardRow(label: "Plan",
                                  value: plan.planName.isEmpty
                                    ? plan.planType.rawValue : plan.planName)

                        Divider()

                        // Emergency contact line
                        if let urgent = plan.contacts.urgentContacts.first {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                Text("24/7: \(urgent.phoneNumber)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(.systemBackground))
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - ID Card Row
struct IDCardRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

// MARK: - Profile Tab View
struct ProfileTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPhotoPrompt: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var showCompletionCelebration: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Profile Ring — large version
                    VStack(spacing: 12) {
                        ZStack {
                            ProfileRingView(
                                completion: appState.completionStatus
                                    .completionFraction,
                                initials: appState.profile.initials.isEmpty
                                    ? "?" : appState.profile.initials,
                                profileImageData: appState.profile
                                    .profileImageData,
                                size: 120,
                                isSecured: appState.isBiometricEnabled
                            )

                            // Edit overlay (only if photo exists)
                            if appState.profile.profileImageData != nil {
                                Circle()
                                    .fill(Color.black.opacity(0.001))
                                    .frame(width: 120, height: 120)
                                    .onTapGesture {
                                        showImagePicker = true
                                    }
                            }
                        }

                        if appState.profile.fullName.isEmpty {
                            Text("Your Profile")
                                .font(.title2).fontWeight(.bold)
                        } else {
                            Text(appState.profile.fullName)
                                .font(.title2).fontWeight(.bold)
                        }

                        Text("\(appState.completionStatus.completionPercentage)% Complete")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Completion Checklist
                    ProfileCompletionChecklist()
                        .padding(.horizontal)

                    Spacer(minLength: 30)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showImagePicker) {
            // ImagePicker would go here
            Text("Image Picker Placeholder")
        }
    }
}

// MARK: - Profile Completion Checklist
struct ProfileCompletionChecklist: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile Checklist")
                .font(.headline)
                .fontWeight(.semibold)

            ChecklistRow(
                label: "Personal Information",
                isComplete: appState.completionStatus.personalInfo,
                icon: "person.fill",
                color: .blue
            )
            ChecklistRow(
                label: "Health Insurance",
                isComplete: appState.completionStatus.healthInsurance,
                icon: "heart.fill",
                color: .red
            )
            ChecklistRow(
                label: "Dental Insurance",
                isComplete: appState.completionStatus.dentalInsurance,
                icon: "mouth.fill",
                color: .purple
            )
            ChecklistRow(
                label: "Vision Insurance",
                isComplete: appState.completionStatus.visionInsurance,
                icon: "eye.fill",
                color: .teal
            )
            ChecklistRow(
                label: "Medical Records",
                isComplete: appState.completionStatus.medicalRecords,
                icon: "cross.case.fill",
                color: .orange
            )
            ChecklistRow(
                label: "Security Setup",
                isComplete: appState.completionStatus.securitySetup,
                icon: "lock.fill",
                color: .green
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Checklist Row
struct ChecklistRow: View {
    var label: String
    var isComplete: Bool
    var icon: String
    var color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isComplete ? color : .gray.opacity(0.4))
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(isComplete ? .primary : .secondary)
            Spacer()
            Image(
                systemName: isComplete
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundColor(isComplete ? .green : .gray.opacity(0.4))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Stat Card (kept from original)
struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline).fontWeight(.bold)
                Text(title)
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Record Row View (kept from original)
struct RecordRowView: View {
    var record: MedicalRecord

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(bloodTypeColor(record.bloodType).opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(record.bloodType.isEmpty ? "?" : record.bloodType)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(bloodTypeColor(record.bloodType))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name.isEmpty ? "Unknown" : record.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label("\(record.age) yrs", systemImage: "person.fill")
                        .font(.caption).foregroundColor(.secondary)
                    if !record.conditions.isEmpty {
                        Text("•").foregroundColor(.secondary)
                        Text(record.conditions)
                            .font(.caption).foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    func bloodTypeColor(_ type: String) -> Color {
        switch type {
        case "A+", "A-":   return .blue
        case "B+", "B-":   return .green
        case "AB+", "AB-": return .purple
        case "O+", "O-":   return .red
        default:            return .gray
        }
    }
}

// MARK: - Empty State View (kept from original)
struct EmptyStateView: View {
    var hasRecords: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasRecords
                  ? "magnifyingglass" : "cross.case.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.4))
            Text(hasRecords
                 ? "No matching records"
                 : "No Health Records Yet")
                .font(.title3).fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(hasRecords
                 ? "Try a different search term."
                 : "Tap the + button to add your first medical record.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Record Detail View (kept from original)
struct RecordDetailView: View {
    var record: MedicalRecord
    @Binding var records: [MedicalRecord]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 90, height: 90)
                        Text(String(record.name.prefix(1)).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    Text(record.name)
                        .font(.title2).fontWeight(.bold)

                    VStack(spacing: 14) {
                        DetailRow(icon: "person.fill",
                                  label: "Age",
                                  value: "\(record.age) years old",
                                  color: .blue)
                        DetailRow(icon: "drop.fill",
                                  label: "Blood Type",
                                  value: record.bloodType.isEmpty
                                    ? "Not specified" : record.bloodType,
                                  color: .red)
                        DetailRow(icon: "heart.text.square.fill",
                                  label: "Conditions",
                                  value: record.conditions.isEmpty
                                    ? "None reported" : record.conditions,
                                  color: .orange)
                        DetailRow(icon: "pills.fill",
                                  label: "Medications",
                                  value: record.medications.isEmpty
                                    ? "None" : record.medications,
                                  color: .green)
                        if !record.allergies.isEmpty {
                            DetailRow(icon: "allergens",
                                      label: "Allergies",
                                      value: record.allergies,
                                      color: .red)
                        }
                        DetailRow(icon: "calendar",
                                  label: "Date Added",
                                  value: formattedDate(record.dateAdded),
                                  color: .purple)
                    }
                    .padding(.horizontal)
                    Spacer(minLength: 30)
                }
            }
            .navigationTitle("Patient Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        records.removeAll { $0.id == record.id }
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Detail Row (kept from original)
struct DetailRow: View {
    var icon: String
    var label: String
    var value: String
    var color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundColor(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline).fontWeight(.medium)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}


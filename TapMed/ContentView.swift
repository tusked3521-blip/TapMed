//
//  ContentView.swift
//  TapMed
//
//  Created by Adam on 3/28/26.
//

import SwiftUI
import SwiftData
import Combine
import HealthKit
import UserNotifications
import PhotosUI

// MARK: - Theme Model

struct AppTheme: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var primaryHex: String
    var secondaryHex: String
    var accentHex: String

    var primary: Color { Color(hex: primaryHex) }
    var secondary: Color { Color(hex: secondaryHex) }
    var accent: Color { Color(hex: accentHex) }

    static let presets: [AppTheme] = [
        AppTheme(name: "Ocean Blue",  primaryHex: "#1A73E8", secondaryHex: "#4DA3FF", accentHex: "#0D47A1"),
        AppTheme(name: "Emerald",     primaryHex: "#2E7D32", secondaryHex: "#66BB6A", accentHex: "#1B5E20"),
        AppTheme(name: "Crimson",     primaryHex: "#C62828", secondaryHex: "#EF5350", accentHex: "#7F0000"),
        AppTheme(name: "Violet",      primaryHex: "#6A1B9A", secondaryHex: "#AB47BC", accentHex: "#38006B"),
        AppTheme(name: "Sunset",      primaryHex: "#E65100", secondaryHex: "#FF8A65", accentHex: "#BF360C"),
        AppTheme(name: "Slate",       primaryHex: "#37474F", secondaryHex: "#78909C", accentHex: "#102027"),
        AppTheme(name: "Rose Gold",   primaryHex: "#AD1457", secondaryHex: "#F48FB1", accentHex: "#880E4F"),
        AppTheme(name: "Teal",        primaryHex: "#00695C", secondaryHex: "#4DB6AC", accentHex: "#004D40"),
    ]
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var current: AppTheme

    init() {
        if let data = UserDefaults.standard.data(forKey: "selectedTheme"),
           let saved = try? JSONDecoder().decode(AppTheme.self, from: data) {
            self.current = saved
        } else {
            self.current = AppTheme.presets[0]
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: "selectedTheme")
        }
    }
}

// MARK: - HealthKit Manager

class HealthKitManager: ObservableObject {
    let store = HKHealthStore()

    @Published var heartRate: Double = 0
    @Published var stepCount: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var isAuthorized: Bool = false

    let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.characteristicType(forIdentifier: .bloodType)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
    ]

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        store.requestAuthorization(toShare: [], read: readTypes) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success { self.fetchAllMetrics() }
            }
        }
    }

    func fetchAllMetrics() {
        fetchLatestQuantity(type: .heartRate, unit: HKUnit(from: "count/min")) { self.heartRate = $0 }
        fetchLatestQuantity(type: .stepCount, unit: .count())                  { self.stepCount = $0 }
        fetchLatestQuantity(type: .oxygenSaturation, unit: .percent())         { self.bloodOxygen = $0 * 100 }
    }

    private func fetchLatestQuantity(
        type identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        completion: @escaping (Double) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async { completion(sample.quantity.doubleValue(for: unit)) }
        }
        store.execute(query)
    }

    func fetchBloodType() -> String {
        guard let obj = try? store.bloodType() else { return "Unknown" }
        switch obj.bloodType {
        case .aPositive:  return "A+"
        case .aNegative:  return "A-"
        case .bPositive:  return "B+"
        case .bNegative:  return "B-"
        case .abPositive: return "AB+"
        case .abNegative: return "AB-"
        case .oPositive:  return "O+"
        case .oNegative:  return "O-"
        default:          return "Unknown"
        }
    }

    func fetchDateOfBirth() -> String {
        guard let dob = try? store.dateOfBirthComponents().date else { return "" }
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        return "\(age)"
    }
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { self.isAuthorized = granted }
        }
    }

    func sendFamilyUpdateNotification(memberName: String, updateType: String) {
        let content = UNMutableNotificationContent()
        content.title = "TapMed Family Update"
        content.body  = "\(memberName)'s \(updateType) has been updated."
        content.sound = .default
        content.badge = 1
        schedule(content)
    }

    func sendConnectionNotification(memberName: String) {
        let content = UNMutableNotificationContent()
        content.title = "TapMed — New Family Connection"
        content.body  = "\(memberName) has joined your family group."
        content.sound = .default
        schedule(content)
    }

    func scheduleMedicationReminder(memberName: String, medication: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder — \(memberName)"
        content.body  = "Time to take \(medication)."
        content.sound = .default
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(
            identifier: "med-\(memberName)-\(medication)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func schedule(_ content: UNMutableNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Family Connection Manager

class FamilyConnectionManager: ObservableObject {
    @Published var authCode: String = ""
    @Published var connectedCodes: [String] = []

    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: "connectedCodes") {
            connectedCodes = saved
        }
        generateAuthCode()
    }

    func generateAuthCode() {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        authCode = code
        UserDefaults.standard.set(code, forKey: "myAuthCode")
    }

    func connectWithCode(_ code: String, memberName: String, notificationManager: NotificationManager) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 6, !connectedCodes.contains(trimmed) else { return false }
        connectedCodes.append(trimmed)
        UserDefaults.standard.set(connectedCodes, forKey: "connectedCodes")
        notificationManager.sendConnectionNotification(memberName: memberName)
        return true
    }

    func disconnectCode(_ code: String) {
        connectedCodes.removeAll { $0 == code }
        UserDefaults.standard.set(connectedCodes, forKey: "connectedCodes")
    }
}

// MARK: - Profile Image Store

class ProfileImageStore: ObservableObject {
    static let shared = ProfileImageStore()

    func save(image: UIImage, for id: UUID) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL(for: id))
        objectWillChange.send()
    }

    func load(for id: UUID) -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL(for: id)) else { return nil }
        return UIImage(data: data)
    }

    func delete(for id: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
        objectWillChange.send()
    }

    private func fileURL(for id: UUID) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(id.uuidString).jpg")
    }
}

// MARK: - Member Avatar View

struct MemberAvatarView: View {
    let member: FamilyMember
    var size: CGFloat = 48
    @ObservedObject private var store = ProfileImageStore.shared

    var body: some View {
        Group {
            if let img = store.load(for: member.id) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(member.color.opacity(0.15))
                        .frame(width: size, height: size)
                    Text(member.ownerName.prefix(1).uppercased())
                        .font(.system(size: size * 0.38, weight: .bold))
                        .foregroundColor(member.color)
                }
            }
        }
    }
}

// MARK: - Photo Picker View

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        init(_ parent: PhotoPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

// MARK: - Family Member Model

@Model
class FamilyMember {
    var id: UUID
    var ownerName: String
    var relationship: String
    var colorHex: String
    var authCode: String
    var isConnected: Bool
    @Relationship(deleteRule: .cascade) var records: [MedicalRecord]

    init(ownerName: String, relationship: String, colorHex: String,
         authCode: String = "", isConnected: Bool = false) {
        self.id           = UUID()
        self.ownerName    = ownerName
        self.relationship = relationship
        self.colorHex     = colorHex
        self.authCode     = authCode
        self.isConnected  = isConnected
        self.records      = []
    }

    var color: Color { Color(hex: colorHex) }

    static let relationshipOptions = [
        "Self", "Spouse / Partner", "Child", "Parent",
        "Sibling", "Grandparent", "Grandchild", "Other"
    ]

    static let memberColors = [
        "#1A73E8", "#2E7D32", "#C62828", "#6A1B9A",
        "#E65100", "#00695C", "#AD1457", "#37474F"
    ]
}

// MARK: - Medical Record Model

@Model
class MedicalRecord {
    var id: UUID
    var name: String
    var age: String
    var bloodType: String
    var medicalConditions: String
    var medications: String
    var allergies: String
    var emergencyContact: String
    var emergencyPhone: String
    var dateAdded: Date
    var lastUpdated: Date
    var heartRate: Double
    var stepCount: Double
    var bloodOxygen: Double

    init(
        name: String, age: String, bloodType: String,
        medicalConditions: String, medications: String,
        allergies: String, emergencyContact: String,
        emergencyPhone: String, heartRate: Double = 0,
        stepCount: Double = 0, bloodOxygen: Double = 0
    ) {
        self.id                = UUID()
        self.name              = name
        self.age               = age
        self.bloodType         = bloodType
        self.medicalConditions = medicalConditions
        self.medications       = medications
        self.allergies         = allergies
        self.emergencyContact  = emergencyContact
        self.emergencyPhone    = emergencyPhone
        self.dateAdded         = Date()
        self.lastUpdated       = Date()
        self.heartRate         = heartRate
        self.stepCount         = stepCount
        self.bloodOxygen       = bloodOxygen
    }
}

// MARK: - ContentView (Tab Root)

struct ContentView: View {
    @StateObject private var themeManager        = ThemeManager()
    @StateObject private var healthKitManager    = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var connectionManager   = FamilyConnectionManager()

    var body: some View {
        TabView {
            FamilyDashboardView()
                .tabItem { Label("Family",   systemImage: "person.3.fill") }
            FamilyConnectionView()
                .tabItem { Label("Connect",  systemImage: "person.2.wave.2.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(themeManager.current.primary)
        .environmentObject(themeManager)
        .environmentObject(healthKitManager)
        .environmentObject(notificationManager)
        .environmentObject(connectionManager)
        .onChange(of: themeManager.current) { _, _ in themeManager.save() }
        .onAppear {
            healthKitManager.requestAuthorization()
            notificationManager.requestAuthorization()
        }
    }
}

// MARK: - Family Dashboard

struct FamilyDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Query private var members: [FamilyMember]
    @State private var showingAddMember = false
    @State private var searchText = ""

    var filteredMembers: [FamilyMember] {
        searchText.isEmpty ? members : members.filter {
            $0.ownerName.localizedCaseInsensitiveContains(searchText) ||
            $0.relationship.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    dashboardHeader
                    if healthKitManager.isAuthorized { healthSummaryBar }
                    memberScrollRow
                    recordSummaryList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMember = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(themeManager.current.primary)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView { member in modelContext.insert(member) }
            }
            .searchable(text: $searchText, prompt: "Search family members…")
        }
        .environmentObject(themeManager)
        .environmentObject(healthKitManager)
    }

    private var dashboardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 30)).foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("TapMed").font(.title.bold()).foregroundColor(.white)
                Text("Family Health Records").font(.subheadline).foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(members.count)").font(.title.bold()).foregroundColor(.white)
                Text("Members").font(.caption).foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [themeManager.current.primary, themeManager.current.secondary],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
    }

    private var healthSummaryBar: some View {
        HStack(spacing: 0) {
            healthTile(icon: "heart.fill",
                       value: healthKitManager.heartRate > 0 ? "\(Int(healthKitManager.heartRate))" : "—",
                       label: "BPM", color: .red)
            Divider().frame(height: 40)
            healthTile(icon: "figure.walk",
                       value: healthKitManager.stepCount > 0 ? "\(Int(healthKitManager.stepCount))" : "—",
                       label: "Steps", color: .green)
            Divider().frame(height: 40)
            healthTile(icon: "lungs.fill",
                       value: healthKitManager.bloodOxygen > 0 ? "\(Int(healthKitManager.bloodOxygen))%" : "—",
                       label: "SpO2", color: .blue)
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(.separator)), alignment: .bottom)
    }

    private func healthTile(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 14))
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 15, weight: .bold))
                Text(label).font(.caption2).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var memberScrollRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(members) { member in
                    NavigationLink(destination: MemberRecordsView(member: member)) {
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                MemberAvatarView(member: member, size: 56)
                                if member.isConnected {
                                    Circle().fill(Color.green)
                                        .frame(width: 12, height: 12)
                                        .offset(x: 2, y: -2)
                                }
                            }
                            Text(member.ownerName.components(separatedBy: " ").first ?? member.ownerName)
                                .font(.caption.bold()).foregroundColor(.primary).lineLimit(1)
                            Text(member.relationship)
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(width: 72)
                    }
                }
                Button(action: { showingAddMember = true }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .strokeBorder(themeManager.current.primary.opacity(0.4), lineWidth: 2)
                                .frame(width: 56, height: 56)
                            Image(systemName: "plus")
                                .font(.title2).foregroundColor(themeManager.current.primary)
                        }
                        Text("Add").font(.caption.bold()).foregroundColor(themeManager.current.primary)
                    }
                    .frame(width: 72)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .background(Color(.systemBackground))
    }

    private var recordSummaryList: some View {
        Group {
            if members.isEmpty {
                emptyFamilyState
            } else {
                List {
                    ForEach(filteredMembers) { member in
                        NavigationLink(destination: MemberRecordsView(member: member)) {
                            FamilyMemberRowView(member: member)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color(.systemBackground))
                    }
                    .onDelete(perform: deleteMembers)
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var emptyFamilyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.3")
                .font(.system(size: 64))
                .foregroundColor(themeManager.current.primary.opacity(0.4))
            Text("No Family Members Yet").font(.title2.bold())
            Text("Tap the + button to add your first family member.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button(action: { showingAddMember = true }) {
                Label("Add Family Member", systemImage: "person.badge.plus")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(themeManager.current.primary).cornerRadius(14)
            }
            Spacer()
        }
    }

    private func deleteMembers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let member = filteredMembers[index]
                ProfileImageStore.shared.delete(for: member.id)
                modelContext.delete(member)
            }
        }
    }
}

// MARK: - Family Member Row

struct FamilyMemberRowView: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                MemberAvatarView(member: member, size: 48)
                if member.isConnected {
                    Circle().fill(Color.green)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.ownerName).font(.headline)
                    if member.isConnected {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green).font(.caption)
                    }
                }
                HStack(spacing: 6) {
                    Label(member.relationship, systemImage: "person.fill")
                        .font(.caption).foregroundColor(.secondary)
                    Text("•").foregroundColor(.secondary)
                    Label(
                        "\(member.records.count) record\(member.records.count == 1 ? "" : "s")",
                        systemImage: "doc.text"
                    )
                    .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Member Records View

struct MemberRecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Bindable var member: FamilyMember
    @State private var showingAddRecord  = false
    @State private var showingEditMember = false
    @State private var searchText = ""

    var filteredRecords: [MedicalRecord] {
        searchText.isEmpty ? member.records : member.records.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.medicalConditions.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                memberProfileHeader
                if member.records.isEmpty {
                    emptyRecordsState
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            NavigationLink(destination: RecordDetailView(record: record, memberColor: member.color)) {
                                RecordRowView(record: record, accentColor: member.color)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color(.systemBackground))
                        }
                        .onDelete(perform: deleteRecords)
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle(member.ownerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button(action: { showingEditMember = true }) {
                        Image(systemName: "person.crop.circle.badge.pencil")
                            .foregroundColor(member.color)
                    }
                    Button(action: { showingAddRecord = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(member.color).font(.title2)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton().foregroundColor(member.color)
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView(accentColor: member.color, healthKitManager: healthKitManager) { newRecord in
                member.records.append(newRecord)
                modelContext.insert(newRecord)
                if member.isConnected {
                    notificationManager.sendFamilyUpdateNotification(
                        memberName: member.ownerName, updateType: "medical record"
                    )
                }
            }
        }
        .sheet(isPresented: $showingEditMember) {
            EditFamilyMemberView(member: member)
        }
        .searchable(text: $searchText, prompt: "Search records…")
    }

    private var memberProfileHeader: some View {
        HStack(spacing: 16) {
            MemberAvatarView(member: member, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.ownerName).font(.headline)
                    if member.isConnected {
                        Label("Connected", systemImage: "checkmark.seal.fill")
                            .font(.caption).foregroundColor(.green)
                    }
                }
                Text(member.relationship).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.records.count)").font(.title2.bold()).foregroundColor(member.color)
                Text("Records").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    private var emptyRecordsState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "cross.case")
                .font(.system(size: 64)).foregroundColor(member.color.opacity(0.4))
            Text("No Records Yet").font(.title2.bold())
            Text("Tap + to add a medical record for \(member.ownerName).")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button(action: { showingAddRecord = true }) {
                Label("Add Record", systemImage: "plus.circle.fill")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(member.color).cornerRadius(14)
            }
            Spacer()
        }
    }

    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let record = filteredRecords[index]
                member.records.removeAll { $0.id == record.id }
                modelContext.delete(record)
            }
        }
    }
}

// MARK: - Edit Family Member View

struct EditFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var member: FamilyMember

    @State private var selectedImage: UIImage?  = nil
    @State private var showingPhotoPicker       = false
    @State private var showRemovePhotoAlert     = false

    private let store = ProfileImageStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let img = selectedImage {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(width: 90, height: 90).clipShape(Circle())
                                    } else if let img = store.load(for: member.id) {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(width: 90, height: 90).clipShape(Circle())
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(member.color.opacity(0.2))
                                                .frame(width: 90, height: 90)
                                            Text(member.ownerName.prefix(1).uppercased())
                                                .font(.system(size: 36, weight: .bold))
                                                .foregroundColor(member.color)
                                        }
                                    }
                                }
                                Button(action: { showingPhotoPicker = true }) {
                                    ZStack {
                                        Circle().fill(member.color).frame(width: 28, height: 28)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12)).foregroundColor(.white)
                                    }
                                }
                                .offset(x: 4, y: 4)
                            }

                            HStack(spacing: 12) {
                                Button(action: { showingPhotoPicker = true }) {
                                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                                        .font(.caption.bold()).foregroundColor(member.color)
                                }
                                if store.load(for: member.id) != nil || selectedImage != nil {
                                    Button(action: { showRemovePhotoAlert = true }) {
                                        Label("Remove", systemImage: "trash")
                                            .font(.caption.bold()).foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear).padding(.vertical, 10)
                }

                Section(header: Text("Member Info")) {
                    TextField("Full Name", text: $member.ownerName)
                    Picker("Relationship", selection: $member.relationship) {
                        ForEach(FamilyMember.relationshipOptions, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section(header: Text("Member Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(FamilyMember.memberColors, id: \.self) { hex in
                            Button(action: { member.colorHex = hex }) {
                                ZStack {
                                    Circle().fill(Color(hex: hex)).frame(width: 44, height: 44)
                                    if member.colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white).font(.headline)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button(action: saveChanges) {
                        HStack {
                            Spacer()
                            Label("Save Changes", systemImage: "checkmark.circle.fill")
                                .font(.headline).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(member.color)
                }
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let img = newImage { store.save(image: img, for: member.id) }
            }
            .alert("Remove Photo", isPresented: $showRemovePhotoAlert) {
                Button("Remove", role: .destructive) {
                    store.delete(for: member.id)
                    selectedImage = nil
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove the profile photo?")
            }
        }
    }

    private func saveChanges() {
        if let img = selectedImage { store.save(image: img, for: member.id) }
        dismiss()
    }
}

// MARK: - Add Family Member View

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (FamilyMember) -> Void

    @State private var name               = ""
    @State private var relationship       = "Self"
    @State private var selectedColorHex   = FamilyMember.memberColors[0]
    @State private var selectedImage: UIImage? = nil
    @State private var showingPhotoPicker = false
    @State private var showValidationAlert = false

    private let store = ProfileImageStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let img = selectedImage {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(width: 90, height: 90).clipShape(Circle())
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: selectedColorHex).opacity(0.2))
                                                .frame(width: 90, height: 90)
                                            Text(name.prefix(1).uppercased().isEmpty ? "?" : name.prefix(1).uppercased())
                                                .font(.system(size: 36, weight: .bold))
                                                .foregroundColor(Color(hex: selectedColorHex))
                                        }
                                    }
                                }
                                Button(action: { showingPhotoPicker = true }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: selectedColorHex))
                                            .frame(width: 28, height: 28)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12)).foregroundColor(.white)
                                    }
                                }
                                .offset(x: 4, y: 4)
                            }
                            Button(action: { showingPhotoPicker = true }) {
                                Label("Choose Photo", systemImage: "photo.on.rectangle")
                                    .font(.caption.bold())
                                    .foregroundColor(Color(hex: selectedColorHex))
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear).padding(.vertical, 10)
                }

                Section(header: Text("Member Info")) {
                    TextField("Full Name *", text: $name)
                    Picker("Relationship", selection: $relationship) {
                        ForEach(FamilyMember.relationshipOptions, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section(header: Text("Member Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(FamilyMember.memberColors, id: \.self) { hex in
                            Button(action: { selectedColorHex = hex }) {
                                ZStack {
                                    Circle().fill(Color(hex: hex)).frame(width: 44, height: 44)
                                    if selectedColorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white).font(.headline)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button(action: saveMember) {
                        HStack {
                            Spacer()
                            Label("Add Member", systemImage: "person.badge.plus")
                                .font(.headline).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color(hex: selectedColorHex))
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(selectedImage: $selectedImage)
            }
            .alert("Missing Name", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a name for this family member.")
            }
        }
    }

    private func saveMember() {
        guard !name.isEmpty else { showValidationAlert = true; return }
        let member = FamilyMember(ownerName: name, relationship: relationship, colorHex: selectedColorHex)
        if let img = selectedImage { store.save(image: img, for: member.id) }
        onSave(member)
        dismiss()
    }
}

// MARK: - Record Row View

struct RecordRowView: View {
    let record: MedicalRecord
    var accentColor: Color = .blue

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(bloodTypeColor(record.bloodType).opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(record.bloodType.isEmpty ? "?" : record.bloodType)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(bloodTypeColor(record.bloodType))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name).font(.headline)
                HStack(spacing: 6) {
                    Label(record.age.isEmpty ? "Age N/A" : "Age \(record.age)", systemImage: "person")
                        .font(.caption).foregroundColor(.secondary)
                    if !record.medicalConditions.isEmpty {
                        Text("•").foregroundColor(.secondary)
                        Text(record.medicalConditions)
                            .font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                if record.heartRate > 0 {
                    HStack(spacing: 8) {
                        Label("\(Int(record.heartRate)) BPM", systemImage: "heart.fill")
                            .font(.caption2).foregroundColor(.red)
                        Label("\(Int(record.bloodOxygen))% SpO2", systemImage: "lungs.fill")
                            .font(.caption2).foregroundColor(.blue)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    func bloodTypeColor(_ type: String) -> Color {
        switch type.uppercased() {
        case "A+", "A-":   return .red
        case "B+", "B-":   return .orange
        case "AB+", "AB-": return .purple
        case "O+", "O-":   return .blue
        default:            return .gray
        }
    }
}

// MARK: - Record Detail View

struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    let record: MedicalRecord
    var memberColor: Color = .blue
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileCard
                if record.heartRate > 0 || record.stepCount > 0 || record.bloodOxygen > 0 {
                    healthMetricsSection
                }
                infoSection(title: "Basic Info", icon: "person.fill", color: memberColor, items: [
                    ("Name",       record.name,      "person"),
                    ("Age",        record.age,       "calendar"),
                    ("Blood Type", record.bloodType, "drop.fill")
                ])
                infoSection(title: "Medical Details", icon: "stethoscope", color: .red, items: [
                    ("Conditions",  record.medicalConditions, "heart.text.square"),
                    ("Medications", record.medications,       "pills.fill"),
                    ("Allergies",   record.allergies,         "exclamationmark.triangle.fill")
                ])
                infoSection(title: "Emergency Contact", icon: "phone.fill", color: .green, items: [
                    ("Contact Name", record.emergencyContact, "person.crop.circle"),
                    ("Phone",        record.emergencyPhone,   "phone")
                ])
                HStack {
                    Image(systemName: "clock").foregroundColor(.secondary)
                    Text("Updated \(record.lastUpdated.formatted(date: .long, time: .shortened))")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 16).padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEditSheet = true }.foregroundColor(memberColor)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecordView(record: record, accentColor: memberColor)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [memberColor, memberColor.opacity(0.6)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Text(record.name.prefix(1).uppercased())
                    .font(.system(size: 34, weight: .bold)).foregroundColor(.white)
            }
            Text(record.name).font(.title2.bold())
            HStack(spacing: 16) {
                statBadge(label: "Age",   value: record.age.isEmpty      ? "—" : record.age,       color: memberColor)
                statBadge(label: "Blood", value: record.bloodType.isEmpty ? "—" : record.bloodType, color: .red)
            }
        }
        .frame(maxWidth: .infinity).padding(20)
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill").foregroundColor(.pink)
                Text("Live Health Metrics").font(.headline)
                Spacer()
                Text("from Apple Health").font(.caption2).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().padding(.leading, 16)
            HStack(spacing: 0) {
                liveMetricTile(icon: "heart.fill",  value: "\(Int(record.heartRate))",     unit: "BPM",   color: .red)
                Divider().frame(height: 50)
                liveMetricTile(icon: "figure.walk", value: "\(Int(record.stepCount))",    unit: "Steps", color: .green)
                Divider().frame(height: 50)
                liveMetricTile(icon: "lungs.fill",  value: "\(Int(record.bloodOxygen))%", unit: "SpO2",  color: .blue)
            }
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func liveMetricTile(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color).font(.title3)
            Text(value).font(.title3.bold())
            Text(unit).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(width: 80).padding(.vertical, 10)
        .background(color.opacity(0.1)).cornerRadius(10)
    }

    private func infoSection(title: String, icon: String, color: Color, items: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.headline)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().padding(.leading, 16)
            ForEach(items, id: \.0) { label, value, iconName in
                HStack(spacing: 12) {
                    Image(systemName: iconName).foregroundColor(color.opacity(0.7)).frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label).font(.caption).foregroundColor(.secondary)
                        Text(value.isEmpty ? "Not provided" : value)
                            .font(.body).foregroundColor(value.isEmpty ? .secondary : .primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                if label != items.last?.0 { Divider().padding(.leading, 48) }
            }
        }
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Add Record View

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    var accentColor: Color = .blue
    var healthKitManager: HealthKitManager? = nil
    var onSave: (MedicalRecord) -> Void

    @State private var name               = ""
    @State private var age                = ""
    @State private var bloodType          = ""
    @State private var medicalConditions  = ""
    @State private var medications        = ""
    @State private var allergies          = ""
    @State private var emergencyContact   = ""
    @State private var emergencyPhone     = ""
    @State private var showValidationAlert = false
    @State private var importedFromHealth = false

    let bloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(accentColor.opacity(0.15)).frame(width: 70, height: 70)
                                Image(systemName: "cross.fill").font(.system(size: 28)).foregroundColor(accentColor)
                            }
                            Text("New Medical Record").font(.headline)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear).padding(.vertical, 8)
                }

                if let hk = healthKitManager, hk.isAuthorized {
                    Section(header: Label("Apple Health", systemImage: "heart.fill").foregroundColor(.red)) {
                        Button(action: { importFromHealthKit(hk) }) {
                            HStack {
                                Image(systemName: "heart.fill").foregroundColor(.red)
                                Text(importedFromHealth ? "Imported from Apple Health ✓" : "Import from Apple Health")
                                    .foregroundColor(importedFromHealth ? .green : accentColor)
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                }

                Section(header: Label("Basic Information", systemImage: "person.fill").foregroundColor(accentColor)) {
                    TextField("Full Name *", text: $name)
                    TextField("Age *", text: $age).keyboardType(.numberPad)
                    Picker("Blood Type *", selection: $bloodType) {
                        Text("Select…").tag("")
                        ForEach(bloodTypes, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section(header: Label("Medical Details", systemImage: "stethoscope").foregroundColor(.red)) {
                    TextField("Medical Conditions", text: $medicalConditions)
                    TextField("Current Medications", text: $medications)
                    TextField("Allergies", text: $allergies)
                }

                Section(header: Label("Emergency Contact", systemImage: "phone.fill").foregroundColor(.green)) {
                    TextField("Contact Name", text: $emergencyContact)
                    TextField("Phone Number", text: $emergencyPhone).keyboardType(.phonePad)
                }

                Section {
                    Button(action: saveRecord) {
                        HStack {
                            Spacer()
                            Label("Save Record", systemImage: "checkmark.circle.fill")
                                .font(.headline).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(accentColor)
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.red)
                }
            }
            .alert("Missing Required Fields", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please fill in Name, Age, and Blood Type before saving.")
            }
        }
    }

    private func importFromHealthKit(_ hk: HealthKitManager) {
        let bt = hk.fetchBloodType()
        if !bt.isEmpty && bt != "Unknown" { bloodType = bt }
        let a = hk.fetchDateOfBirth()
        if !a.isEmpty { age = a }
        hk.fetchAllMetrics()
        importedFromHealth = true
    }

    private func saveRecord() {
        guard !name.isEmpty, !age.isEmpty, !bloodType.isEmpty else {
            showValidationAlert = true; return
        }
        onSave(MedicalRecord(
            name: name, age: age, bloodType: bloodType,
            medicalConditions: medicalConditions, medications: medications,
            allergies: allergies, emergencyContact: emergencyContact,
            emergencyPhone: emergencyPhone,
            heartRate:   healthKitManager?.heartRate   ?? 0,
            stepCount:   healthKitManager?.stepCount   ?? 0,
            bloodOxygen: healthKitManager?.bloodOxygen ?? 0
        ))
        dismiss()
    }
}

// MARK: - Edit Record View

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @Bindable var record: MedicalRecord
    var accentColor: Color = .blue
    let bloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Label("Basic Information", systemImage: "person.fill").foregroundColor(accentColor)) {
                    TextField("Full Name", text: $record.name)
                    TextField("Age", text: $record.age).keyboardType(.numberPad)
                    Picker("Blood Type", selection: $record.bloodType) {
                        ForEach(bloodTypes, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section(header: Label("Medical Details", systemImage: "stethoscope").foregroundColor(.red)) {
                    TextField("Medical Conditions", text: $record.medicalConditions)
                    TextField("Current Medications", text: $record.medications)
                    TextField("Allergies", text: $record.allergies)
                }
                Section(header: Label("Emergency Contact", systemImage: "phone.fill").foregroundColor(.green)) {
                    TextField("Contact Name", text: $record.emergencyContact)
                    TextField("Phone Number", text: $record.emergencyPhone).keyboardType(.phonePad)
                }
                Section {
                    Button(action: saveChanges) {
                        HStack {
                            Spacer()
                            Label("Save Changes", systemImage: "checkmark.circle.fill")
                                .font(.headline).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(accentColor)
                }
            }
            .navigationTitle("Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.red)
                }
            }
        }
    }

    private func saveChanges() {
        record.lastUpdated = Date()
        notificationManager.sendFamilyUpdateNotification(memberName: record.name, updateType: "medical record")
        dismiss()
    }
}

// MARK: - Family Connection View

struct FamilyConnectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var connectionManager: FamilyConnectionManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var members: [FamilyMember]

    @State private var enteredCode        = ""
    @State private var selectedMemberID: UUID? = nil
    @State private var showSuccessAlert   = false
    @State private var showFailureAlert   = false
    @State private var showCopiedToast    = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        myCodeCard
                        connectCard
                        if !connectionManager.connectedCodes.isEmpty {
                            connectedMembersCard
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Family Connect")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Connected!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Family member successfully connected. They will receive health update notifications.")
            }
            .alert("Invalid Code", isPresented: $showFailureAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The code you entered is invalid or already connected. Please check and try again.")
            }
            .overlay(
                Group {
                    if showCopiedToast {
                        VStack {
                            Spacer()
                            Text("Code copied to clipboard!")
                                .font(.subheadline.bold())
                                .foregroundColor(.
                        }

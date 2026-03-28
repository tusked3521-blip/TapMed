import SwiftUI

// MARK: - Data Model
struct MedicalRecord: Identifiable {
    let id = UUID()
    var name: String
    var age: String
    var bloodType: String
    var conditions: String
    var medications: String
    var dateAdded: Date = Date()
}

// MARK: - Main Content View
struct ContentView: View {

    @State private var records: [MedicalRecord] = []
    @State private var showingForm: Bool = false
    @State private var selectedRecord: MedicalRecord? = nil
    @State private var searchText: String = ""

    // MARK: - Filtered Records
    var filteredRecords: [MedicalRecord] {
        if searchText.isEmpty {
            return records
        } else {
            return records.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bloodType.localizedCaseInsensitiveContains(searchText) ||
                $0.conditions.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBlue).opacity(0.05),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {

                    // Stats Bar
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Total Records",
                            value: "\(records.count)",
                            icon: "person.3.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Latest Entry",
                            value: records.isEmpty ? "None" : shortDate(records.last!.dateAdded),
                            icon: "calendar",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search by name, blood type, condition...", text: $searchText)
                            .autocapitalization(.none)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Records List or Empty State
                    if filteredRecords.isEmpty {
                        Spacer()
                        EmptyStateView(hasRecords: !records.isEmpty)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredRecords) { record in
                                RecordRowView(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedRecord = record
                                    }
                                    .listRowBackground(Color(.secondarySystemBackground))
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 6,
                                        leading: 16,
                                        bottom: 6,
                                        trailing: 16
                                    ))
                            }
                            .onDelete(perform: deleteRecord) // ✅ Fixed: now calls local func
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
                    if !records.isEmpty {
                        EditButton()
                            .foregroundColor(.blue)
                    }
                }
            }
            // ✅ Fixed: passes both required bindings
            .sheet(isPresented: $showingForm) {
                ConnectionSettingsView(
                    records: $records,
                    isPresented: $showingForm
                )
            }
            // ✅ Fixed: detail sheet uses item binding
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(
                    record: record,
                    records: $records
                )
            }
        }
    }

    // MARK: - Delete Record
    // ✅ Fixed: defined inside ContentView so it can access `records`
    func deleteRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
    }

    // MARK: - Date Formatter
    func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card
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
                    .font(.headline)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Record Row View
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !record.conditions.isEmpty {
                        Text("•").foregroundColor(.secondary)
                        Text(record.conditions)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    func bloodTypeColor(_ type: String) -> Color {
        switch type {
        case "A+", "A-":  return .blue
        case "B+", "B-":  return .green
        case "AB+", "AB-": return .purple
        case "O+", "O-":  return .red
        default:           return .gray
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var hasRecords: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasRecords ? "magnifyingglass" : "cross.case.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.4))
            Text(hasRecords ? "No matching records" : "No Health Records Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(hasRecords
                 ? "Try a different search term."
                 : "Tap the + button to add your first medical record.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Record Detail View
struct RecordDetailView: View {
    var record: MedicalRecord
    @Binding var records: [MedicalRecord]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Avatar
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
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(spacing: 14) {
                        DetailRow(icon: "person.fill",
                                  label: "Age",
                                  value: "\(record.age) years old",
                                  color: .blue)
                        DetailRow(icon: "drop.fill",
                                  label: "Blood Type",
                                  value: record.bloodType.isEmpty ? "Not specified" : record.bloodType,
                                  color: .red)
                        DetailRow(icon: "heart.text.square.fill",
                                  label: "Conditions",
                                  value: record.conditions.isEmpty ? "None reported" : record.conditions,
                                  color: .orange)
                        DetailRow(icon: "pills.fill",
                                  label: "Medications",
                                  value: record.medications.isEmpty ? "None" : record.medications,
                                  color: .green)
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
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    var icon: String
    var label: String
    var value: String
    var color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
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


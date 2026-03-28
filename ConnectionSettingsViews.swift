import SwiftUI

// MARK: - Blood Type Enum
enum BloodType: String, CaseIterable, Identifiable {
    case unknown = "Select"
    case aPos    = "A+"
    case aNeg    = "A-"
    case bPos    = "B+"
    case bNeg    = "B-"
    case abPos   = "AB+"
    case abNeg   = "AB-"
    case oPos    = "O+"
    case oNeg    = "O-"

    var id: String { self.rawValue }
}

// MARK: - Connection Settings View
struct ConnectionSettingsView: View {

    // ✅ Both bindings explicitly declared
    @Binding var records: [MedicalRecord]
    @Binding var isPresented: Bool

    // Form fields
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedBloodType: BloodType = .unknown
    @State private var conditions: String = ""
    @State private var medications: String = ""

    // UI state
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    @State private var showSuccessBanner: Bool = false
    @State private var isSaving: Bool = false

    // MARK: - Validation
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !age.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(age) != nil &&
        (Int(age) ?? 0) > 0 &&
        (Int(age) ?? 0) <= 130 &&
        selectedBloodType != .unknown
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 24) {

                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Text("New Medical Record")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Fill in the patient's details below")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)

                        // Personal Info
                        FormSection(
                            title: "Personal Information",
                            icon: "person.fill",
                            color: .blue
                        ) {
                            VStack(spacing: 14) {
                                CustomTextField(
                                    icon: "person.fill",
                                    placeholder: "Full Name",
                                    text: $name,
                                    color: .blue
                                )
                                CustomTextField(
                                    icon: "number",
                                    placeholder: "Age (e.g. 28)",
                                    text: $age,
                                    color: .blue,
                                    keyboardType: .numberPad
                                )
                                // Blood Type Picker
                                HStack(spacing: 12) {
                                    Image(systemName: "drop.fill")
                                        .foregroundColor(.red)
                                        .frame(width: 20)
                                    Picker("Blood Type", selection: $selectedBloodType) {
                                        ForEach(BloodType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(selectedBloodType == .unknown ? .secondary : .red)
                                    Spacer()
                                    Text("Blood Type")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }

                        // Medical Details
                        FormSection(
                            title: "Medical Details",
                            icon: "heart.text.square.fill",
                            color: .orange
                        ) {
                            VStack(spacing: 14) {
                                CustomTextEditor(
                                    icon: "heart.text.square.fill",
                                    placeholder: "Medical conditions (e.g. Diabetes, Hypertension)",
                                    text: $conditions,
                                    color: .orange
                                )
                                CustomTextEditor(
                                    icon: "pills.fill",
                                    placeholder: "Current medications (e.g. Metformin 500mg)",
                                    text: $medications,
                                    color: .green
                                )
                            }
                        }

                        // Live Validation Hints
                        if !name.isEmpty || !age.isEmpty {
                            ValidationHintsView(
                                name: name,
                                age: age,
                                bloodType: selectedBloodType
                            )
                        }

                        // Buttons
                        VStack(spacing: 12) {
                            Button(action: saveRecord) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 4)
                                    }
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text(isSaving ? "Saving..." : "Save Record")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    isFormValid
                                    ? LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing)
                                    : LinearGradient(
                                        colors: [.gray.opacity(0.4), .gray.opacity(0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(!isFormValid || isSaving)

                            Button(action: clearForm) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Clear Form")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(.secondary)
                                .cornerRadius(14)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                }

                // Success Banner overlay
                if showSuccessBanner {
                    SuccessBannerView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false  // ✅ Safe binding dismiss
                    }
                    .foregroundColor(.blue)
                }
            }
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Save Record
    func saveRecord() {
        guard isFormValid else {
            validationMessage = buildValidationMessage()
            showValidationAlert = true
            return
        }

        isSaving = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let newRecord = MedicalRecord(
                name: name.trimmingCharacters(in: .whitespaces),
                age: age.trimmingCharacters(in: .whitespaces),
                bloodType: selectedBloodType.rawValue,
                conditions: conditions.trimmingCharacters(in: .whitespaces),
                medications: medications.trimmingCharacters(in: .whitespaces)
            )
            records.append(newRecord)
            isSaving = false

            withAnimation(.spring()) {
                showSuccessBanner = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation { showSuccessBanner = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    clearForm()
                    isPresented = false  // ✅ Fires after full animation
                }
            }
        }
    }

    // MARK: - Clear Form
    func clearForm() {
        name = ""
        age = ""
        selectedBloodType = .unknown
        conditions = ""
        medications = ""
    }

    // MARK: - Validation Message
    func buildValidationMessage() -> String {
        var messages: [String] = []
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            messages.append("• Name is required.")
        }
        if age.trimmingCharacters(in: .whitespaces).isEmpty {
            messages.append("• Age is required.")
        } else if Int(age) == nil {
            messages.append("• Age must be a valid number.")
        } else if let ageInt = Int(age), ageInt <= 0 || ageInt > 130 {
            messages.append("• Age must be between 1 and 130.")
        }
        if selectedBloodType == .unknown {
            messages.append("• Please select a blood type.")
        }
        return messages.joined(separator: "\n")
    }
}

// MARK: - Form Section Wrapper
struct FormSection<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var color: Color
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .default ? .words : .none)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(text.isEmpty ? Color.clear : color.opacity(0.4), lineWidth: 1.5)
        )
    }
}

// MARK: - Custom Text Editor
struct CustomTextEditor: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            TextEditor(text: $text)
                .frame(minHeight: 70, maxHeight: 100)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
                .scrollContentBackground(.hidden)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(text.isEmpty ? Color.clear : color.opacity(0.4), lineWidth: 1.5)
        )
    }
}

// MARK: - Validation Hints View
struct ValidationHintsView: View {
    var name: String
    var age: String
    var bloodType: BloodType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Checklist")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            HintRow(
                isValid: !name.trimmingCharacters(in: .whitespaces).isEmpty,
                text: "Name entered"
            )
            HintRow(
                isValid: Int(age) != nil && (Int(age) ?? 0) > 0 && (Int(age) ?? 0) <= 130,
                text: "Valid age (1–130)"
            )
            HintRow(
                isValid: bloodType != .unknown,
                text: "Blood type selected"
            )
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Hint Row
struct HintRow: View {
    var isValid: Bool
    var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
                .foregroundColor(isValid ? .primary : .secondary)
        }
    }
}

// MARK: - Success Banner
struct SuccessBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.white)
                .font(.title3)
            Text("Record saved successfully!")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.green, .mint],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.top, 8)
        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    ConnectionSettingsView(
        records: .constant([]),
        isPresented: .constant(true)
    )
}


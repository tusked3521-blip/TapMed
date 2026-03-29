import SwiftUI
import SwiftData

// MARK: - Item Category Enum
enum ItemCategory: String, CaseIterable, Identifiable {
    case medication   = "Medication"
    case supplement   = "Supplement"
    case equipment    = "Equipment"
    case firstAid     = "First Aid"
    case prescription = "Prescription"
    case other        = "Other"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .medication:   return "pills.fill"
        case .supplement:   return "leaf.fill"
        case .equipment:    return "stethoscope"
        case .firstAid:     return "cross.case.fill"
        case .prescription: return "doc.text.fill"
        case .other:        return "archivebox.fill"
        }
    }

    var color: Color {
        switch self {
        case .medication:   return .blue
        case .supplement:   return .green
        case .equipment:    return .purple
        case .firstAid:     return .red
        case .prescription: return .orange
        case .other:        return .gray
        }
    }
    
}

// MARK: - Item Priority Enum
enum ItemPriority: String, CaseIterable, Identifiable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }

    var icon: String {
        switch self {
        case .low:    return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high:   return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Health Item Model
@Model class HealthItem: Identifiable {
    var id: UUID
    var name: String
    var categoryString: String       // Persisted as String
    
    var quantity: Int
    var unit: String
    var priorityString: String       // Persisted as String
    var isLowStock: Bool
    var notes: String
    var expiryDate: Date?
    var hasExpiry: Bool
    var dateAdded: Date
    
    init(name: String, categoryString: String, quantity: Int,
             unit: String, priorityString: String, notes: String,
             expiryDate: Date?, hasExpiry: Bool, isLowStock: Bool) {
            self.id = UUID()
            self.name = name
            self.categoryString = categoryString
            self.quantity = quantity
            self.unit = unit
            self.priorityString = priorityString
            self.notes = notes
            self.expiryDate = expiryDate
            self.hasExpiry = hasExpiry
            self.dateAdded = Date()
            self.isLowStock = isLowStock
        }

        // MARK: - Computed Properties (Convert String -> Enum)
        var category: ItemCategory {
            return ItemCategory(rawValue: categoryString) ?? .other
        }

        var priority: ItemPriority {
            return ItemPriority(rawValue: priorityString) ?? .medium
        }
    
    
}

// MARK: - Items Section View
struct ItemsSectionView: View {

    @State private var items: [HealthItem] = []
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem: Bool = false
    @State private var selectedItem: HealthItem? = nil
    @State private var searchText: String = ""
    @State private var selectedCategory: ItemCategory? = nil
    @State private var selectedSortOption: SortOption = .nameAsc
    @State private var showingDeleteAlert: Bool = false
    @State private var itemToDelete: HealthItem? = nil

    // MARK: - Sort Options
    enum SortOption: String, CaseIterable {
        case nameAsc    = "Name A–Z"
        case nameDesc   = "Name Z–A"
        case priority   = "Priority"
        case quantity   = "Quantity"
        case expiry     = "Expiry Date"
    }

    // MARK: - Filtered & Sorted Items
    var filteredItems: [HealthItem] {
        var result = items

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Sort
        switch selectedSortOption {
        case .nameAsc:
            result.sort { $0.name < $1.name }
        case .nameDesc:
            result.sort { $0.name > $1.name }
        case .priority:
            let order: [ItemPriority] = [.high, .medium, .low]
            result.sort { order.firstIndex(of: $0.priority)! < order.firstIndex(of: $1.priority)! }
        case .quantity:
            result.sort { $0.quantity < $1.quantity }
        case .expiry:
            result.sort {
                guard let d1 = $0.expiryDate, let d2 = $1.expiryDate else { return false }
                return d1 < d2
            }
        }

        return result
    }

    // MARK: - Low Stock Items
    var lowStockItems: [HealthItem] {
        items.filter { $0.isLowStock }
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(.systemBlue).opacity(0.04), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: Summary Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            SummaryCard(
                                title: "Total Items",
                                value: "\(items.count)",
                                icon: "archivebox.fill",
                                color: .blue
                            )
                            SummaryCard(
                                title: "Low Stock",
                                value: "\(lowStockItems.count)",
                                icon: "exclamationmark.triangle.fill",
                                color: lowStockItems.isEmpty ? .green : .red
                            )
                            SummaryCard(
                                title: "Categories",
                                value: "\(Set(items.map { $0.category }).count)",
                                icon: "square.grid.2x2.fill",
                                color: .purple
                            )
                            SummaryCard(
                                title: "High Priority",
                                value: "\(items.filter { $0.priority == .high }.count)",
                                icon: "flag.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    // MARK: Low Stock Alert Banner
                    if !lowStockItems.isEmpty {
                        LowStockBanner(count: lowStockItems.count)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    // MARK: Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search items...", text: $searchText)
                            .autocapitalization(.none)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // MARK: Category Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                label: "All",
                                icon: "square.grid.2x2",
                                color: .blue,
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            ForEach(ItemCategory.allCases) { category in
                                CategoryChip(
                                    label: category.rawValue,
                                    icon: category.icon,
                                    color: category.color,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = (selectedCategory == category) ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    // MARK: Sort Bar
                    HStack {
                        Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { selectedSortOption = option }) {
                                    HStack {
                                        Text(option.rawValue)
                                        // if selectedSortOption == option {
                                        //    Image(systemName: "checkmark")
                                        // }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.caption)
                                Text("Sort: \(selectedSortOption.rawValue)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                    // MARK: Items List
                    if filteredItems.isEmpty {
                        Spacer()
                        ItemsEmptyStateView(
                            hasItems: !items.isEmpty,
                            categoryFilter: selectedCategory?.rawValue
                        )
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredItems) { item in
                                ItemRowView(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            itemToDelete = item
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            incrementQuantity(for: item)
                                        } label: {
                                            Label("Add Stock", systemImage: "plus.circle")
                                        }
                                        .tint(.green)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 5, leading: 16, bottom: 5, trailing: 16
                                    ))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("🧴 Health Items")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(items: $items, isPresented: $showingAddItem)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item, items: $items)
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        deleteItem(item)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \"\(itemToDelete?.name ?? "this item")\"?")
            }
        }
    }

    // MARK: - Helper Functions
    func deleteItem(_ item: HealthItem) {
        modelContext.delete(item)
    }

    func incrementQuantity(for item: HealthItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].quantity += 1
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(width: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Low Stock Banner
struct LowStockBanner: View {
    var count: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text("\(count) item\(count == 1 ? "" : "s") running low on stock")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [.red, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    var label: String
    var icon: String
    var color: Color
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Item Row View
struct ItemRowView: View {
    var item: HealthItem

    var body: some View {
        HStack(spacing: 14) {

            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.category.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: item.category.icon)
                    .font(.title3)
                    .foregroundColor(item.category.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    if item.isLowStock {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                HStack(spacing: 8) {
                    // Category tag
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.category.color.opacity(0.15))
                        .foregroundColor(item.category.color)
                        .cornerRadius(4)

                    // Priority tag
                    HStack(spacing: 3) {
                        Image(systemName: item.priority.icon)
                            .font(.caption2)
                        Text(item.priority.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(item.priority.color)
                }
            }

            Spacer()

            // Quantity Badge
            VStack(spacing: 2) {
                Text("\(item.quantity)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(item.isLowStock ? .red : .primary)
                Text(item.unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 44)
            .padding(8)
            .background(
                item.isLowStock
                ? Color.red.opacity(0.1)
                : Color(.secondarySystemBackground)
            )
            .cornerRadius(10)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Items Empty State
struct ItemsEmptyStateView: View {
    var hasItems: Bool
    var categoryFilter: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasItems ? "line.3.horizontal.decrease.circle" : "archivebox")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.35))
            Text(hasItems ? "No items in \"\(categoryFilter ?? "this filter")\"" : "No Items Added Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(hasItems
                 ? "Try selecting a different category or clearing the search."
                 : "Tap the + button to start tracking your health items.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Item Detail View
struct ItemDetailView: View {
    var item: HealthItem
    @Binding var items: [HealthItem]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Header Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient(
                                colors: [item.category.color, item.category.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 90, height: 90)
                        Image(systemName: item.category.icon)
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)

                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    // Stock Indicator
                    StockIndicatorView(quantity: item.quantity, unit: item.unit)

                    // Detail Cards
                    VStack(spacing: 12) {
                        ItemDetailRow(
                            icon: item.category.icon,
                            label: "Category",
                            value: item.category.rawValue,
                            color: item.category.color
                        )
                        ItemDetailRow(
                            icon: item.priority.icon,
                            label: "Priority",
                            value: item.priority.rawValue,
                            color: item.priority.color
                        )
                        ItemDetailRow(
                            icon: "number.circle.fill",
                            label: "Quantity",
                            value: "\(item.quantity) \(item.unit)",
                            color: item.isLowStock ? .red : .blue
                        )
                        if item.hasExpiry, let expiry = item.expiryDate {
                            ItemDetailRow(
                                icon: "calendar.badge.exclamationmark",
                                label: "Expiry Date",
                                value: formattedDate(expiry),
                                color: isExpiringSoon(expiry) ? .orange : .green
                            )
                        }
                        if !item.notes.isEmpty {
                            ItemDetailRow(
                                icon: "note.text",
                                label: "Notes",
                                value: item.notes,
                                color: .gray
                            )
                        }
                        ItemDetailRow(
                            icon: "calendar",
                            label: "Date Added",
                            value: formattedDate(item.dateAdded),
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        items.removeAll { $0.id == item.id }
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
        f.dateStyle = .medium
        return f.string(from: date)
    }

    func isExpiringSoon(_ date: Date) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days <= 30
    }
}

// MARK: - Stock Indicator View
struct StockIndicatorView: View {
    var quantity: Int
    var unit: String

    var stockLevel: String {
        if quantity == 0 { return "Out of Stock" }
        if quantity <= 2  { return "Low Stock" }
        if quantity <= 10 { return "Moderate" }
        return "Well Stocked"
    }

    var stockColor: Color {
        if quantity == 0 { return .red }
        if quantity <= 2  { return .orange }
        if quantity <= 10 { return .yellow }
        return .green
    }

    var fillFraction: Double {
        min(Double(quantity) / 20.0, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Stock Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(stockLevel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(stockColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [stockColor.opacity(0.7), stockColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * fillFraction, height: 10)
                        .animation(.spring(), value: fillFraction)
                }
            }
            .frame(height: 10)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Item Detail Row
struct ItemDetailRow: View {
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

// MARK: - Add Item View
struct AddItemView: View {

    @Environment(\.modelContext) private var modelContext
    @Binding var items: [HealthItem]
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var selectedCategory: ItemCategory = .medication
    @State private var quantity: String = "1"
    @State private var unit: String = "pcs"
    @State private var selectedPriority: ItemPriority = .medium
    @State private var notes: String = ""
    @State private var hasExpiry: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(
        byAdding: .year, value: 1, to: Date()
    ) ?? Date()

    @State private var showValidationAlert: Bool = false
    @State private var showSuccessBanner: Bool = false
    @State private var isSaving: Bool = false

    let unitOptions = ["pcs", "mg", "ml", "tablets", "capsules", "bottles", "boxes", "strips"]

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(quantity) != nil &&
        (Int(quantity) ?? 0) >= 0
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 22) {

                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(LinearGradient(
                                        colors: [selectedCategory.color, selectedCategory.color.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 72, height: 72)
                                Image(systemName: selectedCategory.icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            .animation(.spring(), value: selectedCategory)

                            Text("Add Health Item")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Track your medical supplies and medications")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)

                        // MARK: Basic Info Section
                        AddFormSection(title: "Item Information", icon: "info.circle.fill", color: .blue) {
                            VStack(spacing: 14) {

                                // Name Field
                                AddCustomTextField(
                                    icon: "tag.fill",
                                    placeholder: "Item name (e.g. Paracetamol)",
                                    text: $name,
                                    color: .blue
                                )

                                // Category Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.grid.2x2.fill")
                                            .foregroundColor(.purple)
                                            .frame(width: 20)
                                        Text("Category")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.top, 12)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(ItemCategory.allCases) { cat in
                                                Button(action: { selectedCategory = cat }) {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: cat.icon)
                                                            .font(.title3)
                                                            .foregroundColor(
                                                                selectedCategory == cat ? .white : cat.color
                                                            )
                                                        Text(cat.rawValue)
                                                            .font(.caption2)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(
                                                                selectedCategory == cat ? .white : .primary
                                                            )
                                                    }
                                                    .frame(width: 72, height: 64)
                                                    .background(
                                                        selectedCategory == cat
                                                        ? cat.color
                                                        : Color(.tertiarySystemBackground)
                                                    )
                                                    .cornerRadius(12)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.bottom, 12)
                                    }
                                }
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }

                        // MARK: Quantity Section
                        AddFormSection(title: "Quantity & Unit", icon: "number.circle.fill", color: .green) {
                            VStack(spacing: 14) {
                                HStack(spacing: 12) {
                                    // Quantity stepper
                                    HStack {
                                        Button(action: {
                                            if let q = Int(quantity), q > 0 {
                                                quantity = "\(q - 1)"
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                        TextField("Qty", text: $quantity)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.center)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .frame(width: 60)
                                        Button(action: {
                                            if let q = Int(quantity) {
                                                quantity = "\(q + 1)"
                                            }
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.green.opacity(0.8))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)

                                    // Unit picker
                                    Picker("Unit", selection: $unit) {
                                        ForEach(unitOptions, id: \.self) { u in
                                            Text(u).tag(u)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.green)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                        }

                        // MARK: Priority Section
                        AddFormSection(title: "Priority Level", icon: "flag.fill", color: .orange) {
                            HStack(spacing: 10) {
                                ForEach(ItemPriority.allCases) { priority in
                                    Button(action: { selectedPriority = priority }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: priority.icon)
                                                .font(.subheadline)
                                            Text(priority.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedPriority == priority
                                            ? priority.color
                                            : Color(.secondarySystemBackground)
                                        )
                                        .foregroundColor(
                                            selectedPriority == priority ? .white : .primary
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        // MARK: Expiry Section
                        AddFormSection(title: "Expiry Date", icon: "calendar.badge.exclamationmark", color: .red) {
                            VStack(spacing: 12) {
                                Toggle(isOn: $hasExpiry) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.red)
                                        Text("Has expiry date")
                                            .font(.subheadline)
                                    }
                                }
                                .tint(.red)

                                if hasExpiry {
                                    DatePicker(
                                        "Expiry Date",
                                        selection: $expiryDate,
                                        in: Date()...,
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.graphical)
                                    .tint(.red)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }

                        // MARK: Notes Section
                        AddFormSection(title: "Notes", icon: "note.text", color: .gray) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 8) {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    Text("Additional notes (optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.top, 12)

                                TextEditor(text: $notes)
                                    .frame(minHeight: 80, maxHeight: 120)
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 8)
                                    .scrollContentBackground(.hidden)
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // MARK: Save / Clear Buttons
                        VStack(spacing: 12) {
                            Button(action: saveItem) {
                                HStack {
                                    if isSaving {
                                        ProgressView().tint(.white).padding(.trailing, 4)
                                    }
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text(isSaving ? "Saving..." : "Save Item")
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
                                    Text("Clear Form").fontWeight(.medium)
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

                // Success Banner
                if showSuccessBanner {
                    SuccessBannerView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.blue)
                }
            }
            .alert("Missing Information", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a valid item name and quantity.")
            }
        }
    }

    // MARK: - Save Item
    func saveItem() {
        guard isFormValid else {
            showValidationAlert = true
            return
        }
        
        // Use ModelContext to insert, do not append to array
        let newItem = HealthItem(
            name: name.trimmingCharacters(in: .whitespaces),
            categoryString: selectedCategory.rawValue, // Fixed: Pass String
            quantity: Int(quantity) ?? 1,
            unit: unit,
            priorityString: selectedPriority.rawValue, // Fixed: Pass String
            notes: notes.trimmingCharacters(in: .whitespaces),
            expiryDate: hasExpiry ? expiryDate : nil,
            hasExpiry: hasExpiry,
            isLowStock: false // Initialize as false; logic will handle updates later if needed
        )
        
        modelContext.insert(newItem)
        
        // Show success banner and dismiss
        withAnimation(.spring()) { showSuccessBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isPresented = false
            // Reset form state if needed
        }
    }

    // MARK: - Clear Form
    func clearForm() {
        name = ""
        selectedCategory = .medication
        quantity = "1"
        unit = "pcs"
        selectedPriority = .medium
        notes = ""
        hasExpiry = false
    }
}

// MARK: - Add Form Section Wrapper
struct AddFormSection<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.headline).fontWeight(.semibold)
            }
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Add Custom Text Field
struct AddCustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 20)
            TextField(placeholder, text: $text)
                .autocapitalization(.words)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        
    }
}

import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @Environment(\.modelContext) private var context
    @State private var showEditor = false
    @State private var editing: CategoryItem?

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editing = category
                    showEditor = true
                } label: {
                    HStack {
                        Image(systemName: category.iconName)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading) {
                            Text(category.name).foregroundStyle(.primary)
                            Text(category.isSystem ? "Bawaan · \(category.kind.title)" : category.kind.title)
                                .font(BudgetFont.caption())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Kategori")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Tambah kategori")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { CategoryEditorView(existing: editing) }
        }
    }
}

struct CategoryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var existing: CategoryItem?

    @State private var name = ""
    @State private var kind: CategoryKind = .expense
    @State private var showDelete = false

    var body: some View {
        Form {
            TextField("Nama", text: $name)
            Picker("Dipakai untuk", selection: $kind) {
                ForEach(CategoryKind.allCases, id: \.self) { item in
                    Text(item.title).tag(item)
                }
            }
            if existing?.isSystem == false || existing == nil {
                if existing != nil {
                    Button("Hapus kategori", role: .destructive) { showDelete = true }
                }
            } else {
                Text("Kategori bawaan bisa diubah namanya, tetapi tidak dihapus dari sini.")
                    .font(BudgetFont.footnote())
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(existing == nil ? "Kategori baru" : "Edit kategori")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Batal") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            guard let existing else { return }
            name = existing.name
            kind = existing.kind
        }
        .alert("Hapus kategori?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive) {
                if let existing, !existing.isSystem {
                    context.delete(existing)
                    try? context.save()
                }
                dismiss()
            }
            Button("Batal", role: .cancel) {}
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.name = trimmed
            existing.kind = kind
        } else {
            context.insert(CategoryItem(name: trimmed, iconName: "tag", kind: kind, isSystem: false, sortOrder: 99))
        }
        try? context.save()
        dismiss()
    }
}

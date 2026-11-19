import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: KeywordStore
    @State private var newWord = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationView {
            List {
                if !SharedStore.isGroupAvailable {
                    Section {
                        Text("App Group not available. The Safari extension cannot read your list until the app is signed with the App Group entitlement (AltStore/SideStore does this).")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }

                Section(header: Text("Add blocked word")) {
                    HStack {
                        TextField("e.g. casino", text: $newWord)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                            .focused($fieldFocused)
                            .onSubmit(addWord)
                        Button("Add", action: addWord)
                            .disabled(SharedStore.normalize(newWord).isEmpty)
                    }
                }

                Section(
                    header: Text("Blocked words (\(store.keywords.count))"),
                    footer: Text("A tab is closed as soon as its URL or search query contains any of these words. Matching ignores case, accents, + and %20.")
                ) {
                    if store.keywords.isEmpty {
                        Text("No blocked words yet.").foregroundColor(.secondary)
                    }
                    ForEach(store.keywords, id: \.self) { word in
                        Text(word)
                    }
                    .onDelete(perform: store.remove)
                }

                Section(header: Text("Setup")) {
                    Text("Settings → Safari → Extensions → Keyword Tab Killer → turn on and set “All Websites” to Allow. On iOS 18+: Settings → Apps → Safari → Extensions.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Keyword Tab Killer")
            .toolbar { EditButton() }
        }
        .navigationViewStyle(.stack)
    }

    private func addWord() {
        if store.add(newWord) { newWord = "" }
        fieldFocused = false
    }
}

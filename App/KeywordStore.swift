import Foundation

final class KeywordStore: ObservableObject {
    @Published private(set) var keywords: [String] = []

    init() { reload() }

    func reload() {
        keywords = SharedStore.load()
    }

    @discardableResult
    func add(_ raw: String) -> Bool {
        let word = SharedStore.normalize(raw)
        guard !word.isEmpty, !keywords.contains(word) else { return false }
        keywords.append(word)
        SharedStore.save(keywords)
        return true
    }

    func remove(at offsets: IndexSet) {
        keywords.remove(atOffsets: offsets)
        SharedStore.save(keywords)
    }
}

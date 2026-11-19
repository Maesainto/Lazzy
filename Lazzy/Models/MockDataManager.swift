import UIKit

struct Friend: Identifiable, Codable {
    let id: UUID
    var name: String
    var steps: Int
    var hasFailed: Bool
    var avatarName: String
    var bio: String?
    var personalGoal: Int?
    var trophyIDs: [String]?
    var equippedTrophyID: String?
    var dailyGoal: Int { max(1, personalGoal ?? 10000) }
    var trophies: [Trophy] {
        let ids = trophyIDs ?? Trophy.dayIDs(steps: steps)
        return Trophy.all.filter { ids.contains($0.id) }
    }
    var equippedTrophy: Trophy? {
        if let id = equippedTrophyID { return trophies.first { $0.id == id } }
        return trophyIDs == nil ? trophies.last : nil
    }
    var displayName: String { name + (equippedTrophy.map { " " + $0.badge } ?? "") }
    init(name: String, steps: Int, hasFailed: Bool = false, avatarName: String = "") {
        id = UUID(); self.name = name; self.steps = steps; self.hasFailed = hasFailed; self.avatarName = avatarName
        bio = nil; personalGoal = 10000
        trophyIDs = Trophy.dayIDs(steps: steps); equippedTrophyID = trophyIDs?.last
    }
}
struct WalkingGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var symbol: String
    var goal: Int
    var members: [Friend]
    var photoFile: String?
    var photo: UIImage? {
        guard let photoFile else { return nil }
        let url = LocalStore.fileURL(photoFile)
        guard let bytes = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: bytes)
    }
    init(id: UUID = UUID(), name: String, symbol: String, goal: Int, members: [Friend], photoFile: String? = nil) {
        self.id = id; self.name = name; self.symbol = symbol
        self.goal = goal; self.members = members; self.photoFile = photoFile
    }
}
struct ShamePost: Identifiable {
    let id: UUID
    let name: String
    let challenge: String
    let imageName: String?
    let imageFile: String?
    let isDemo: Bool
    var likes: Int
    var isLiked: Bool
    var createdAt: Date = Date()
    var image: UIImage? {
        if let imageFile { return UIImage(contentsOfFile: LocalStore.fileURL(imageFile).path) }
        return imageName.flatMap(UIImage.init(named:))
    }
}

/// Données sociales de démonstration. Aucune requête vers l'API de Gaël pour le moment.
final class MockDataManager {
    static let shared = MockDataManager()
    var friends = [Friend(name: "Maé", steps: 12450), Friend(name: "Gaël", steps: 10820),
                   Friend(name: "Simon", steps: 7340), Friend(name: "Lucas", steps: 4230, hasFailed: true)] { didSet { saveSocialData() } }
    var groups: [WalkingGroup] = [] {
        didSet {
            saveSocialData()
            NotificationCenter.default.post(name: .lazzyGroupsChanged, object: nil)
        }
    }
    var posts: [ShamePost] = [
        ShamePost(id: UUID(), name: "Lucas", challenge: "Une journée en banane", imageName: "ProofCostume", imageFile: nil, isDemo: true, likes: 12, isLiked: false),
        ShamePost(id: UUID(), name: "Simon", challenge: "La danse de la défaite", imageName: "ProofDance", imageFile: nil, isDemo: true, likes: 8, isLiked: false)
    ]
    private init() {
        if let saved = UserDefaults.standard.data(forKey: "lazzy.friends"),
           let decoded = try? JSONDecoder().decode([Friend].self, from: saved) { friends = decoded }
        if let saved = UserDefaults.standard.data(forKey: "lazzy.groups"),
           let decoded = try? JSONDecoder().decode([WalkingGroup].self, from: saved) { groups = decoded }
        else {
            groups = [WalkingGroup(name: "Les marcheurs du campus", symbol: "figure.walk", goal: 10000, members: friends),
                      WalkingGroup(name: "La team du dimanche", symbol: "sun.max", goal: 8000, members: Array(friends.prefix(3)))]
        }
        saveSocialData()
        loadLocalPosts()
    }
    private func saveSocialData() {
        if let encoded = try? JSONEncoder().encode(friends) { UserDefaults.standard.set(encoded, forKey: "lazzy.friends") }
        if let encoded = try? JSONEncoder().encode(groups) { UserDefaults.standard.set(encoded, forKey: "lazzy.groups") }
    }
    func updateGroup(_ group: WalkingGroup) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index] = group
    }

    func addProof(image: UIImage, challenge: String) throws {
        let file = "proof-\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileWriteUnknown) }
        try data.write(to: LocalStore.fileURL(file), options: .atomic)
        let post = ShamePost(id: UUID(), name: ProfileStore.shared.name, challenge: challenge,
                             imageName: nil, imageFile: file, isDemo: false, likes: 0, isLiked: false)
        posts.insert(post, at: 0)
        saveLocalPosts()
    }
    func removeExpiredProofs() {
        let expired = posts.filter { !$0.isDemo && Date().timeIntervalSince($0.createdAt) >= 86400 }
        for post in expired {
            if let file = post.imageFile { try? FileManager.default.removeItem(at: LocalStore.fileURL(file)) }
        }
        posts.removeAll { !$0.isDemo && Date().timeIntervalSince($0.createdAt) >= 86400 }
        saveLocalPosts()
    }
    private func saveLocalPosts() {
        let saved = posts.filter { !$0.isDemo }.map { ["name": $0.name, "challenge": $0.challenge, "file": $0.imageFile ?? "", "date": String($0.createdAt.timeIntervalSince1970)] }
        UserDefaults.standard.set(saved, forKey: "lazzy.localProofs")
    }
    private func loadLocalPosts() {
        let saved = UserDefaults.standard.array(forKey: "lazzy.localProofs") as? [[String: String]] ?? []
        posts.insert(contentsOf: saved.compactMap { item in
            guard let name = item["name"], let challenge = item["challenge"], let file = item["file"],
                  let timestamp = Double(item["date"] ?? "") else { return nil }
            guard Date().timeIntervalSince1970 - timestamp < 86400 else {
                try? FileManager.default.removeItem(at: LocalStore.fileURL(file))
                return nil
            }
            guard FileManager.default.fileExists(atPath: LocalStore.fileURL(file).path) else { return nil }
            return ShamePost(id: UUID(), name: name, challenge: challenge, imageName: nil,
                             imageFile: file, isDemo: false, likes: 0, isLiked: false, createdAt: Date(timeIntervalSince1970: timestamp))
        }, at: 0)
    }
}

enum LocalStore {
    static func fileURL(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
    }
}
final class ProfileStore {
    static let shared = ProfileStore()
    private let defaults = UserDefaults.standard
    var name: String { defaults.string(forKey: "lazzy.name") ?? "Simon" }
    var displayName: String { name + (TrophyStore.shared.equipped.map { " " + $0.badge } ?? "") }
    var bio: String { defaults.string(forKey: "lazzy.bio") ?? "Un pas après l’autre." }
    var dailyGoal: Int { let goal = defaults.integer(forKey: "lazzy.goal"); return goal > 0 ? goal : 10000 }
    var avatar: UIImage? { UIImage(contentsOfFile: LocalStore.fileURL("profile.jpg").path) }
    func save(name: String, bio: String, goal: Int) {
        defaults.set(name, forKey: "lazzy.name"); defaults.set(bio, forKey: "lazzy.bio"); defaults.set(goal, forKey: "lazzy.goal")
        NotificationCenter.default.post(name: .lazzyProfileChanged, object: nil)
    }
    func saveAvatar(_ image: UIImage) throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileWriteUnknown) }
        try data.write(to: LocalStore.fileURL("profile.jpg"), options: .atomic)
    }
}
extension Notification.Name {
    static let lazzyGroupsChanged = Notification.Name("lazzyGroupsChanged")
    static let lazzyProfileChanged = Notification.Name("lazzyProfileChanged")
}
extension Int {
    var stepsText: String { formatted(.number.locale(Locale(identifier: "fr_FR"))) }
}

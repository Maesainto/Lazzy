import Foundation

/// Import local d’une sauvegarde préparée sur le Mac. Les images sont copiées
/// avant le manifeste ; les préférences sont appliquées au prochain lancement.
enum LegacyDataImport {
    static let manifestName = "lazzy-legacy-import.plist"

    @discardableResult
    static func run(directory: URL = LocalStore.fileURL("").standardizedFileURL,
                    defaults: UserDefaults = .standard) throws -> Bool {
        let manifest = directory.appendingPathComponent(manifestName)
        guard FileManager.default.fileExists(atPath: manifest.path) else { return false }
        let object = try PropertyListSerialization.propertyList(from: Data(contentsOf: manifest), format: nil)
        guard let incoming = object as? [String: Any],
              let proofs = incoming["lazzy.localProofs"] as? [[String: String]] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // Tout valider avant d’écrire les préférences ; un transfert incomplet
        // pourra être repris sans perdre les preuves déjà dans la nouvelle app.
        for proof in proofs {
            guard let file = proof["file"], !file.isEmpty,
                  (file as NSString).lastPathComponent == file,
                  proof["name"] != nil, proof["challenge"] != nil,
                  let timestamp = Double(proof["date"] ?? ""), timestamp.isFinite,
                  FileManager.default.fileExists(atPath: directory.appendingPathComponent(file).path) else {
                throw CocoaError(.fileReadCorruptFile)
            }
        }
        var merged = defaults.array(forKey: "lazzy.localProofs") as? [[String: String]] ?? []
        for proof in proofs where !merged.contains(where: { $0["file"] == proof["file"] }) {
            merged.append(proof)
        }
        for key in ["lazzy.name", "lazzy.bio"] where defaults.object(forKey: key) == nil {
            if let value = incoming[key] as? String { defaults.set(value, forKey: key) }
        }
        if defaults.object(forKey: "lazzy.goal") == nil,
           let goal = incoming["lazzy.goal"] as? Int, goal > 0 {
            defaults.set(goal, forKey: "lazzy.goal")
        }
        defaults.set(merged, forKey: "lazzy.localProofs")
        try FileManager.default.removeItem(at: manifest)
        return true
    }
}

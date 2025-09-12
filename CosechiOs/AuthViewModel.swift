import Foundation
import CoreData

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserID: UUID?

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
    }

    enum AuthError: LocalizedError {
        case emailTaken
        case invalidCredentials
        case unknown(Error)
        var errorDescription: String? {
            switch self {
            case .emailTaken: return "El correo ya está en uso."
            case .invalidCredentials: return "Correo o contraseña incorrectos."
            case .unknown(let e): return e.localizedDescription
            }
        }
    }

    func register(username: String, email: String, password: String) async throws {
        // Validación simple
        guard password.count >= 8 else { throw AuthError.unknown(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Contraseña muy corta"])) }

        let fr: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "User")
        fr.predicate = NSPredicate(format: "email ==[c] %@", email.lowercased())
        let found = try viewContext.fetch(fr)
        guard found.isEmpty else { throw AuthError.emailTaken }

        // Crear User
        let userEntity = NSEntityDescription.entity(forEntityName: "User", in: viewContext)!
        let user = NSManagedObject(entity: userEntity, insertInto: viewContext)
        let userID = UUID()
        user.setValue(userID, forKey: "userID")
        user.setValue(username, forKey: "username")
        user.setValue(email.lowercased(), forKey: "email")
        user.setValue(Date(), forKey: "createdAt")
        user.setValue(Date(), forKey: "updatedAt")

        try viewContext.save()

        // Guardar hash+salt en Keychain (no sincronizable)
        let salt = randomSalt()
        let hash = sha256Hex(password: password, salt: salt)
        try KeychainHelper.savePasswordPayload(email: email, passwordHash: hash, salt: salt, synchronizable: false)

        self.currentUserID = userID
        self.isAuthenticated = true
    }

    func login(email: String, password: String) async throws {
        // Buscar user
        let fr: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "User")
        fr.predicate = NSPredicate(format: "email ==[c] %@", email.lowercased())
        let users = try viewContext.fetch(fr)
        guard let user = users.first else { throw AuthError.invalidCredentials }

        // Leer keychain
        do {
            let payload = try KeychainHelper.readPasswordPayload(email: email, synchronizable: false)
            let attemptHash = sha256Hex(password: password, salt: payload.salt)
            guard attemptHash == payload.hash else { throw AuthError.invalidCredentials }

            self.currentUserID = user.value(forKey: "userID") as? UUID
            self.isAuthenticated = true
        } catch {
            throw AuthError.invalidCredentials
        }
    }

    func logout() {
        self.currentUserID = nil
        self.isAuthenticated = false
    }
}


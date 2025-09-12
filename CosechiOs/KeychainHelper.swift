import Foundation
import Security
import CryptoKit

// Generador de salt
func randomSalt(length: Int = 16) -> Data {
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    precondition(status == errSecSuccess, "No se pudo generar salt")
    return Data(bytes)
}

func sha256Hex(password: String, salt: Data) -> String {
    var data = Data()
    data.append(salt)
    data.append(Data(password.utf8))
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
    case invalidData
}

struct KeychainHelper {
    /// Guarda (o actualiza) el payload JSON {hash:, salt:} bajo account = email
    static func savePasswordPayload(email: String, passwordHash: String, salt: Data, synchronizable: Bool = false) throws {
        let payload = ["hash": passwordHash, "salt": salt.base64EncodedString()]
        let data = try JSONEncoder().encode(payload)
        let account = email.lowercased()

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            // Actualizar
            var updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account
            ]
            if synchronizable {
                updateQuery[kSecAttrSynchronizable as String] = kCFBooleanTrue
            }
            let attributes: [String: Any] = [kSecValueData as String: data]
            let upStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            guard upStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(upStatus) }
        } else {
            guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        }
    }

    static func readPasswordPayload(email: String, synchronizable: Bool = false) throws -> (hash: String, salt: Data) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email.lowercased(),
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unexpectedStatus(status)
        }
        let payload = try JSONDecoder().decode([String: String].self, from: data)
        guard let hash = payload["hash"], let saltB64 = payload["salt"], let salt = Data(base64Encoded: saltB64) else {
            throw KeychainError.invalidData
        }
        return (hash, salt)
    }

    static func deletePasswordPayload(email: String, synchronizable: Bool = false) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email.lowercased()
        ]
        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unexpectedStatus(status) }
    }
}


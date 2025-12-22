import FirebaseAuth
import AuthenticationServices

final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    var isSignedIn: Bool { Auth.auth().currentUser != nil }

    func signUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func signInWithApple(result: Result<ASAuthorization, Error>) async throws {
        let authorization = try result.get()

        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = appleIDCredential.identityToken,
            let tokenString = String(data: identityToken, encoding: .utf8)
        else {
            throw NSError(domain: "AppleAuth", code: -1)
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nil,
            fullName: appleIDCredential.fullName
        )

        _ = try await Auth.auth().signIn(with: credential)
    }
}

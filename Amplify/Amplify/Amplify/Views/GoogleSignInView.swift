//
//  GoogleSignInView.swift
//  Amplify
//
//  Google Sign-In integration for API authentication
//

import SwiftUI
import GoogleSignIn

struct GoogleSignInView: View {
    @ObservedObject var appState: AppStateManager
    let onSignInComplete: () -> Void
    
    @State private var isSigningIn = false
    @State private var signInError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // App logo or branding
                VStack(spacing: 16) {
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Amplify")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Transform your stories with AI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Sign in section
                VStack(spacing: 20) {
                    Text("Sign in to enhance your stories")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Your stories and enhancements will be securely saved and synced across your devices.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Google Sign-In Button
                    Button(action: {
                        Task {
                            await performGoogleSignIn()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text("Sign in with Google")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .padding(.horizontal, 40)
                    }
                    .disabled(isSigningIn)
                    .opacity(isSigningIn ? 0.6 : 1.0)
                    
                    if isSigningIn {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Signing in...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = signInError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Privacy notice
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        appState.returnToHome()
                    }
                    .disabled(isSigningIn)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func performGoogleSignIn() async {
        print("🔵 Starting Google Sign-In process")
        isSigningIn = true
        signInError = nil
        
        do {
            print("🔵 Getting Google ID token...")
            // Get the Google ID token using GoogleSignIn SDK
            let googleIdToken = try await getGoogleIdToken()
            print("✅ Got Google ID token: \(String(googleIdToken.prefix(20)))...")
            
            print("🔵 Authenticating with backend...")
            // Use the real Google ID token with our backend
            try await appState.signInWithGoogle(googleIdToken)
            print("✅ Backend authentication successful")
            
            await MainActor.run {
                isSigningIn = false
                onSignInComplete()
            }
        } catch {
            print("❌ Sign-in failed with error: \(error)")
            await MainActor.run {
                isSigningIn = false
                signInError = error.localizedDescription
            }
        }
    }
    
    private func getGoogleIdToken() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Ensure we're on the main thread for UI operations
            DispatchQueue.main.async {
                print("🔵 Finding root view controller...")
                
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    print("❌ No window scene found")
                    continuation.resume(throwing: GoogleSignInError.noRootViewController)
                    return
                }
                
                guard let rootViewController = windowScene.windows.first?.rootViewController else {
                    print("❌ No root view controller found")
                    continuation.resume(throwing: GoogleSignInError.noRootViewController)
                    return
                }
                
                print("✅ Found root view controller: \(type(of: rootViewController))")
                
                // Check if Google Sign-In is already configured
                if GIDSignIn.sharedInstance.configuration == nil {
                    print("❌ GIDSignIn not configured - this should have been done in App.swift")
                    continuation.resume(throwing: GoogleSignInError.configurationMissing)
                    return
                }
                
                print("✅ GIDSignIn is configured")
                print("🔵 Starting Google Sign-In flow...")
                
                // Perform Google Sign-In
                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                    if let error = error {
                        print("❌ Google Sign-In error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let result = result else {
                        print("❌ No result from Google Sign-In")
                        continuation.resume(throwing: GoogleSignInError.noIdToken)
                        return
                    }
                    
                    guard let idToken = result.user.idToken?.tokenString else {
                        print("❌ No ID token in result")
                        continuation.resume(throwing: GoogleSignInError.noIdToken)
                        return
                    }
                    
                    print("✅ Got ID token successfully")
                    continuation.resume(returning: idToken)
                }
            }
        }
    }
}

// MARK: - Google Sign-In Errors

enum GoogleSignInError: LocalizedError {
    case noRootViewController
    case configurationMissing
    case configurationError
    case noIdToken
    
    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "Unable to find root view controller for Google Sign-In"
        case .configurationMissing:
            return "GoogleService-Info.plist not found or CLIENT_ID missing"
        case .configurationError:
            return "Failed to configure Google Sign-In"
        case .noIdToken:
            return "Failed to get ID token from Google Sign-In"
        }
    }
}

#if DEBUG
struct GoogleSignInView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSignInView(appState: AppStateManager()) {
            print("Sign-in completed")
        }
        .previewDevice("iPhone 15 Pro")
    }
}
#endif
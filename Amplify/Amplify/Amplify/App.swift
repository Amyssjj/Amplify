//
//  App.swift
//  Amplify
//
//  Main app entry point for Amplify - AI Communication Coach
//

import SwiftUI
import GoogleSignIn

@main
struct AmplifyApp: App {
    
    init() {
        // Configure app appearance
        configureAppearance()
        
        // Initialize any required services
        initializeServices()
        
        // Configure Google Sign-In
        configureGoogleSignIn()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Start with light mode
                .onAppear {
                    // Additional setup if needed
                }
                .onOpenURL { url in
                    // Handle Google Sign-In URL callbacks
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    // MARK: - Configuration
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Configure tab bar appearance if needed in future
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func initializeServices() {
        // Any global service initialization
        // For example, analytics, crash reporting, etc.
        
        #if DEBUG
        print("🚀 Amplify app starting in DEBUG mode")
        #endif
    }
    
    private func configureGoogleSignIn() {
        // Load Google Sign-In configuration from GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["CLIENT_ID"] as? String else {
            
            #if DEBUG
            print("⚠️ GoogleService-Info.plist not found or CLIENT_ID missing")
            print("🔧 Please add your GoogleService-Info.plist file to configure OAuth")
            #endif
            return
        }
        
        // Configure Google Sign-In with client ID
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = config
        
        #if DEBUG
        print("✅ Google Sign-In configured successfully")
        print("📱 Client ID: \(clientID)")
        #endif
    }
}

// MARK: - App Configuration Extensions

extension AmplifyApp {
    
    /// Handle app lifecycle events
    private func handleAppLifecycle() {
        // Handle app becoming active, background, etc.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App became active
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App entered background
        }
    }
}
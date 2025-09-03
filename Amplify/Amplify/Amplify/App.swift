//
//  App.swift
//  Amplify
//
//  Main app entry point for Amplify - AI Communication Coach
//

import SwiftUI

@main
struct AmplifyApp: App {
    
    init() {
        // Configure app appearance
        configureAppearance()
        
        // Initialize any required services
        initializeServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Start with light mode
                .onAppear {
                    // Additional setup if needed
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
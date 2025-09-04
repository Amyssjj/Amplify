//
//  ViewExtensions.swift
//  Amplify
//
//  Common View extensions used across the app
//

import SwiftUI

// MARK: - Navigation Positioning

extension View {
    /// Applies standard iOS navigation bar positioning
    /// - Parameter safeAreaTop: The top safe area inset
    /// - Returns: View positioned at standard navigation height
    func standardNavigationPosition(safeAreaTop: CGFloat) -> some View {
        self
            .frame(height: 44) // Standard nav bar height
            .padding(.top, safeAreaTop + 8) // Safe area + small offset for proper alignment
            .padding(.vertical, 24) 
    }
}

// Add other reusable view extensions here as your app grows
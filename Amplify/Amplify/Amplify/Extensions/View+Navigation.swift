//
//  View+Navigation.swift
//  Amplify
//
//  Navigation positioning extension for consistent UI across screens
//

import SwiftUI

extension View {
    /// Applies standard iOS navigation positioning with proper safe area handling
    /// - Parameter safeAreaTop: The safe area top inset from GeometryReader
    /// - Returns: View with consistent navigation positioning
    func standardNavigationPosition(safeAreaTop: CGFloat) -> some View {
        self.padding(.top, safeAreaTop + 8) // Safe area + standard spacing
            .frame(height: 44) // Standard iOS navigation bar height
    }
}
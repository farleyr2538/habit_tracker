//
//  MigrationErrorView.swift
//  Habit Tracker
//
//  Created by Rob Farley on 13/03/2026.
//

import SwiftUI

// Error view to show when migration fails
struct MigrationErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            
            Text("Migration Error")
                .font(.title)
                .bold()
            
            Text("We encountered an issue updating your data.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text("Please contact support or reinstall the app. Note: Reinstalling will erase your data.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
}

#Preview {
    MigrationErrorView(error: NSError(domain: "PreviewError", code: -1, userInfo: [NSLocalizedDescriptionKey: "This is a preview error message"]))
}

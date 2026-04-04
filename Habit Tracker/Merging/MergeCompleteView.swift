//
//  MergeCompleteView.swift
//  Habit Tracker
//
//  Created by Rob Farley on 01/04/2026.
//

import SwiftUI

struct MergeCompleteView: View {
    let report: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Merge Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text(report)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .padding(8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .padding(.vertical, 40)
    }
}

#Preview {
    MergeCompleteView(
        report: "Success",
        onDismiss: {}
    )
}

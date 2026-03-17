//
//  SubscriptionCardView.swift
//  Habit Tracker
//
//  Created by Rob Farley on 13/03/2026.
//

import SwiftUI

struct SubscriptionCard: View {
    
    enum SubscriptionPlan {
        case monthly
        case yearly
    }
    
    let plan: PaywallSheet.SubscriptionPlan
    let isSelected: Bool
    let title: String
    let price: String
    let period: String
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            
            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    
                    Text(title)
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.accent : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.accent)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                
                
                VStack(alignment: .leading) {
                    // price
                    HStack(alignment: .firstTextBaseline) {
                        Text(price)
                            .font(.system(size: 30, weight: .bold))
                        Text(period)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
 
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 2)
            )
            .overlay(alignment: .top) {
                if let badge = badge {
                    Text(badge)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.accent)
                        )
                        .offset(y: -12)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

#Preview {
    
    SubscriptionCard(
        plan: .monthly,
        isSelected: true,
        title: "Monthly",
        price: "£1.99",
        period: "/mo",
        badge: nil,
        action: {}
    )
}

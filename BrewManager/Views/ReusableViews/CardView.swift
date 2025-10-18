//
//  CardView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 17/10/2025.
//

import SwiftUI

struct CardView: View {
    let title: String
    let value: String
    let icon: Image?
    let actionIcon: Image?
    let disabled: Bool
    let action: (() -> Void)?

    
    init(title: String, value: String, icon: Image?,  actionIcon: Image?, disabled: Bool = false, action: (() -> Void)?) {
        self.title = title
        self.value = value
        self.icon = icon
        self.action = action
        self.actionIcon = actionIcon
        self.disabled = disabled
    }
    
    init(title: String, value: String, icon: Image? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.action = nil
        self.actionIcon = nil
        self.disabled = false
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40, alignment: .leading)
                        .padding([.leading, .trailing, .top])
                    
                }
                Spacer()
                if let action, let actionIcon {
                    if disabled {
                        ProgressView()
                            .scaleEffect(0.6)
                            .padding([.trailing, .top])
                    } else {
                        Button(action: action) {
                            actionIcon
                        }
                        .buttonStyle(.borderless)
                        .disabled(disabled)
                        .padding([.trailing, .top])
                    }
                }
                
            }
            Text(title)
                .font(.title3)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .padding([.leading, .trailing, .top])
            Text(value)
                .lineLimit(1)
                .font(.title)
                .foregroundStyle(.primary)
                .padding([.leading, .trailing, .bottom])
        }
        .glassEffect(in: .rect(cornerRadius: 16))
        .frame(maxWidth: 200)
        
    }
}

#Preview {
    CardView(title: "Homebrew Version", value: "3.29.2", icon: Image("homebrew"))
}

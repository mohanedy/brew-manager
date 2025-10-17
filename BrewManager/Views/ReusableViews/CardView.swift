//
//  CardView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 17/10/2025.
//

import SwiftUI

struct CardView: View {
    var body: some View {
        VStack {
            Text("Card View")
                .font(.title)
                .padding()
            Text("This is a reusable card view component.")
                .font(.body)
                .padding([.leading, .trailing, .bottom])
        }
        .glassEffect()
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

#Preview {
    CardView()
}

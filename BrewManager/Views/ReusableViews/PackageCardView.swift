//
//  PackageCardView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 25/10/2025.
//

import SwiftUI

struct PackageCardView: View {
    let package: BrewPackage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(package.name)
                .font(.headline)
                .lineLimit(1)
            Text(package.description ?? "No description available.")
                .font(.subheadline)
                .lineLimit(2)
        }
        .frame(width: 200, height: 150)
        .padding()
        .background(Color(.systemFill))
        .cornerRadius(10)

    }
}

#Preview {
    PackageCardView(package: BrewPackage(fromCask: BrewCaskInfo(
        token: "example",
        name: ["Example App"],
        homepage: "https://example.com",
        installed: "1.0.0",
        version: "1.2.0",
        desc: "An example application.",
        tap: "homebrew/cask"
    )))
}

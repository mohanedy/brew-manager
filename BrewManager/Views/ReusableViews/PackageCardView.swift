//
//  PackageCardView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 25/10/2025.
//

import SwiftUI

struct PackageCardView: View {
    let package: BrewPackage
    
    var isInstalled : Bool {
        return package.version != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(package.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(package.isCask ? "Cask" : "Formula")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(package.isCask ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .foregroundColor(package.isCask ? .blue : .green)
                    .cornerRadius(6)
            }
            Text("Version: \(package.latestVersion ?? "Unknown")" )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(package.description ?? "No description available.")
                .font(.subheadline)
                .lineLimit(2)
            Spacer()
            HStack {
                Spacer()
                Button {
                    
                } label: {
                    Text("\(isInstalled ? "Installed" : "Install")")
                        .font(.subheadline)
                }
                .buttonStyle(.glassProminent)
                .disabled(isInstalled)
                .accessibility(label: Text("Install \(package.name)"))
                
                
            }
        }
        .frame(width: 180, height: 150, alignment: .leading)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
        
    }
}

#Preview {
    PackageCardView(package: BrewPackage(fromCask: BrewCaskInfo(
        token: "example",
        name: ["Example App"],
        homepage: "https://example.com",
        installed: nil,
        version: "1.2.0",
        desc: "An example application lorem ipsum dolor sit amet. Consectetur adipiscing elit.",
        tap: "homebrew/cask"
    )))
}

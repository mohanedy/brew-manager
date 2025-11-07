//
//  AboutView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 24/10/2025.
//

import SwiftUI

struct AboutView: View {
    @State private var isAnimating = false
    
    var body: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        VStack(alignment: .center, spacing: 20) {
            Image("AppDefaultIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .rotationEffect(.degrees(isAnimating ? 0 : -180))
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            Text("BrewManager")
                .font(.largeTitle)
                .fontWeight(.bold)
            VStack {
                Text("Version \(appVersion ?? "") Build \(buildNumber ?? "")")
                    .font(.title3)
                    .padding(.top, 10)
                Divider()
                Text("BrewManager is an open-source macOS application designed to help you manage your Homebrew packages with ease. It provides a user-friendly interface to install, update, and remove formulae & Casks.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Divider()
                Link("GitHub repository", destination: URL(string: "https://github.com/mohanedy/brew-manager")!)
                    .font(.body)
                Link("Report a bug", destination: URL(string: "https://github.com/mohanedy/brew-manager/issues/new")!)
                    .font(.body)
                Divider()
                Text("© 2025 mohanedy. All rights reserved.")
                    .font(.body)
                    .padding(.vertical, 10)
                    .foregroundColor(.secondary)
            }
            .glassEffect(in: .rect(cornerRadius: 16))
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)
        }
        .navigationTitle("About")
    }
}

#Preview {
    AboutView()
}

//
//  PackageCardView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 25/10/2025.
//

import SwiftUI

struct PackageCardView: View {
    let packageState: PackageState
    let installTapAction: ((Bool) -> Void)?
    
    var isInstalled : Bool {
        return package.version != nil
    }
    
    var package: BrewPackage {
        return packageState.package
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(package.isCask ? package.token! : package.name)
                    .textSelection(.enabled)
                    .font(.headline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
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
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack {
                if package.homepage != nil {
                    Button {
                        if let url = URL(string: package.homepage ?? "") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "safari")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color(.linkColor))
                }
                Spacer()
                if packageState.status == .idle {
                    Button {
                        if let installTapAction, !isInstalled {
                            installTapAction(false)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(isInstalled ? "Installed" : "Install")")
                                .font(.subheadline)
                            if(!isInstalled) {
                                Menu {
                                    Button("Force Install") {
                                        installTapAction?(true)
                                    }
                                } label: {
                                    EmptyView()
                                }
                                .menuStyle(.borderlessButton)
                                .padding(0)
                            }
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(isInstalled)
                    .accessibility(label: Text("Install \(package.name)"))
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                
                if packageState.status == .loading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 20, height: 20)
                        .transition(.opacity.combined(with: .scale(scale: 0.5)))
                }
                
                if packageState.status == .success() {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Installed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: packageState.status)
        }
        .help("\(package.name)\n\n\(package.description ?? "No description available.")")
        .frame(width: 180, height: 150, alignment: .leading)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
        
        
    }
}

#Preview {
    PackageCardView(
        packageState: PackageState(
            package: BrewPackage(
                fromCask: BrewCaskInfo(
                    token: "github-copilot-for-xcode",
                    name: ["GitHub Copilot for Xcode"],
                    homepage: "https://example.com",
                    installed: nil,
                    version: "1.2.0",
                    desc: "An example application lorem ipsum dolor sit amet. Consectetur adipiscing elit.",
                    tap: "homebrew/cask"
                )),
            status: .idle
        ),
        installTapAction: nil
    )
}

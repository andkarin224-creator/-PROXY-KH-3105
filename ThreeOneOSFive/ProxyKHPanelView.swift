import SwiftUI

struct ProxyKHPanelView: View {
    @State private var selectedTab = 0
    @State private var filesTabSession = FilesTabSession()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                homeView
                    .tabItem {
                        Label("HOME", systemImage: "house.fill")
                    }
                    .tag(0)

                AppDataBrowserView(
                    tabSession: $filesTabSession
                )
                .tabItem {
                    Label("FILES", systemImage: "folder.fill")
                }
                .tag(1)

                PatchProjectsView()
                    .tabItem {
                        Label("PATCH", systemImage: "wrench.and.screwdriver.fill")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("SETTINGS", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(.red)
        }
        .preferredColorScheme(.dark)
    }

    private var homeView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(.red)

                    Text("PROXY KH")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)

                    Text("3105 SYSTEM")
                        .font(.headline)
                        .foregroundStyle(.gray)

                    Text("FILE MANAGEMENT • PATCH • SETTINGS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)

                    VStack(spacing: 12) {
                        panelButton(
                            title: "APP DATA",
                            subtitle: "จัดการไฟล์และข้อมูลแอป",
                            icon: "folder.fill"
                        ) {
                            selectedTab = 1
                        }

                        panelButton(
                            title: "PATCH PROJECTS",
                            subtitle: "จัดการโปรเจกต์ Patch ของ 3105",
                            icon: "wrench.and.screwdriver.fill"
                        ) {
                            selectedTab = 2
                        }

                        panelButton(
                            title: "SETTINGS",
                            subtitle: "ตั้งค่าระบบ 3105",
                            icon: "gearshape.fill"
                        ) {
                            selectedTab = 3
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .navigationTitle("PROXY KH")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func panelButton(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
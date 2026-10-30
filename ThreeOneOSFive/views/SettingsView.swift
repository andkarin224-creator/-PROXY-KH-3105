
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    @AppStorage(AppLanguage.storageKey)
    private var languageCode = AppLanguage.english.rawValue

    @AppStorage(FeatureVisibility.cleanerStorageKey)
    private var cleanerEnabled = true

    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                // HEADER
                Section {
                    HStack(spacing: 14) {
                        AppLogo()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("KHEWIN STORE")
                                .font(.headline)

                            Text("ONLINE • Version 1.1.5")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }

                // TRIAL MEMBER
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "hourglass")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("ทดลองใช้งาน")
                                .font(.headline)

                            Text("ขณะนี้เป็นตัวทดลองใช้งาน ยังไม่เชื่อมต่อ License")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("สมาชิก KH STORE")
                }

                // LANGUAGE
                Section {
                    Picker("ภาษา", selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName)
                                .tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("ภาษา")
                }

                // FEATURES
                Section {
                    Toggle(isOn: $cleanerEnabled) {
                        Label(
                            language.text("tab.cleaner"),
                            systemImage: "sparkles"
                        )
                    }

                    Toggle(isOn: $developerModeEnabled) {
                        Label(
                            language.text("settings.developer_mode"),
                            systemImage: "hammer.fill"
                        )
                    }
                } header: {
                    Text("ฟังก์ชัน")
                } footer: {
                    Text(language.text("settings.developer_mode_footer"))
                }

                // WALLPAPER
                if WallpaperFeatureSupportPolicy.isSupported(
                    major: AppInfo.versionTuple.major
                ) {
                    Section {
                        NavigationLink {
                            WallpaperResetSettingsView()
                        } label: {
                            Label(
                                language.text("wallpaper.reset"),
                                systemImage: "arrow.counterclockwise"
                            )
                        }
                    } header: {
                        Text("วอลเปเปอร์")
                    } footer: {
                        Text(language.text("wallpaper.reset_settings_footer"))
                    }
                }

                // DEVICE
                Section {
                    LabeledContent(
                        "รุ่นอุปกรณ์",
                        value: AppInfo.displayMachineName
                    )

                    LabeledContent(
                        "เวอร์ชัน iOS",
                        value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                    )

                    LabeledContent(
                        "สถานะระบบ",
                        value: appState.isSupported ? "รองรับ" : "ไม่รองรับ"
                    )
                    .foregroundStyle(
                        appState.isSupported ? Color.green : Color.red
                    )
                } header: {
                    Text("ข้อมูลอุปกรณ์")
                }

                // VERIFIED IOS
                Section {
                    LabeledContent(
                        "iOS 17",
                        value: ExploitSupportPolicy.verifiedIOS17Range
                    )

                    LabeledContent(
                        "iOS 18",
                        value: ExploitSupportPolicy.verifiedIOS18Range
                    )

                    LabeledContent(
                        "iOS 26",
                        value: ExploitSupportPolicy.verifiedIOS26Range
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("iOS 27.0")
                            .font(.body)

                        ForEach(
                            ExploitSupportPolicy.verifiedIOS27Builds,
                            id: \.build
                        ) { version in
                            Text(versionLabel(version))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("เวอร์ชัน iOS ที่ตรวจสอบแล้ว")
                } footer: {
                    Text(
                        language.text(
                            "settings.supported_versions_footer"
                        )
                    )
                }

                // ABOUT
                Section {
                    LabeledContent(
                        "ชื่อแอป",
                        value: "KHEWIN STORE"
                    )

                    LabeledContent(
                        "เวอร์ชัน",
                        value: "1.1.5"
                    )

                    Text("KH STORE PREMIUM CONTROL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("เกี่ยวกับแอป")
                }

                // SOCIAL MEDIA
                Section {
                    creditsRow(
                        name: "GitHub",
                        role: language.text("social.github_role"),
                        url: "https://github.com/YangJiiii/3105"
                    )

                    creditsRow(
                        name: "Cộng Đồng IOSVN",
                        role: language.text("social.iosvn_role"),
                        url: "https://t.me/ioscrackvn"
                    )
                } header: {
                    Text(language.text("settings.social_media"))
                }

                // CREDITS
                Section {
                    creditsRow(
                        name: "YangJiii",
                        role: language.text("credit.yangjiii"),
                        url: "https://x.com/duongduong0908"
                    )

                    creditsRow(
                        name: "0xjohnnydev",
                        role: language.text("credit.filzaslop"),
                        url: "https://github.com/0xjohnnydev/FilzaSlop"
                    )

                    creditsRow(
                        name: "LeminLimez",
                        role: language.text("credit.pocket_poster"),
                        url: "https://github.com/leminlimez/Pocket-Poster"
                    )

                    creditsRow(
                        name: "CrazyMind90",
                        role: language.text("credit.sandbox_escape"),
                        url: "https://github.com/CrazyMind90"
                    )

                    creditsRow(
                        name: "forcequitOS",
                        role: language.text("credit.forcequit"),
                        url: "https://github.com/forcequitOS"
                    )
                } header: {
                    Text(language.text("settings.credits"))
                }

                // FOOTER
                Section {
                    VStack(spacing: 8) {
                        Text("KH STORE")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("PLAY A BETTER TOMORROW")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .tint(AppTheme.accent)
            .navigationTitle("ตั้งค่า KH STORE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }

        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }

    @ViewBuilder
    private func creditsRow(
        name: String,
        role: String,
        url: String
    ) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(
                language.text("accessibility.open_profile", name)
            )
        }
    }
}

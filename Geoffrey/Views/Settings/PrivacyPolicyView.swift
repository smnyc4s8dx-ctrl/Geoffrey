import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title2.bold())

                Text("Effective Date: March 24, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    section(
                        title: "Data Storage",
                        body: "Geoffrey stores all data — projects, worlds, characters, locations, lore cards, and dialogue sessions — locally on your device using Apple's SwiftData framework. No data is transmitted to external servers operated by Aeon Digital or any third party."
                    )

                    section(
                        title: "Network Connections",
                        body: "Geoffrey connects only to a local LLM server (such as LM Studio) that you configure and run on your own machine. These connections are made to a server address you specify, typically localhost (127.0.0.1). Geoffrey does not connect to any remote AI service, analytics platform, or telemetry endpoint."
                    )

                    section(
                        title: "Data Collection",
                        body: "Geoffrey does not collect, transmit, or share any personal information. There are no user accounts, no analytics, no crash reporting, and no usage tracking of any kind."
                    )

                    section(
                        title: "Third-Party Services",
                        body: "Geoffrey does not integrate with any third-party services. The local LLM server you connect to is software you install and operate independently."
                    )

                    section(
                        title: "Data Deletion",
                        body: "All data is stored in your local application container. To delete all Geoffrey data, simply delete the application. You can also delete individual projects, worlds, and sessions from within the app."
                    )

                    section(
                        title: "Children's Privacy",
                        body: "Geoffrey is a creative writing tool rated 12+. It does not collect any data from users of any age."
                    )

                    section(
                        title: "Changes to This Policy",
                        body: "Any changes to this privacy policy will be included in app updates. The effective date above will be updated accordingly."
                    )

                    section(
                        title: "Contact",
                        body: "For questions about this privacy policy, contact the developer through the App Store."
                    )
                }
            }
            .padding()
        }
        .frame(minWidth: 360, idealWidth: 480)
        .frame(minHeight: 300)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

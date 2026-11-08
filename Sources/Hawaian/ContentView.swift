import SwiftUI

struct ContentView: View {
    @State private var selectedIntent: ConversationIntent = .everyday
    @State private var isListening = false
    @State private var selectedLanguage = "English"
    @State private var selectedReply: ReplySuggestion?
    @State private var showIntentPicker = false
    @State private var showSettings = false

    private let languages = ["English", "日本語", "한국어", "Español", "Français"]

    var body: some View {
        ZStack {
            HawaianBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    languageBar
                    visualizerSection
                    intentSection
                    replySection
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showIntentPicker) {
            intentSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HAWAIAN")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.62))
                Text("Speak freely.")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .tracking(-1.2)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .glassEffect(.regular, in: Circle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var languageBar: some View {
        HStack(spacing: 10) {
            languagePill("Auto", icon: "waveform")
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Menu {
                ForEach(languages, id: \.self) { language in
                    Button(language) { selectedLanguage = language }
                }
            } label: {
                HStack(spacing: 7) {
                    Text(selectedLanguage)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: Capsule())
            }
            Spacer(minLength: 0)
        }
    }

    private func languagePill(_ title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
    }

    private var visualizerSection: some View {
        VStack(spacing: 18) {
            SiriOrbView(isActive: isListening)
                .frame(height: 224)
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Text(isListening ? "Listening to the moment" : "Your conversations, understood")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(isListening ? "Hawaian is ready for the next voice." : "A quieter, smarter way to connect.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Button {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.72)) {
                    isListening.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isListening ? "pause.fill" : "waveform")
                        .font(.system(size: 14, weight: .bold))
                    Text(isListening ? "Pause session" : "Start listening")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black.opacity(0.88))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    LinearGradient(colors: [Color.white, Color(red: 0.78, green: 0.88, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .shadow(color: .cyan.opacity(0.18), radius: 24, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.24), .white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
    }

    private var intentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONVERSATION INTENT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.2)
                        .foregroundStyle(.white.opacity(0.48))
                    Text(selectedIntent.title)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button("Change") { showIntentPicker = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.cyan.opacity(0.95))
            }

            HStack(spacing: 12) {
                Image(systemName: selectedIntent.symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.cyan)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedIntent.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Text(selectedIntent.guidance)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(15)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var replySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SMART REPLY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(.white.opacity(0.48))
                Spacer()
                Text("CONCEPT PREVIEW")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.orange.opacity(0.9))
            }

            Text("How would you like to respond?")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            ForEach(ReplySuggestion.examples) { reply in
                Button {
                    selectedReply = reply
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedReply?.id == reply.id ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(selectedReply?.id == reply.id ? .cyan : .white.opacity(0.36))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(reply.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(reply.template)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.52))
                        }
                        Spacer()
                        if !reply.missingFields.isEmpty {
                            Text("FILL")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.cyan)
                        }
                    }
                    .padding(14)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
            Text("Designed for private, intentional conversations.")
        }
        .font(.system(size: 11))
        .foregroundStyle(.white.opacity(0.38))
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }


    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Translation") {
                    Picker("Translate into", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                }
                Section("Hawaian") {
                    Label("Earbud-first conversation assistant", systemImage: "airpodspro")
                    Text("The animated orb is Hawaian's own voice visualizer. Siri and Apple Intelligence features will be connected only through public APIs supported by the device and language.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Privacy") {
                    Label("Microphone access is requested only when live listening is implemented and started.", systemImage: "lock.shield")
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var intentSheet: some View {
        NavigationStack {
            List {
                ForEach(ConversationIntent.allCases) { intent in
                    Button {
                        selectedIntent = intent
                        showIntentPicker = false
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: intent.symbol)
                                .frame(width: 28)
                                .foregroundStyle(.cyan)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(intent.title).foregroundStyle(.primary)
                                Text(intent.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedIntent == intent {
                                Image(systemName: "checkmark").foregroundStyle(.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Conversation intent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showIntentPicker = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct HawaianBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.035, blue: 0.075)
            RadialGradient(colors: [Color.blue.opacity(0.25), .clear], center: .topTrailing, startRadius: 10, endRadius: 390)
            RadialGradient(colors: [Color.purple.opacity(0.19), .clear], center: .center, startRadius: 20, endRadius: 330)
            LinearGradient(colors: [.clear, Color.black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

private struct SiriOrbView: View {
    let isActive: Bool
    @State private var phase = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.08))
                .frame(width: 190, height: 190)
                .blur(radius: 34)
                .scaleEffect(phase ? 1.22 : 0.88)

            ForEach(0..<3) { index in
                Circle()
                    .stroke(.white.opacity(0.09 - Double(index) * 0.018), lineWidth: 1)
                    .frame(width: CGFloat(142 + index * 34), height: CGFloat(142 + index * 34))
                    .scaleEffect(phase ? 1.035 : 0.965)
            }

            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(red: 0.24, green: 0.88, blue: 1),
                                Color(red: 0.45, green: 0.48, blue: 1),
                                Color(red: 0.87, green: 0.42, blue: 0.94),
                                Color(red: 1, green: 0.58, blue: 0.76),
                                Color(red: 0.24, green: 0.88, blue: 1)
                            ],
                            center: .center,
                            angle: .degrees(phase ? 250 : 35)
                        )
                    )
                    .frame(width: 112, height: 112)
                    .blur(radius: 1)

                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 84, height: 84)
                    .blur(radius: 16)
                    .offset(x: -15, y: -17)

                Circle()
                    .fill(.black.opacity(0.16))
                    .frame(width: 74, height: 74)
                    .blur(radius: 13)
                    .offset(x: 18, y: 16)

                Circle()
                    .stroke(.white.opacity(0.34), lineWidth: 0.8)
                    .frame(width: 110, height: 110)
            }
            .shadow(color: .cyan.opacity(phase ? 0.45 : 0.2), radius: isActive ? 34 : 22)
            .scaleEffect(isActive ? (phase ? 1.12 : 0.94) : (phase ? 1.035 : 0.97))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: isActive ? 0.85 : 2.8).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
        .onChange(of: isActive) { _, active in
            withAnimation(.easeInOut(duration: active ? 0.55 : 2.8).repeatForever(autoreverses: true)) {
                phase.toggle()
            }
        }
        .accessibilityLabel(isActive ? "Hawaian voice visualizer active" : "Hawaian voice visualizer idle")
    }
}

#Preview {
    ContentView()
}

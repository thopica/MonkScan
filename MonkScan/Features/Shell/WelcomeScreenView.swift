import SwiftUI

struct WelcomeScreenView: View {
    @State private var visibleCharacters: Int = 0
    @State private var characterOpacities: [Double] = Array(repeating: 0, count: 8)
    @State private var timer: Timer?
    
    var onAnimationComplete: () -> Void
    
    private let appName = "MonkScan"
    private let typingInterval: TimeInterval = 0.12
    private let holdDuration: TimeInterval = 1.2
    
    var body: some View {
        ZStack {
            // Yellow background
            Color("LaunchBackground")
                .ignoresSafeArea()
            
            // Animated characters
            HStack(spacing: 0) {
                ForEach(Array(appName.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(NBColors.ink)
                        .opacity(characterOpacities[index])
                        .scaleEffect(characterOpacities[index] > 0 ? 1.0 : 0.5)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7),
                            value: characterOpacities[index]
                        )
                }
            }
        }
        .onAppear {
            startTypewriterAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTypewriterAnimation() {
        // Small initial delay before typing starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            timer = Timer.scheduledTimer(withTimeInterval: typingInterval, repeats: true) { t in
                if visibleCharacters < appName.count {
                    withAnimation {
                        characterOpacities[visibleCharacters] = 1.0
                    }
                    visibleCharacters += 1
                } else {
                    t.invalidate()
                    // Hold then complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                        onAnimationComplete()
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeScreenView(onAnimationComplete: {})
}


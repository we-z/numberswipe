import SwiftUI
import AVFoundation

let hapticManager = HapticManager.instance

struct ContentView: View {
    @State private var currentPower = 1
    @State private var centerNumber = 2
    @State private var topNumber = 4
    @State private var bottomNumber = 3
    @State private var isGameOver = false
    @State private var chosenDirection: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var bgColor = Color.black
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                bgColor.ignoresSafeArea()
                if isGameOver {
                    VStack {
                        Text("Game Over")
                            .foregroundColor(.white)
                            .font(.system(size: g.size.width * 0.15))
                            .padding(.bottom, 20)
                        Button {
                            reset()
                        } label: {
                            Text("Reset")
                                .foregroundColor(.white)
                                .font(.system(size: g.size.width * 0.07))
                                .padding()
                                .padding(.horizontal)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(g.size.width * 0.03)
                        }
                        
                    }
                } else {
                    VStack {
                        // Top number
                        Text("\(topNumber)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.01)
                            .foregroundColor(.white)
                            .font(.system(size: g.size.height * 0.15))
                            .padding(.horizontal, g.size.width * 0.15)
                        Spacer()
                        // Center number
                        Text("\(centerNumber)")
                            .minimumScaleFactor(0.01)
                            .foregroundColor(.white)
                            .font(.system(size: g.size.height * 0.6))
                            .scaleEffect(scale)
                            .offset(y: chosenDirection * (g.size.height / 2.0))
                            
                        Spacer()
                        // Bottom number
                        Text("\(bottomNumber)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.01)
                            .foregroundColor(.white)
                            .font(.system(size: g.size.height * 0.15))
                            .padding(.horizontal, g.size.width * 0.15)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 21)
                    .onEnded { val in
                        if abs(val.translation.height) > abs(val.translation.width) && !isGameOver {
                            swipe(val.translation.height < 0, g)
                        }
                    }
            )
        }
    }
    
    func swipe(_ up: Bool, _ g: GeometryProxy) {
        withAnimation(.easeIn(duration: 0.2)) {
            chosenDirection = up ? -1 : 1
            scale = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            checkAnswer(correct: (up && topNumber == nextPower()) || (!up && bottomNumber == nextPower()))
        }
    }
    
    func checkAnswer(correct: Bool) {
        if correct {
            hapticManager.notification(type: .success)
            flash(color: .blue)
            currentPower += 1
            centerNumber = Int(pow(2, Double(currentPower)))
            setNewNumbers()
        } else {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
            flash(color: .red)
            isGameOver = true
        }
        chosenDirection = 0
        scale = 1
    }
    
    func nextPower() -> Int {
        return Int(pow(2, Double(currentPower+1)))
    }
    
    func setNewNumbers() {
        let correctVal = nextPower()
        let offset = Int.random(in: 1...max(3,currentPower))
        let incorrectVal = Bool.random() ? correctVal + offset : max(1, correctVal - offset)
        if Bool.random() {
            topNumber = correctVal
            bottomNumber = incorrectVal
        } else {
            topNumber = incorrectVal
            bottomNumber = correctVal
        }
    }
    
    func reset() {
        hapticManager.notification(type: .error)
        bgColor = .black
        currentPower = 1
        centerNumber = 2
        isGameOver = false
        setNewNumbers()
    }
    
    func flash(color: Color) {
        bgColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            bgColor = .black
        }
    }
}

class HapticManager {
    static let instance = HapticManager()
    private init() {}

    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    ContentView()
}

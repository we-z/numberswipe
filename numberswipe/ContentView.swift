import SwiftUI
import AVFoundation

let hapticManager = HapticManager.instance
let impactLight = UIImpactFeedbackGenerator(style: .light)

struct ContentView: View {
    @State private var currentPower = 1
    @State private var centerNumber = "2" {
        didSet {
            // Compare centerNumber with bestScore as strings to handle large numbers
            if compareLargeNumbers(centerNumber, bestScore) > 0 {
                bestScore = centerNumber
            }
      }
    }
    @State private var topNumber = "4"
    @State private var bottomNumber = "3"
    @AppStorage("bestScore") var bestScore: String = "0"
    @State private var isGameOver = false
    @State private var chosenDirection: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var bgColor = Color.black
    
    @StateObject private var storeKitManager = StoreKitManager()
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                bgColor.ignoresSafeArea()
                    .background(.gray.opacity(0.0001))
                    .onTapGesture {
                        if isGameOver{
                            reset()
                        }
                    }
                if isGameOver {
                    VStack {
                        HStack {
                            Button {
                                impactLight.impactOccurred()
                                Task {
                                        do {
                                            if let transaction = try await storeKitManager.purchase() {
                                                // Handle successful purchase
                                                print("Purchase successful: \(transaction)")
                                            }
                                        } catch {
                                            // Handle errors
                                            print("Purchase failed: \(error)")
                                        }
                                    }
                            } label: {
                                Text("Tip $2")
                                    .bold()
                                    .font(.system(size: g.size.height * 0.025))
                                    .foregroundColor(.white)
                                    .padding(g.size.height * 0.01)
                                    .padding(.horizontal, g.size.height * 0.01)
                                    .background(.blue)
                                    .cornerRadius(g.size.height * 0.01)
                                    .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                        Text("Best")
                            .font(.system(size: g.size.height * 0.05))
                            .foregroundColor(.gray)
                        ZStack {
                            Text("0")
                                .font(.system(size: g.size.height * 0.1))
                                .foregroundColor(.clear)
                            Text(insertCommas(bestScore))
                                .lineLimit(1)
                                .minimumScaleFactor(0.01)
                                .font(.system(size: g.size.height * 0.08))
                                .foregroundColor(.white)
                                .padding(.horizontal, g.size.width * 0.15)
                        }
                            
                        Text("Score")
                            .font(.system(size: g.size.height * 0.05))
                            .foregroundColor(.gray)
                        ZStack {
                            Text("0")
                                .font(.system(size: g.size.height * 0.1))
                                .foregroundColor(.clear)
                            Text(insertCommas(centerNumber))
                                .lineLimit(1)
                                .minimumScaleFactor(0.01)
                                .font(.system(size: g.size.height * 0.08))
                                .foregroundColor(.white)
                                .padding(.horizontal, g.size.width * 0.15)
                        }
                        Spacer()
                        Text("Game Over")
                            .foregroundColor(.white)
                            .font(.system(size: g.size.height * 0.08))
                            .padding(.bottom)
                            .allowsHitTesting(false)
                        Text("Tap To Restart")
                            .foregroundColor(.gray)
                            .font(.system(size: g.size.height * 0.05))
                            .padding(.bottom)
                            .allowsHitTesting(false)
                        Spacer()
                        
                    }
                } else {
                    VStack {
                        Spacer()
                        // Top number
                        Text(insertCommas(topNumber))
                            .lineLimit(1)
                            .minimumScaleFactor(0.01)
                            .foregroundColor(.gray)
                            .font(.system(size: g.size.height * 0.15))
                            .padding(.horizontal, g.size.width * 0.15)
                        Spacer()
                        // Center number
                        Text(insertCommas(centerNumber))
                            .minimumScaleFactor(0.01)
                            .foregroundColor(.white)
                            .font(.system(size: g.size.height * 0.6))
                            .scaleEffect(scale)
                            .offset(y: chosenDirection * (g.size.height / 3.0))
                            
                        Spacer()
                        // Bottom number
                        Text(insertCommas(bottomNumber))
                            .lineLimit(1)
                            .minimumScaleFactor(0.01)
                            .foregroundColor(.gray)
                            .font(.system(size: g.size.height * 0.15))
                            .padding(.horizontal, g.size.width * 0.15)
                        Spacer()
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
    
    func insertCommas(_ numberString: String) -> String {
        guard numberString.count > 3 else { return numberString }
        
        var result = ""
        let reversed = Array(numberString.reversed())
        
        for (index, digit) in reversed.enumerated() {
            result.insert(digit, at: result.startIndex)
            if (index + 1) % 3 == 0 && index < reversed.count - 1 {
                result.insert(",", at: result.startIndex)
            }
        }
        
        return result
    }
    
    // Helper function to compare large numbers represented as strings
        func compareLargeNumbers(_ num1: String, _ num2: String) -> Int {
            // Remove commas if present
            let cleanNum1 = num1.replacingOccurrences(of: ",", with: "")
            let cleanNum2 = num2.replacingOccurrences(of: ",", with: "")
            
            // Compare lengths first
            if cleanNum1.count > cleanNum2.count {
                return 1
            } else if cleanNum1.count < cleanNum2.count {
                return -1
            }
            
            // If lengths are same, compare lexicographically
            return cleanNum1.compare(cleanNum2).rawValue
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
            centerNumber = String(format: "%.0f", pow(2, Double(currentPower)))
            setNewNumbers()
        } else {
//            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
            hapticManager.notification(type: .error)
            flash(color: .red)
            isGameOver = true
        }
        chosenDirection = 0
        scale = 1
    }
    
    func nextPower() -> String {
        return String(format: "%.0f", pow(2, Double(currentPower+1)))
    }

    
    func setNewNumbers() {
        let correctVal = nextPower()
        var chars = Array(correctVal)
        guard chars.count > 2 else { // If number is only one or two digits, just increment or decrement middle as needed
            let val = Int(correctVal) ?? 2
            let inc = Bool.random() ? val + 1 : val - 1
            assignNumbers(correct: correctVal, incorrect: String(max(1, inc)))
            return
        }
        
        var differenceMade = false
        for i in 1..<chars.count-1 {
            if Bool.random() {
                let d = Int(String(chars[i]))!
                let offset = [-1,0,1].randomElement()!
                if offset != 0 {
                    var newD = d + offset
                    if newD < 0 { newD = d+1 }
                    if newD > 9 { newD = d-1 }
                    if newD != d {
                        chars[i] = Character("\(newD)")
                        differenceMade = true
                    }
                }
            }
        }
        if !differenceMade { // ensure at least one difference
            let i = Int.random(in: 1..<chars.count-1)
            let d = Int(String(chars[i]))!
            chars[i] = Character("\(d == 9 ? d-1 : d+1)")
        }
        let incorrectVal = String(chars)
        assignNumbers(correct: correctVal, incorrect: incorrectVal)
    }

    func assignNumbers(correct: String, incorrect: String) {
        if Bool.random() {
            topNumber = correct
            bottomNumber = incorrect
        } else {
            topNumber = incorrect
            bottomNumber = correct
        }
    }
    
    
    
    func reset() {
        impactLight.impactOccurred()
        bgColor = .black
        currentPower = 1
        centerNumber = "2"
        isGameOver = false
        setNewNumbers()
    }
    
    func flash(color: Color) {
        bgColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                bgColor = .black
            }
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

import SwiftUI

struct ContentView: View {
    @State private var currentPower = 1
    @State private var centerNumber = "2" { didSet { if compareLargeNumbers(centerNumber, bestScore) > 0 { bestScore = centerNumber } } }
    @State private var topNumber = "4"
    @State private var bottomNumber = "3"
    @AppStorage("bestScore") var bestScore: String = "2"
    @State private var isGameOver = false
    @State private var chosenDirection: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var bgColor = Color.black
    @StateObject private var storeKitManager = StoreKitManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        GeometryReader { g in
            ZStack {
                bgColor.ignoresSafeArea().background(.gray.opacity(0.0001)).onTapGesture { if isGameOver { reset() } else { shakeCenterNumber()} }
                if isGameOver {
                    VStack {
                        HStack {
                            Button {
                                impactLight.impactOccurred()
                                Task { do { if let transaction = try await storeKitManager.purchase() { print("Purchase successful: \(transaction)") } } catch { print("Purchase failed: \(error)") } }
                            } label: {
                                Text("Tip $2").bold().font(.system(size: g.size.height * 0.025)).foregroundColor(.white).padding(g.size.height * 0.01).padding(.horizontal, g.size.height * 0.01).background(.blue).cornerRadius(g.size.height * 0.01).padding()
                            }
                            Spacer()
                        }
                        VStack {
                            Spacer()
                            Text("Best").font(.system(size: g.size.height * 0.05)).foregroundColor(.gray).allowsHitTesting(false)
                            ZStack {
                                Text("0").font(.system(size: g.size.height * 0.1)).foregroundColor(.clear)
                                Text(insertCommas(bestScore)).lineLimit(1).minimumScaleFactor(0.01).font(.system(size: g.size.height * 0.08)).foregroundColor(.white).padding(.horizontal, g.size.width * 0.15)
                            }.allowsHitTesting(false)
                            Text("Score").font(.system(size: g.size.height * 0.05)).foregroundColor(.gray).allowsHitTesting(false)
                            ZStack {
                                Text("0").font(.system(size: g.size.height * 0.1)).foregroundColor(.clear)
                                Text(insertCommas(centerNumber)).lineLimit(1).minimumScaleFactor(0.01).font(.system(size: g.size.height * 0.08)).foregroundColor(.white).padding(.horizontal, g.size.width * 0.15)
                            }.allowsHitTesting(false)
                            Spacer()
                            Text("Game Over").foregroundColor(.white).font(.system(size: g.size.height * 0.08)).padding(.bottom).allowsHitTesting(false)
                            Text("Tap To Restart").foregroundColor(.gray).font(.system(size: g.size.height * 0.05)).padding(.bottom).allowsHitTesting(false)
                            Spacer()
                        }.scaleEffect(scale)
                    }
                } else {
                    VStack {
                        Spacer()
                        Text(insertCommas(topNumber)).lineLimit(1).minimumScaleFactor(0.01).foregroundColor(.gray).font(.system(size: g.size.height * 0.15)).padding(.horizontal, g.size.width * 0.15).allowsHitTesting(false)
                        Spacer()
                        Text(insertCommas(centerNumber)).minimumScaleFactor(0.01).foregroundColor(.white).font(.system(size: g.size.height * 0.6)).scaleEffect(scale).offset(y: chosenDirection * (g.size.height / 3.0)).allowsHitTesting(false)
                        Spacer()
                        Text(insertCommas(bottomNumber)).lineLimit(1).minimumScaleFactor(0.01).foregroundColor(.gray).font(.system(size: g.size.height * 0.15)).padding(.horizontal, g.size.width * 0.15).allowsHitTesting(false)
                        Spacer()
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        // val.translation.height is how far the user has dragged vertically
                        let drag = val.translation.height
                        let optionDistance: CGFloat = g.size.height / 4
                        
                        // Offset direction: negative for up, positive for down.
                        // This fraction helps ensure the offset doesn't get too large.
                        // For example, dividing by 200 can be tuned as needed.
                        if abs(drag) < optionDistance  {
                            chosenDirection = drag / (g.size.height / 3)
                        }
                        // Scale: You can define any function that suits your preference.
                        // E.g. shrink slightly as the user drags away from center.
                        let dragDistance = abs(drag)
                        
                        
                        
                        // Make sure it doesn't shrink below some minimum (e.g. 0.8).
                        if !isGameOver {
                            scale = max((optionDistance - dragDistance) / optionDistance, 0.1)
                        }
                    }
                    .onEnded { val in
                        // If the user has swiped far enough in one direction, evaluate their choice.
                        // Else, snap back to original size and position without checking the answer.
                        let drag = val.translation.height
                        
                        // Decide whether we consider it a valid swipe:
                        if abs(drag) > 21, !isGameOver {
                            swipe(drag < 0, g)
                        } else {
                            // Snap back
                            withAnimation(.linear(duration: 0.1)) {
                                chosenDirection = 0
                                scale = 1
                            }
                        }
                    }
            )
        }
        .onChange(of: scenePhase) { _ in
            withAnimation(.linear(duration: 0.1)) {
                chosenDirection = 0.0
                scale = 1
            }
        }
    }

    func insertCommas(_ numberString: String) -> String {
        guard numberString.count > 3 else { return numberString }
        var result = ""; let reversed = Array(numberString.reversed())
        for (index, digit) in reversed.enumerated() {
            result.insert(digit, at: result.startIndex)
            if (index + 1) % 3 == 0 && index < reversed.count - 1 { result.insert(",", at: result.startIndex) }
        }
        return result
    }

    func compareLargeNumbers(_ num1: String, _ num2: String) -> Int {
        let cleanNum1 = num1.replacingOccurrences(of: ",", with: "")
        let cleanNum2 = num2.replacingOccurrences(of: ",", with: "")
        if cleanNum1.count > cleanNum2.count { return 1 } else if cleanNum1.count < cleanNum2.count { return -1 }
        return cleanNum1.compare(cleanNum2).rawValue
    }

    func swipe(_ up: Bool, _ g: GeometryProxy) {
        withAnimation(.easeIn(duration: 0.2)) { chosenDirection = up ? -1 : 1; scale = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            checkAnswer(correct: (up && topNumber == nextPower()) || (!up && bottomNumber == nextPower()))
        }
    }
    
    func shakeCenterNumber() {
        withAnimation(.linear(duration: 0.1)) {
            chosenDirection = -0.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.1)) {
                chosenDirection = 0.1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.linear(duration: 0.1)) {
                chosenDirection = 0
            }
        }
    }

    func checkAnswer(correct: Bool) {
        if correct {
            hapticManager.notification(type: .success)
            currentPower += 1; centerNumber = String(format: "%.0f", pow(2, Double(currentPower))); setNewNumbers()
        } else {
            hapticManager.notification(type: .error); isGameOver = true
        }
        chosenDirection = 0; withAnimation(.linear(duration: 0.1)) { scale = 1 }
    }

    func nextPower() -> String { String(format: "%.0f", pow(2, Double(currentPower+1))) }

    func setNewNumbers() {
        let correctVal = nextPower()
        var chars = Array(correctVal)
        guard chars.count > 2 else {
            let val = Int(correctVal) ?? 2
            let inc = Bool.random() ? val + 2 : val - 2
            assignNumbers(correct: correctVal, incorrect: String(max(1, inc)))
            return
        }
        var differenceMade = false
        for i in 1..<chars.count-1 where Bool.random() {
            let d = Int(String(chars[i]))!
            let offset = [-1,0,1].randomElement()!
            if offset != 0 {
                var newD = d + offset
                if newD < 0 { newD = d+1 }
                if newD > 9 { newD = d-1 }
                if newD != d { chars[i] = Character("\(newD)"); differenceMade = true }
            }
        }
        if !differenceMade {
            let i = Int.random(in: 1..<chars.count-1)
            let d = Int(String(chars[i]))!
            chars[i] = Character("\(d == 9 ? d-1 : d+1)")
        }
        assignNumbers(correct: correctVal, incorrect: String(chars))
    }

    func assignNumbers(correct: String, incorrect: String) {
        if Bool.random() {
            topNumber = correct; bottomNumber = incorrect
        } else {
            topNumber = incorrect; bottomNumber = correct
        }
    }

    func reset() {
        impactLight.impactOccurred()
        currentPower = 1; centerNumber = "2"; isGameOver = false; setNewNumbers()
    }
}

#Preview { ContentView() }

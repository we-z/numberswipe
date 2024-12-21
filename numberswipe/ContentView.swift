import SwiftUI
import AVFoundation
import LinkPresentation

struct ContentView: View {
    @State private var currentPower = 1
    @State private var centerNumber = "2" { didSet { if compareLargeNumbers(centerNumber, bestScore) > 0 { bestScore = centerNumber } } }
    @State private var topNumber = "4"
    @State private var bottomNumber = "3"
    @AppStorage("bestScore") var bestScore: String = "2"
    @State private var isGameOver = false
    @State private var chosenDirection: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var topOptionScale: CGFloat = 1
    @State private var bottomOptionScale: CGFloat = 1
    @State private var topOptionOffset: CGFloat = 0
    @State private var bottomOptionOffset: CGFloat = 0
    @State private var topOptionColor: Color = .gray
    @State private var bottomOptionColor: Color = .gray
    @State private var swiping = false
    @State private var bgColor = Color.black
    @StateObject private var storeKitManager = StoreKitManager()
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showFlexShareSheet: Bool = false
    
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
                            Button {
                                impactLight.impactOccurred()
                                showFlexShareSheet = true
                            } label: {
                                Text("Flex").bold().font(.system(size: g.size.height * 0.025)).foregroundColor(.white).padding(g.size.height * 0.01).padding(.horizontal, g.size.height * 0.02).background(.gray.opacity(0.3)).cornerRadius(g.size.height * 0.01).padding()
                            }
                            .sheet(isPresented: $showFlexShareSheet) {
                                if let flexShareImage = renderScoreboardImage(geometry: g) {
                                    // 3) We present our custom FlexShareView
                                    FlexShareView(image: flexShareImage)
                                        .onAppear {
                                            print("flexShareImage created")
                                        }
                                }
                            }
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
                        Text(insertCommas(topNumber)).lineLimit(1).minimumScaleFactor(0.01).foregroundColor(topOptionColor).font(.system(size: g.size.height * 0.15)).scaleEffect(topOptionScale).offset(y: topOptionOffset * (g.size.height / 15.0)).padding(.horizontal, g.size.width * 0.15).allowsHitTesting(false)
                        Spacer()
                        Text(insertCommas(centerNumber)).minimumScaleFactor(0.01).lineLimit(1).frame(maxWidth: g.size.width).fixedSize(horizontal: false, vertical: false).foregroundColor(.white).font(.system(size: g.size.height * 0.6)).scaleEffect(scale).offset(y: chosenDirection * (g.size.height / 3.0)).allowsHitTesting(false)
                        Spacer()
                        Text(insertCommas(bottomNumber)).lineLimit(1).minimumScaleFactor(0.01).foregroundColor(bottomOptionColor).font(.system(size: g.size.height * 0.15)).scaleEffect(bottomOptionScale).offset(y: bottomOptionOffset * (g.size.height / 15.0)).padding(.horizontal, g.size.width * 0.15).allowsHitTesting(false)
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
                        if abs(drag) < optionDistance / 1.1  {
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
            .allowsHitTesting(!swiping)
        }
        .onChange(of: scenePhase) { _ in
            withAnimation(.linear(duration: 0.1)) {
                chosenDirection = 0.0
                scale = 1
            }
        }
    }
    
    @MainActor
    func renderScoreboardImage(geometry g: GeometryProxy) -> UIImage? {
        // We'll replicate the "Best" and "Score" portion
        let scoreboardView = VStack(spacing: 20) {
            Text("Best")
                .font(.system(size: g.size.height * 0.05))
                .foregroundColor(.gray)
            
            ZStack {
                // Transparent placeholder for consistent sizing
                Text("0")
                    .font(.system(size: g.size.height * 0.1))
                    .foregroundColor(.clear)
                Text(insertCommas(bestScore))
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                    .font(.system(size: g.size.height * 0.08))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
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
                    .padding(.horizontal, 40)
            }
        }
        .frame(width: g.size.width, height: g.size.width)  // adjust as desired
        .background(Color.black)
        // Use ImageRenderer to create a UIImage
        let renderer = ImageRenderer(content: scoreboardView)
        // For iOS 17+ you can set a scale, if needed:
        // renderer.scale = UIScreen.main.scale
        return renderer.uiImage
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
        swiping = true
        withAnimation(.spring(duration: 0.2)) { chosenDirection = up ? -1 : 1; scale = 0.0 }
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
            currentPower += 1
            withAnimation {
                centerNumber = String(format: "%.0f", pow(2, Double(currentPower)))
            }
            
            if chosenDirection > 0 {
                withAnimation(.linear(duration: 0.1)) { bottomOptionScale = 1.7; bottomOptionColor = .white }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.linear(duration: 0.1)) { bottomOptionScale = 1.0; bottomOptionColor = .gray}
                }
            } else {
                withAnimation(.linear(duration: 0.1)) { topOptionScale = 1.7; topOptionColor = .white}
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.linear(duration: 0.1)) { topOptionScale = 1.0; topOptionColor = .gray }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                setNewNumbers()
                withAnimation(.linear(duration: 0.2)) { chosenDirection = 0; scale = 1; swiping = false}
            }
        } else {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
            if chosenDirection > 0 {
                withAnimation(.linear(duration: 0.1)) { bottomOptionOffset = -1; bottomOptionColor = .red }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.linear(duration: 0.1)) { bottomOptionOffset = 1 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.linear(duration: 0.1)) { bottomOptionOffset = 0 }
                }
            } else {
                withAnimation(.linear(duration: 0.1)) { topOptionOffset = -1; topOptionColor = .red }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.linear(duration: 0.1)) { topOptionOffset = 1 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.linear(duration: 0.1)) { topOptionOffset = 0 }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hapticManager.notification(type: .error); isGameOver = true; swiping = false
                withAnimation(.linear(duration: 0.1)) { chosenDirection = 0; scale = 1; bottomOptionColor = .gray; topOptionColor = .gray }
            }
        }
        
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

class FlexActivityItemProvider: NSObject, UIActivityItemSource {
    let image: UIImage
    let url: URL
    
    init(image: UIImage, url: URL) {
        self.image = image
        self.url = url
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        // The placeholder is typically either the image or text
        return image
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // Return the URL or image depending on the activity
        // Typically, we return the same object for all activity types
        return url
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        // Set the link
        metadata.originalURL = url
        metadata.url = url
        
        // Title in the preview
        metadata.title = "Beat my score!"
        
        // The image to show in the preview
        metadata.imageProvider = NSItemProvider(object: image)
        
        return metadata
    }
}

// MARK: - A UIViewControllerRepresentable to present the share sheet
struct FlexShareView: UIViewControllerRepresentable {
    let image: UIImage
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Provide the link you want to share
        let shareURL = URL(string: "https://apps.apple.com/us/app/x2g/id6739356744")!
        
        // Activity items: Our custom item provider
        let items: [Any] = [FlexActivityItemProvider(image: image, url: shareURL)]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Excluded activity types if needed
        // activityVC.excludedActivityTypes = [.addToReadingList, .airDrop, ...]
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) {
        // no updates needed
    }
}

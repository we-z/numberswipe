

import SwiftUI

struct TempView: View {
    var body: some View {
        ZStack{
            Color.white
            Color.black
                .aspectRatio(contentMode: .fit)
            Text("2")
                .foregroundColor(.white)
                .font(.system(size: 300))
            Text("n")
                .foregroundColor(.white)
                .font(.system(size: 150))
                .offset(x: 120, y: -90)
        }
    }
}

#Preview {
    TempView()
}

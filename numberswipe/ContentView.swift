//
//  ContentView.swift
//  numberswipe
//
//  Created by Wheezy Capowdis on 8/14/24.
//

import SwiftUI

let deviceHeight = UIScreen.main.bounds.height
let deviceWidth = UIScreen.main.bounds.width

struct ContentView: View {
    var body: some View {
        VStack {
            Text("2331")
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .font(.system(size: deviceWidth))
                .frame(height: deviceHeight/4)
            Spacer()
            Text("52 + 43")
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .font(.system(size: deviceWidth))
                .frame(height: deviceHeight/4)
            Spacer()
            Text("9333")
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .font(.system(size: deviceWidth))
                .frame(height: deviceHeight/4)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

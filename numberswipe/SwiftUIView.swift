//
//  SwiftUIView.swift
//  X2G
//
//  Created by Wheezy Capowdis on 12/13/24.
//

import SwiftUI

struct SwiftUIView: View {
    @State var videoURL = "None"
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Color.black
//                    .aspectRatio(contentMode: .fit)
                    .frame(width: 360, height: 240)
                
                Text(videoURL)
                    .foregroundColor(.white)
            }
            Spacer()
            HStack {
                Spacer()
                Button {
                    videoURL = "https://www.youtube.com/watch?v=1111111111"
                } label: {
                    Text("Set Queue")
                        .foregroundColor(.white)
                        .padding()
                        .background(.blue)
                        .cornerRadius(10)
                }
                Spacer()
                Text("Go Queue")
                    .foregroundColor(.white)
                    .padding()
                    .background(.blue)
                    .cornerRadius(10)
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview {
    SwiftUIView()
}

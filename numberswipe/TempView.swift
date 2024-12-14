//
//  TempView.swift
//  PO2
//
//  Created by Wheezy Capowdis on 12/10/24.
//

import SwiftUI

struct TempView: View {
    var body: some View {
        ZStack{
            Color.white
            Color.black
                .aspectRatio(contentMode: .fit)
            Text("X2G")
                .foregroundColor(.white)
                .font(.system(size: 200))
//            Text("n")
//                .foregroundColor(.white)
//                .font(.system(size: 150))
//                .offset(x: 110, y: -110)
        }
    }
}

#Preview {
    TempView()
}

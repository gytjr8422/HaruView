//
//  ToastView.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct ToastView: View {
   var body: some View {
       LocalizedText(key: "save_completed")
           .font(.pretendardSemiBold(size: 14))
           .foregroundStyle(Color.white)
           .padding(10)
           .background(
               RoundedRectangle(cornerRadius: 10)
                   .opacity(0.85)
           )
           .transition(.move(edge: .top).combined(with: .opacity))
   }
}

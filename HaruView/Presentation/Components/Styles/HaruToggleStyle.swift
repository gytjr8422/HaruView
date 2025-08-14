//
//  HaruToggleStyle.swift
//  HaruView
//
//  Created by 김효석 on 6/30/25.
//

import SwiftUI


struct HaruToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(configuration.isOn ? .haruPrimary : Color.gray)
                .frame(width: 46, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20)
                        .offset(x: configuration.isOn ? 12 : -12)
                        .shadow(color: .black.opacity(0.25), radius: 4)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

//
//  AddSheetHeader.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI

struct AddSheetHeader: View {
    @Binding var selected: AddSheetMode
    let indicatorNS: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AddSheetMode.allCases) { seg in
                VStack(spacing: 4) {
                    Text(seg.localized)
                        .font(.pretendardBold(size: 16))
                        .foregroundStyle(selected == seg ? .haruPrimary : .secondary)
                    ZStack {
                        Capsule().fill(Color.clear).frame(height: 3)
                        if selected == seg {
                            Capsule()
                                .fill(.haruPrimary)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "indicator", in: indicatorNS)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
                .onTapGesture { withAnimation(.spring()) { selected = seg } }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

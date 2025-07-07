//
//  CalendarView.swift
//  HaruView
//
//  Created by 김효석 on 7/7/25.
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexCode: "FFFCF5")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundStyle(Color(hexCode: "A76545"))
                        
                        Text("달력 뷰")
                            .font(.pretendardBold(size: 24))
                            .foregroundStyle(Color(hexCode: "40392B"))
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("달력")
                        .font(.pretendardSemiBold(size: 18))
                        .foregroundStyle(Color(hexCode: "40392B"))
                }
            }
        }
    }
}

#Preview {
    CalendarView()
}

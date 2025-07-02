//
//  CalendarSelectionView.swift
//  HaruView
//
//  Created by 김효석 on 6/30/25.
//

import SwiftUI

// MARK: - 캘린더 선택 컴포넌트
struct CalendarSelectionView: View {
    @Binding var selectedCalendar: EventCalendar?
    let availableCalendars: [EventCalendar]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if availableCalendars.isEmpty {
                Text("사용 가능한 캘린더가 없습니다")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(availableCalendars, id: \.id) { calendar in
                        HStack {
                            Circle()
                                .fill(Color(calendar.color))
                                .frame(width: 12, height: 12)
                            
                            Text(calendar.title)
                                .font(.pretendardRegular(size: 16))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if selectedCalendar?.id == calendar.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color(hexCode: "A76545"))
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .font(.pretendardRegular(size: 12))
                        .foregroundStyle(Color(hexCode: "A76545"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hexCode: "A76545").opacity(0.1))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCalendar = calendar
                        }
                    }
                }
            }
        }
    }
}

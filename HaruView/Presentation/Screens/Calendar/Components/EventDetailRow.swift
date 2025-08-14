//
//  EventDetailRow.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import SwiftUI

struct EventDetailRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(event.calendarColor))
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .lineLimit(1)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(.haruTextPrimary)
                
                if let timeText = event.timeDisplayText {
                    Text(timeText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if event.isAllDay {
                    Text("하루 종일")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if event.hasAlarms {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.haruPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(event.calendarColor).opacity(0.1))
        )
    }
}

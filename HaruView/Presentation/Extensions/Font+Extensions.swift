//
//  Font+Extensions.swift
//  HaruView
//
//  Created by 김효석 on 5/4/25.
//

import SwiftUI

extension Font {
    static func robotoSerifBold(size: CGFloat) -> Font {
        .custom("RobotoSerif28pt-Bold", size: size)
    }

    static func pretendardBold(size: CGFloat) -> Font {
        .custom("Pretendard-Bold", size: size)
    }

    static func pretendardSemiBold(size: CGFloat) -> Font {
        .custom("Pretendard-SemiBold", size: size)
    }

    static func pretendardRegular(size: CGFloat) -> Font {
        .custom("Pretendard-Regular", size: size)
    }
    
    static func museumBold(size: CGFloat) -> Font {
        .custom("MuseumClassicBold", size: size)
    }
    
    static func museumMedium(size: CGFloat) -> Font {
        .custom("MuseumClassicMedium", size: size)
    }
    
    static func jakartaRegular(size: CGFloat) -> Font {
        .custom("PlusJakartaSans-Regular", size: size)
    }
    
    static func jakartaBold(size: CGFloat) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }
    
    static func bookkMyungjoBold(size: CGFloat) -> Font {
        .custom("BookkMyungjo-Bd", size: size)
    }
}

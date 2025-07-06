//
//  String+Extensions.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import Foundation

extension String {
    func withFillIfAvailable() -> String {
        let fillableSymbols: Set<String> = [
            "sun.max",
            "moon.stars",
            "cloud",
            "cloud.sun",
            "cloud.moon",
            "cloud.rain",
            "cloud.snow",
            "cloud.bolt.rain",
            "cloud.fog",
            "cloud.drizzle",
            "cloud.sun.rain",
            "cloud.moon.rain",
            "sun.haze",
            "moon.haze",
            "thermometer.sun",
            "thermometer.snowflake",
            "wind.snow",
            "hurricane",
            "smoke",
            "wind"
        ]
        
        guard !self.hasSuffix(".fill") else { return self }
        let fillable: Set<String> = fillableSymbols
        return fillable.contains(self) ? self + ".fill" : self
    }
}

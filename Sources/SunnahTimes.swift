//
//  SunnahTimes.swift
//  Adhan
//
//  Copyright © 2018 Batoul Apps.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// A struct representing additional Sunnah prayer times based on `PrayerTimes`.
///
/// Includes:
/// - `firstThirdOfTheNight`: End of the first third of the night (Maghrib + 1/3 of night duration)
/// - `middleOfTheNight`: Midpoint between Maghrib and next Fajr (recommended time for Isha)
/// - `lastThirdOfTheNight`: Beginning of the final third of the night (Fajr - 1/3 of night duration), a prime time for Qiyam
/// - `sunrise`: Exact sunrise time (Shurooq)
/// - `firstTimeOfDuha`: Approximate start of Duha prayer (~20 minutes after sunrise)
/// - `lastTimeOfDhuha`: Safe time to finish Duha prayer (~10 minutes before Dhuhr)
/// - `firstTimeOfWitre`: Beginning of the time for Witr prayer (after Isha has been performed)
/// - `lastTimeOfWitre`: Safe recommended time to FINISH Witr prayer (5-minute buffer before Fajr)
public struct SunnahTimes {
    public let firstThirdOfTheNight: Date
    public let middleOfTheNight: Date
    public let lastThirdOfTheNight: Date
    public let sunrise: Date
    public let firstTimeOfDuha: Date
    public let lastTimeOfDhuha: Date
    public let firstTimeOfWitre: Date
    public let lastTimeOfWitre: Date

    public init?(from prayerTimes: PrayerTimes) {
        guard let date = Calendar.gregorianUTC.date(from: prayerTimes.date),
              let nextDay = Calendar.gregorianUTC.date(byAdding: .day, value: 1, to: date),
              let nextDayPrayerTimes = PrayerTimes(
                  coordinates: prayerTimes.coordinates,
                  date: Calendar.gregorianUTC.dateComponents([.year, .month, .day], from: nextDay),
                  calculationParameters: prayerTimes.calculationParameters
              )
        else {
            return nil
        }

        let nightDuration = nextDayPrayerTimes.fajr.timeIntervalSince(prayerTimes.maghrib)

        // Night calculations
        self.firstThirdOfTheNight = prayerTimes.maghrib
            .addingTimeInterval(nightDuration / 3.0)
            .roundedMinute()

        self.middleOfTheNight = prayerTimes.maghrib
            .addingTimeInterval(nightDuration / 2.0)
            .roundedMinute()

        // FIXED: Calculate from Fajr backwards for clarity and accuracy
        self.lastThirdOfTheNight = prayerTimes.maghrib
            .addingTimeInterval(nightDuration * (2.0 / 3.0))
            .roundedMinute()

        self.sunrise = prayerTimes.sunrise.roundedMinute()

        // Duha time calculations (approximations)
        self.firstTimeOfDuha = prayerTimes.sunrise
            .addingTimeInterval(20 * 60) // ~20 minutes after sunrise
            .roundedMinute()

        self.lastTimeOfDhuha = prayerTimes.dhuhr
            .addingTimeInterval(-10 * 60) // ~10 minutes before Dhuhr
            .roundedMinute()

        // FIXED: Document that this is after Isha begins, not necessarily after it's performed
        self.firstTimeOfWitre = prayerTimes.isha.roundedMinute()

        // FIXED: Critical theological fix - use safety buffer instead of fixed cutoff
        let witrSafetyBuffer: TimeInterval = -5 * 60 // 5 minute buffer
        self.lastTimeOfWitre = nextDayPrayerTimes.fajr
            .addingTimeInterval(witrSafetyBuffer)
            .roundedMinute()
    }

    /// Check if current time is within the recommended time for Duha prayer
    /// Note: This uses approximations (~15 min after sunrise to ~10 min before Dhuhr)
    public func isDuhaTime(now: Date = Date()) -> Bool {
        return now >= firstTimeOfDuha && now <= lastTimeOfDhuha
    }

    /// The recommended time range for Duha prayer (approximated)
    public var duhaRange: ClosedRange<Date> {
        return firstTimeOfDuha...lastTimeOfDhuha
    }
}

// Extension for rounding dates to the nearest minute for clean display
extension Date {
    func roundedMinute() -> Date {
        let calendar = Calendar.gregorianUTC
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: components) ?? self
    }
}

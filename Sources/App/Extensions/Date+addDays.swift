//
//  Date+addDays.swift
//  App
//
//  Created by Djordje Ljubinkovic on 8/9/19.
//

import Foundation

extension Date {
    func addDays(_ daysCount: Int) -> Date {
        var dayComponent = DateComponents()
        dayComponent.day = daysCount
        
        let calendar = Calendar.current
        guard let nextDate = calendar.date(byAdding: dayComponent, to: self) else { fatalError() }
        
        return nextDate
    }
}

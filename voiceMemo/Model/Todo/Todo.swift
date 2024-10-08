//
//  Todo.swift
//  voiceMemo
//

import Foundation

// 중요도 열거형 정의
enum Priority: String, Comparable {
    case high = "중요도 상"
    case medium = "중요도 중"
    case low = "중요도 하"
    
    // Comparable 프로토콜을 구현하여 중요도를 비교할 수 있도록 합니다.
    static func < (lhs: Priority, rhs: Priority) -> Bool {
        switch (lhs, rhs) {
        case (.high, .medium), (.high, .low), (.medium, .low):
            return false
        case (.medium, .high), (.low, .high), (.low, .medium):
            return true
        default:
            return false
        }
    }
}

struct Todo: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var time: Date
    var day: Date
    var priority: Priority
    var selected: Bool
    var tags: [String]
    
    init(
        title: String,
        time: Date,
        day: Date,
        priority: Priority = .medium,
        selected: Bool = false,
        tags: [String] = []
    ) {
        self.title = title
        self.time = time
        self.day = day
        self.priority = priority
        self.selected = selected;
        self.tags = tags
    }
    
    var convertedDayAndTime: String {
            String("\(day.formattedDay) - \(time.formattedTime)에 알림")
    }
}



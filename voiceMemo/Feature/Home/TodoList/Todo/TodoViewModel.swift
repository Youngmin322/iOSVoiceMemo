//
//  TodoViewModel.swift
//  voiceMemo
//

import Foundation

class TodoViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var time: Date = Date()
    @Published var day: Date = Date()
    @Published var priority: Priority = .medium
    @Published var isDisplayCalendar: Bool = false
    @Published var currentTodo: Todo
    
    // Init 메서드에 priority 추가
    init(
        title: String = "",
        time: Date = Date(),
        day: Date = Date(),
        priority: Priority = .medium,  // priority 초기화 추가
        isDisplayCalendar: Bool = false
    ) {
        self.title = title
        self.time = time
        self.day = day
        self.priority = priority
        self.isDisplayCalendar = isDisplayCalendar;
        self.currentTodo = Todo(title: title,time: time, day: day, priority: priority)
    }

    func setIsDisplayCalendar(_ isDisplay: Bool) {
        isDisplayCalendar = isDisplay
    }
    func updateTodoTags(tags: [String]) {
           currentTodo.tags = tags
       }
}

import Foundation

class TodoListViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var isEditTodoMode: Bool = false
    @Published var removeTodos: [Todo] = []
    @Published var isDisplayRemoveTodoAlert: Bool = false
    
    var removeTodosCount: Int {
        return removeTodos.count
    }
    
    var navigationBarRightBtnMode: NavigationBtnType {
        isEditTodoMode ? .complete : .remove
    }
    
    // 할 일 추가 메서드
    func addTodo(
        title: String,
        time: Date,
        day: Date,
        priority: Priority = .medium,
        tags: [String] = [], // 태그 매개변수 추가
        selected: Bool = false
    ) {
        let newTodo = Todo(
            title: title,
            time: time,
            day: day,
            priority: priority,
            selected: selected,
            tags: tags // 태그 포함
        )
        todos.append(newTodo)
    }
    
    // 나중 할 일로 정렬
    func sortByFuture() {
        todos.sort { $0.time > $1.time }
    }
    
    // 가까운 할 일로 정렬
    func sortByUpcoming() {
        todos.sort { $0.time < $1.time }
    }
    
    // 중요도 순으로 정렬
    func sortByPriority() {
        todos.sort { $0.priority > $1.priority }
    }

    // 할 일 선택 메서드
    func selectedBoxTapped(_ todo: Todo) {
        if let index = todos.firstIndex(of: todo) {
            todos[index].selected.toggle()
        }
    }
    
    func navigationRightBtnTapped() {
        if isEditTodoMode {
            if removeTodos.isEmpty {
                isEditTodoMode = false
            } else {
                setIsDisplayRemoveTodoAlert(true)
            }
        } else {
            isEditTodoMode = true
        }
    }
    
    func setIsDisplayRemoveTodoAlert(_ isDisplay: Bool) {
        isDisplayRemoveTodoAlert = isDisplay
    }
    
    func todoRemoveSelectedBoxTapped(_ todo: Todo) {
        if let index = removeTodos.firstIndex(of: todo) {
            removeTodos.remove(at: index)
        } else {
            removeTodos.append(todo)
        }
    }
    
    func removeBtnTapped() {
        todos.removeAll { todo in
            removeTodos.contains(todo)
        }
        removeTodos.removeAll()
        isEditTodoMode = false
    }
}

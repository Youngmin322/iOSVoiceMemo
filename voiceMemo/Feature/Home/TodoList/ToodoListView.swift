import SwiftUI

// MARK: - TodoListView
struct TodoListView: View {
    @EnvironmentObject private var pathModel: PathModel
    @EnvironmentObject private var todoListViewModel: TodoListViewModel
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var selectedSortOption: SortOption = .upcoming
    
    enum SortOption: String, CaseIterable, Identifiable {
        case future = "나중 할 일"
        case upcoming = "가까운 할 일"
        case priority = "중요도 순"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            // 투두 셀 리스트
            VStack {
                Picker("정렬 기준", selection: $selectedSortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedSortOption, perform: { option in
                    switch option {
                    case .future:
                        todoListViewModel.sortByFuture()
                    case .upcoming:
                        todoListViewModel.sortByUpcoming()
                    case .priority:
                        todoListViewModel.sortByPriority()
                    }
                })

                if !todoListViewModel.todos.isEmpty {
                    CustomNavigationBar(
                        isDisplayLeftBtn: false,
                        rightBtnAction: {
                            todoListViewModel.navigationRightBtnTapped()
                        },
                        rightBtnType: todoListViewModel.navigationBarRightBtnMode
                    )
                } else {
                    Spacer()
                        .frame(height: 30)
                }
                
                TitleView()
                    .padding(.top, 20)
                
                if todoListViewModel.todos.isEmpty {
                    AnnouncementView()
                } else {
                    TodoListContentView()
                        .padding(.top, 20)
                }
            }

            // 할 일 추가 버튼
            WriteTodoBtnView()
                .padding(.trailing, 20)
                .padding(.bottom, 50)
        }
        .alert(
            "To do list \(todoListViewModel.removeTodosCount)개 삭제하시겠습니까?",
            isPresented: $todoListViewModel.isDisplayRemoveTodoAlert
        ) {
            Button("삭제", role: .destructive) {
                todoListViewModel.removeBtnTapped()
            }
            Button("취소", role: .cancel) { }
        }
        .onChange(
            of: todoListViewModel.todos,
            perform: { todos in
                homeViewModel.setTodosCount(todos.count)
            }
        )
    }
}

// MARK: - todo리스트 타이틀뷰
private struct TitleView: View {
    @EnvironmentObject private var todoListViewModel: TodoListViewModel
    
    fileprivate var body: some View {
        HStack {
            if todoListViewModel.todos.isEmpty {
                Text("To do list를 \n추가해보세요")
            } else {
                Text("To do list \(todoListViewModel.todos.count)개가\n있습니다.")
            }
            
            Spacer()
        }
        .font(.system(size: 30, weight: .bold))
        .padding(.leading, 20)
    }
}

// MARK: - TodoList 안내
private struct AnnouncementView: View {
    fileprivate var body: some View {
        VStack(spacing: 15) {
            Spacer()
            
            Image("pencil")
                .renderingMode(.template)
            Text("\"매일 아침 5시 운동하자!\"")
            Text("\"내일 8시 수강 신청하자! \"")
            Text("\"1시 반 점심약속 리마인드 해보자!\"")
            
            Spacer()
        }
        .font(.system(size:16))
        .foregroundColor(.customGray2)
    }
}

// MARK: - TodoList 컨텐츠 뷰
private struct TodoListContentView: View {
    @EnvironmentObject private var todoListViewModel: TodoListViewModel
  
    fileprivate var body: some View {
        VStack {
            HStack {
                Text("할일 목록")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.leading, 20)
                
                Spacer()
            }
          
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.customGray0)
                        .frame(height: 1)
                  
                    ForEach(todoListViewModel.todos, id: \.id) { todo in
                        TodoCellView(todo: todo)
                    }
                }
            }
        }
    }
}

// MARK: - Todo 셀 뷰
struct TodoCellView: View {
    @EnvironmentObject private var todoListViewModel: TodoListViewModel
    @State private var isRemoveSelected: Bool
    private var todo: Todo
    
    init(
        isRemoveSelected: Bool = false,
        todo: Todo
    ) {
        _isRemoveSelected = State(initialValue: isRemoveSelected)
        self.todo = todo
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                if !todoListViewModel.isEditTodoMode {
                    Button(
                        action: { todoListViewModel.selectedBoxTapped(todo) },
                        label: { todo.selected ? Image("selectedBox") : Image("unSelectedBox") }
                    )
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    // 제목 표시
                    Text(todo.title)
                        .font(.system(size: 16))
                        .foregroundColor(todo.selected ? .customIconGray : .customBlack)
                        .strikethrough(todo.selected)
                    
                    // 날짜와 시간 표시
                    Text(todo.convertedDayAndTime)
                        .font(.system(size: 14))
                        .foregroundColor(.customIconGray)
                    
                    // 중요도 표시
                    Text("Priority: \(todo.priority.rawValue)")
                        .font(.system(size: 14))
                        .foregroundColor(priorityColor(for: todo.priority))
                }
                
                Spacer()
                
                if todoListViewModel.isEditTodoMode {
                    Button(
                        action: {
                            isRemoveSelected.toggle()
                            todoListViewModel.todoRemoveSelectedBoxTapped(todo)
                        },
                        label: {
                            isRemoveSelected ? Image("selectedBox") : Image("unSelectedBox")
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Rectangle()
                .fill(Color.customGray0)
                .frame(height: 1)
        }
    }
    
    // 중요도에 따른 색상 선택
    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        }
    }
}

// MARK: - Todo 작성 버튼 뷰
private struct WriteTodoBtnView: View {
    @EnvironmentObject private var pathModel: PathModel
  
    fileprivate var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(
                    action: {
                        pathModel.paths.append(.todoView)
                    },
                    label: {
                        Image("writeBtn")
                    }
                )
            }
        }
    }
}

#Preview {
    TodoListView()
        .environmentObject(PathModel())
        .environmentObject(TodoListViewModel())
        .environmentObject(HomeViewModel())
}

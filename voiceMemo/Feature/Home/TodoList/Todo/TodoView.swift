//
//  TodoView.swift
//  voiceMemo
//

import SwiftUI

struct TodoView: View {
    @EnvironmentObject private var pathModel: PathModel
    @EnvironmentObject private var todoListViewModel: TodoListViewModel
    @StateObject private var todoViewModel = TodoViewModel()
  
    var body: some View {
        VStack {
            CustomNavigationBar(
                leftBtnAction: {
                    pathModel.paths.removeLast()
                },
                rightBtnAction: {
                    todoListViewModel.addTodo(
                        title: todoViewModel.title,
                        time: todoViewModel.time,
                        day: todoViewModel.day,
                        priority: todoViewModel.priority,
                        selected: false
                    )
                    pathModel.paths.removeLast()
                },
                rightBtnType: .create
            )
      
            TitleView()
                .padding(.top, 20)
      
            Spacer()
                .frame(height: 20)
      
            TodoTitleView(todoViewModel: todoViewModel)
                .padding(.leading, 20)
            
            // 중요도 선택 뷰를 제목 아래로 이동하고 중요도 라벨 제거
            SelectPriorityView(todoViewModel: todoViewModel)
                .padding(.horizontal, 20) // 양쪽 여백 추가하여 중앙에 정렬
              
            SelectTimeView(todoViewModel: todoViewModel)
      
            SelectDayView(todoViewModel: todoViewModel)
                .padding(.leading, 20)
            
            SelectTagView(todoViewModel: todoViewModel) // 태그 선택 뷰
                .padding(.leading, 20)
      
            Spacer()
        }
    }
}

// MARK: - 타이틀 뷰
private struct TitleView: View {
    fileprivate var body: some View {
        HStack {
            Text("To do list를\n추가해 보세요.")
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .minimumScaleFactor(0.5)
            
            Spacer()
        }
        .font(.system(size: 30, weight: .bold))
        .padding(.leading, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading) 
    }
}


// MARK: - 투두 타이틀 뷰 (제목 입력 뷰)
private struct TodoTitleView: View {
    @ObservedObject private var todoViewModel: TodoViewModel
    
    fileprivate init(todoViewModel: TodoViewModel) {
        self.todoViewModel = todoViewModel
    }
    
    fileprivate var body: some View {
        VStack {
            TextField("제목을 입력하세요.", text: $todoViewModel.title)
            
        }
    }
}
// MARK: - 시간 선택 뷰
private struct SelectTimeView: View {
    @ObservedObject private var todoViewModel: TodoViewModel
    
    fileprivate init(todoViewModel: TodoViewModel) {
        self.todoViewModel = todoViewModel
    }
    
    fileprivate var body: some View {
        VStack {
            Rectangle()
                .fill(Color.customGray0)
                .frame(height: 1)
            
            DatePicker(
                "",
                selection: $todoViewModel.time,
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(WheelDatePickerStyle())
            .frame(maxWidth: .infinity, alignment: .center)
            
            Rectangle()
                .fill(Color.customGray0)
                .frame(height: 1)
        }
    }
}

// MARK: - 날짜 선택 뷰
private struct SelectDayView: View {
    @ObservedObject private var todoViewModel: TodoViewModel
    
    fileprivate init(todoViewModel: TodoViewModel) {
        self.todoViewModel = todoViewModel
    }
    
    fileprivate var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("날짜")
                    .foregroundColor(.customIconGray)
                Spacer()
            }
            
            HStack {
                Button(
                    action: { todoViewModel.setIsDisplayCalendar(true) },
                    label: {
                        Text("\(todoViewModel.day.formattedDay)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.customPink)
                    }
                )
                .popover(isPresented: $todoViewModel.isDisplayCalendar) {
                    DatePicker(
                        "",
                        selection: $todoViewModel.day,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .onChange(of: todoViewModel.day) { _ in
                        todoViewModel.setIsDisplayCalendar(false)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - 중요도 선택 뷰
private struct SelectPriorityView: View {
    @ObservedObject private var todoViewModel: TodoViewModel
    
    fileprivate init(todoViewModel: TodoViewModel) {
        self.todoViewModel = todoViewModel
    }
    
    fileprivate var body: some View {
        VStack(spacing: 5) {
            Picker("", selection: $todoViewModel.priority) {
                Text("중요도 상").tag(Priority.high)
                Text("중요도 중").tag(Priority.medium)
                Text("중요도 하").tag(Priority.low)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: .infinity, alignment: .center) // 가운데 정렬
        }
    }
}

// MARK: - 태그 선택 뷰
private struct SelectTagView: View {
    @ObservedObject private var todoViewModel: TodoViewModel
    @State private var selectedTags: Set<String> = []
    
    let availableTags = ["운동", "공부", "업무", "기타"]
    
    fileprivate init(todoViewModel: TodoViewModel) {
        self.todoViewModel = todoViewModel
        _selectedTags = State(initialValue: Set(todoViewModel.currentTodo.tags))
    }
    
    fileprivate var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("태그")
                    .foregroundColor(.customIconGray)
                Spacer()
            }
            .padding(.bottom, 10)
            
            // 태그 버튼을 가로로 배치
            HStack(spacing: 10) {
                ForEach(availableTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                        // 선택한 태그를 todo에 업데이트
                        todoViewModel.updateTodoTags(tags: Array(selectedTags))
                    }) {
                        Text(tag)
                            .padding(10)
                            .background(selectedTags.contains(tag) ? Color(red: 238/255, green: 95/255, blue: 167/255) : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                            .frame(maxWidth: .infinity) // 버튼을 가로로 늘림
                    }
                }
            }
            .padding(.horizontal) // 좌우 여백 추가

            Spacer()
        }
        .padding(.vertical) // 위아래 여백 추가
        .background(Color.clear) // 배경색 제거
    }
}


#Preview {
    TodoView()
}

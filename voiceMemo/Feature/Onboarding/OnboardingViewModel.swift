//
//  OnboardingViewModel.swift
//  voiceMemo
//
//

import Foundation

class OnboardingViewModel: ObservableObject {
  @Published var onboardingContents: [OnboardingContent]
  
  init(
    onboardingContents: [OnboardingContent] = [
      .init(
        imageFileName: "onboarding_1",
        title: "오늘의 할일",
        subTitle: "To do list로 언제 어디서든 해야할일을 한눈에"
      ),
      .init(
        imageFileName: "onboarding_2",
        title: "언제 어디서든 메모하기",
        subTitle: "기억해야 할것, 메모하기"
      ),
      .init(
        imageFileName: "onboarding_3",
        title: "작은 순간도 놓치지 않게",
        subTitle: "소중한 기억, 음성 메모로 완벽하게"
      ),
      .init(
        imageFileName: "onboarding_4",
        title: "흘러가는 시간의 순간들",
        subTitle: "타이머로 맞이하는 원하는 시간"
      )
    ]
  ) {
    self.onboardingContents = onboardingContents
  }
}

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
        title: "꿈을 향한 첫 걸음",
        subTitle: "내일의 나를 향한 여정, To do list와 함께"
      ),
      .init(
        imageFileName: "onboarding_2",
        title: "나만의 작은 기록의 공간",
        subTitle: "언제든 떠오르는 생각, 메모장에"
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

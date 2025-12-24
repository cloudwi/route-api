class UpdateDiaryPromptsToCoupleFocused < ActiveRecord::Migration[8.1]
  def up
    # 기존 데이터 삭제
    DiaryPrompt.delete_all

    # 커플 중심 질문으로 재구성
    prompts = [
      # 감정 (Emotion) - 20개
      { content: "오늘 하루 중 가장 행복했던 순간은 언제였나요?", category: "감정" },
      { content: "오늘 어떤 감정을 가장 많이 느꼈나요?", category: "감정" },
      { content: "오늘 웃었던 순간이 있나요? 무엇 때문이었나요?", category: "감정" },
      { content: "오늘 스트레스를 받은 일이 있었나요? 어떻게 해소했나요?", category: "감정" },
      { content: "오늘 누군가에게 고마움을 느꼈나요?", category: "감정" },
      { content: "오늘 가장 편안했던 순간은 언제였나요?", category: "감정" },
      { content: "오늘 슬펐거나 속상했던 일이 있었나요?", category: "감정" },
      { content: "오늘 자랑하고 싶은 일이 있나요?", category: "감정" },
      { content: "오늘 누군가를 웃게 만든 적이 있나요?", category: "감정" },
      { content: "오늘 기분을 색으로 표현한다면 무슨 색일까요?", category: "감정" },
      { content: "오늘 가장 설렜던 순간은 언제였나요?", category: "감정" },
      { content: "오늘 누군가에게 위로받고 싶은 순간이 있었나요?", category: "감정" },
      { content: "오늘 가장 평화로웠던 순간은 언제였나요?", category: "감정" },
      { content: "오늘 무엇이 당신을 미소 짓게 했나요?", category: "감정" },
      { content: "오늘 화가 났던 순간이 있었나요? 어떻게 진정했나요?", category: "감정" },
      { content: "오늘 감동받은 일이 있었나요?", category: "감정" },
      { content: "오늘 외로움을 느낀 적이 있나요?", category: "감정" },
      { content: "오늘 자신이 자랑스러웠던 순간이 있나요?", category: "감정" },
      { content: "오늘 두려움을 느낀 적이 있나요?", category: "감정" },
      { content: "오늘 가장 후회되는 순간이 있나요?", category: "감정" },

      # 일상 (Daily) - 20개
      { content: "오늘 아침에 일어나서 가장 먼저 한 일은 무엇인가요?", category: "일상" },
      { content: "오늘 점심은 무엇을 먹었나요? 맛있었나요?", category: "일상" },
      { content: "오늘 날씨가 어땠나요? 날씨가 기분에 영향을 주었나요?", category: "일상" },
      { content: "오늘 가장 많은 시간을 보낸 일은 무엇인가요?", category: "일상" },
      { content: "오늘 새롭게 시도해본 것이 있나요?", category: "일상" },
      { content: "오늘 만난 사람들 중 기억에 남는 사람이 있나요?", category: "일상" },
      { content: "오늘 가장 힘들었던 일은 무엇인가요?", category: "일상" },
      { content: "오늘 계획했던 일을 모두 해냈나요?", category: "일상" },
      { content: "오늘 하루를 한 문장으로 요약한다면?", category: "일상" },
      { content: "오늘 가장 생산적이었던 시간은 언제였나요?", category: "일상" },
      { content: "오늘 배운 것이 있나요?", category: "일상" },
      { content: "오늘 지하철/버스에서 본 인상 깊은 장면이 있나요?", category: "일상" },
      { content: "오늘 듣거나 본 뉴스 중 기억에 남는 것이 있나요?", category: "일상" },
      { content: "오늘 카페나 식당에서 특별한 경험을 했나요?", category: "일상" },
      { content: "오늘 산책하거나 운동했나요?", category: "일상" },
      { content: "오늘 읽은 책이나 본 영상이 있나요?", category: "일상" },
      { content: "오늘 쇼핑하거나 구매한 것이 있나요?", category: "일상" },
      { content: "오늘 집안일이나 청소를 했나요?", category: "일상" },
      { content: "오늘 가장 오래 생각했던 주제는 무엇인가요?", category: "일상" },
      { content: "오늘 잠자기 전에 하고 싶은 일이 있나요?", category: "일상" },

      # 관계 (Relationship) - 20개
      { content: "오늘 상대방에게 고마웠던 점이 있나요?", category: "관계" },
      { content: "오늘 상대방에게 하고 싶은 말이 있나요?", category: "관계" },
      { content: "오늘 상대방이 보고 싶었던 순간이 있었나요?", category: "관계" },
      { content: "상대방과 함께하고 싶은 주말 계획이 있나요?", category: "관계" },
      { content: "상대방에게 배우고 싶은 점이 있나요?", category: "관계" },
      { content: "상대방과 가장 최근에 함께 웃었던 순간은 언제인가요?", category: "관계" },
      { content: "상대방의 어떤 모습이 가장 매력적인가요?", category: "관계" },
      { content: "상대방과 함께 만들고 싶은 추억은 무엇인가요?", category: "관계" },
      { content: "오늘 상대방을 생각하며 미소 지었던 순간이 있나요?", category: "관계" },
      { content: "상대방에게 해주고 싶은 깜짝 선물이 있나요?", category: "관계" },
      { content: "상대방과 함께 도전해보고 싶은 일이 있나요?", category: "관계" },
      { content: "상대방이 힘들 때 어떻게 위로하고 싶나요?", category: "관계" },
      { content: "상대방과 함께 가고 싶은 여행지가 있나요?", category: "관계" },
      { content: "상대방에게서 배운 가장 중요한 것은 무엇인가요?", category: "관계" },
      { content: "상대방과 함께하는 시간 중 가장 좋아하는 순간은?", category: "관계" },
      { content: "상대방의 어떤 습관이 귀엽게 느껴지나요?", category: "관계" },
      { content: "상대방과 더 자주 하고 싶은 활동이 있나요?", category: "관계" },
      { content: "상대방에게 미안했던 일이 있나요?", category: "관계" },
      { content: "상대방과 나눈 대화 중 기억에 남는 것이 있나요?", category: "관계" },
      { content: "상대방과 함께 나이 들어가는 모습을 상상해본 적 있나요?", category: "관계" },

      # 미래 (Future) - 15개
      { content: "내일은 어떤 하루가 되길 바라나요?", category: "미래" },
      { content: "이번 주 안에 꼭 하고 싶은 일이 있나요?", category: "미래" },
      { content: "다음 달에 도전하고 싶은 목표가 있나요?", category: "미래" },
      { content: "올해 안에 꼭 이루고 싶은 일이 있나요?", category: "미래" },
      { content: "5년 후 자신의 모습을 상상해본다면?", category: "미래" },
      { content: "언젠가 꼭 배우고 싶은 것이 있나요?", category: "미래" },
      { content: "미래의 나에게 하고 싶은 말이 있나요?", category: "미래" },
      { content: "이루고 싶은 꿈이 있나요?", category: "미래" },
      { content: "가보고 싶은 나라나 도시가 있나요?", category: "미래" },
      { content: "미래에 어떤 사람이 되고 싶나요?", category: "미래" },
      { content: "다음 휴가 때 하고 싶은 일이 있나요?", category: "미래" },
      { content: "이번 달의 목표는 무엇인가요?", category: "미래" },
      { content: "새로운 취미를 시작한다면 무엇을 하고 싶나요?", category: "미래" },
      { content: "나중에 함께 살 집은 어떤 모습일까요?", category: "미래" },
      { content: "10년 후 우리의 모습은 어떨까요?", category: "미래" },

      # 추억 (Memory) - 10개 (커플 중심으로 재구성)
      { content: "어린 시절 가장 행복했던 기억은 무엇인가요?", category: "추억" },
      { content: "인생에서 가장 기억에 남는 순간은 언제인가요?", category: "추억" },
      { content: "잊을 수 없는 여행의 추억이 있나요?", category: "추억" },
      { content: "가장 소중한 추억 속 물건이 있나요?", category: "추억" },
      { content: "우리가 처음 만났을 때를 기억하나요?", category: "추억" },
      { content: "함께한 추억 중 가장 특별했던 순간은?", category: "추억" },
      { content: "다시 돌아가고 싶은 순간이 있나요?", category: "추억" },
      { content: "우리가 처음 데이트했던 날을 기억하나요?", category: "추억" },
      { content: "우리가 함께 극복한 어려움이 있나요?", category: "추억" },
      { content: "상대방과 함께한 가장 낭만적인 순간은?", category: "추억" },

      # 감사 (Gratitude) - 10개 (커플 중심으로 재구성)
      { content: "오늘 감사한 일 세 가지를 말해주세요.", category: "감사" },
      { content: "인생에서 가장 감사한 사람은 누구인가요?", category: "감사" },
      { content: "지금 이 순간 감사한 것이 있나요?", category: "감사" },
      { content: "올해 가장 감사했던 일은 무엇인가요?", category: "감사" },
      { content: "당연하게 여겼지만 사실 감사해야 할 것은?", category: "감사" },
      { content: "누군가에게 감사 인사를 전하고 싶나요?", category: "감사" },
      { content: "건강에 대해 감사한 점이 있나요?", category: "감사" },
      { content: "일상에서 감사한 작은 순간들이 있나요?", category: "감사" },
      { content: "상대방에게 감사한 점이 있나요?", category: "감사" },
      { content: "우리 관계에서 가장 감사한 것은 무엇인가요?", category: "감사" },

      # 취미 (Hobby) - 5개
      { content: "요즘 가장 재미있게 하는 취미가 있나요?", category: "취미" },
      { content: "최근에 본 영화나 드라마 중 추천하고 싶은 것이 있나요?", category: "취미" },
      { content: "요즘 듣는 음악이 있나요? 어떤 기분이 드나요?", category: "취미" },
      { content: "주말에 주로 무엇을 하며 보내나요?", category: "취미" },
      { content: "함께 시작하고 싶은 취미가 있나요?", category: "취미" }
    ]

    DiaryPrompt.insert_all(prompts)
  end

  def down
    DiaryPrompt.delete_all
  end
end

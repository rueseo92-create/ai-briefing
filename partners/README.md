# 제휴처 안내 (취향 엽서)

취향 엽서는 매주 사용자에게 작은 웰니스 실험 세 장을 줍니다. 제휴처는 **처음 오는 손님을 위한 체험**이나 **주말 키트**를 실험으로 올릴 수 있어요.

## 어떻게 보이나요

- 실험 카드에 항상 **"광고"**라고 표시돼요. 한 번에 많아야 한 장이에요.
- 사용자가 그 주에 고른 **예산 안**(혜택 뒤 가격 기준)이고, **오가는 시간 안**에 갈 수 있는 사람에게만 보여요. 실제로 올 수 있는 사람에게만 노출돼요.
- 사용자의 기록, 예산, 위치는 제휴처에게 가지 않아요. 무엇을 보여 줄지는 사용자의 폰 안에서 정해요.

## 올리는 법

1. `offer-template.json`을 복사해 채워 주세요.
   - `zone`: rest(잠과 쉼) · movement(움직임) · food(먹는 것) · breath(숨과 마음) · nature(자연) · senses(감각) · making(손과 만들기) · connection(사람과 연결)
   - `tags`(1~3개): quiet · novel · solo · together · making · moving · outdoors · slow · sensory · learning · pretty · refreshing
   - 체험: `place`(좌표), `benefit`, `priceAfterBenefit`, `code`(영어 대문자·숫자 4~12자)
   - 키트: `kit`(구성, 가격, 배송일 1~7일)
   - 계절 한정이면 `seasons`: ["spring", "autumn"] 처럼
2. **건강 효과를 약속하는 말**(치료, 예방, 효능, 면역력, 디톡스 등)은 쓸 수 없어요.
3. 운영자가 검사합니다.

```bash
swift run --package-path Packages/TasteCore offer-check validate partners/offer-template.json
```

## 정산 (성과형)

혜택 코드가 실제로 쓰인 만큼 정산해요. 매장에서 코드가 쓰일 때마다 한 줄씩 적어 보내 주세요.

```csv
date,code
2026-10-14,YOGAFREE
2026-10-15,YOGAFREE
```

```bash
swift run --package-path Packages/TasteCore offer-check redemptions codes.csv
```

코드·주별 사용 횟수와 합계가 나와요.

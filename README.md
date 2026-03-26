# 쿠팡 파트너스 블로그 (Next.js)

SEO 최적화 + 쿠팡 파트너스 자동 연동 블로그 보일러플레이트

## 🚀 시작하기

```bash
npm install
npm run dev
```

## 📁 프로젝트 구조

```
coupang-blog/
├── app/                    # Next.js App Router
│   ├── layout.tsx          # 루트 레이아웃 (SEO 메타, 헤더/푸터)
│   ├── page.tsx            # 홈페이지
│   ├── globals.css         # 전역 스타일
│   └── posts/[slug]/       # 포스트 상세 페이지
├── components/
│   ├── PostCard.tsx         # 포스트 카드
│   └── CoupangProductCard.tsx  # 쿠팡 상품 카드 (★ 핵심)
├── content/
│   └── posts/              # MDX 포스트 파일들
├── lib/
│   ├── config.ts           # 사이트 설정 (★ 니치 정하면 여기만 수정)
│   └── posts.ts            # 포스트 관리 라이브러리
├── scripts/
│   └── new-post.mjs        # 포스트 자동 생성 스크립트
└── public/                 # 정적 파일
```

## ✏️ 글 작성하기

### 수동 작성
```bash
npm run new-post -- --title "목 마사지기 추천 TOP 5" --category comparison
```

### AI 자동 생성 (Claude API)
```bash
ANTHROPIC_API_KEY=sk-ant-... npm run new-post -- --title "공기청정기 비교" --ai
```

### MDX 포맷
```yaml
---
title: "제목"
description: "설명 (SEO용)"
date: "2026-03-26"
category: "review"          # review | comparison | guide | deal
tags: ["태그1", "태그2"]
published: true             # false면 비공개
coupangLinks:               # 쿠팡 상품 카드 자동 생성
  - name: "상품명"
    price: 39900
    link: "https://link.coupang.com/..."
    rating: 4.5
    pros: ["장점1", "장점2"]
    cons: ["단점1"]
---
```

## 🔍 SEO 기능

- ✅ 메타 태그 자동 생성 (title, description, OG)
- ✅ JSON-LD 구조화 데이터 (Article + Product)
- ✅ sitemap.xml 자동 생성
- ✅ robots.txt 자동 생성
- ✅ RSS feed
- ✅ canonical URL
- ✅ Google Analytics 연동

## 🛒 쿠팡 파트너스 연동

1. `lib/config.ts`에서 `coupang.partnerId` 설정
2. MDX frontmatter에 `coupangLinks` 추가
3. 자동으로 상품 카드 + 구조화 데이터 생성
4. 대가성 고지 문구 자동 삽입 (법적 필수)

## 🚀 배포 (Vercel 무료)

```bash
npx vercel
```

또는 GitHub에 push하면 자동 배포.

## 🔄 sero-brain 연동

sero-reels.py에서 WP REST API 대신 이 블로그에 직접 MDX 파일을 
생성하는 방식으로 자동화 가능:

```python
# sero-blog.py (추가 예정)
# Claude API로 글 생성 → MDX 파일 생성 → git push → Vercel 자동 배포
```

## ⚙️ 니치 변경하기

`lib/config.ts` 파일 하나만 수정하면 됨:
- `name`: 사이트 이름
- `description`: 설명
- `categories`: 카테고리 목록
- `nav`: 네비게이션

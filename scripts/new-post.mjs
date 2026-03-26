#!/usr/bin/env node
/**
 * new-post.mjs - 블로그 포스트 자동 생성 스크립트
 *
 * 사용법:
 *   npm run new-post -- --title "목 마사지기 추천 TOP 5"
 *   npm run new-post -- --title "공기청정기 비교" --category comparison
 *   npm run new-post -- --title "로봇청소기 리뷰" --ai  (Claude API로 본문 자동 생성)
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const POSTS_DIR = path.join(__dirname, "..", "content", "posts");

// Args 파싱
const args = process.argv.slice(2);
const opts = {};
for (let i = 0; i < args.length; i++) {
  if (args[i].startsWith("--")) {
    const key = args[i].replace("--", "");
    opts[key] = args[i + 1] || true;
    if (typeof opts[key] !== "boolean") i++;
  }
}

if (!opts.title) {
  console.log("Usage: npm run new-post -- --title '제목' [--category review] [--ai]");
  process.exit(1);
}

// 슬러그 생성 (한글 → romanization 대신 날짜 기반)
const today = new Date().toISOString().split("T")[0];
const slug = `${today}-${opts.title
  .replace(/[^\w가-힣\s]/g, "")
  .replace(/\s+/g, "-")
  .toLowerCase()
  .slice(0, 50)}`;

const category = opts.category || "review";

// Frontmatter 생성
const frontmatter = `---
title: "${opts.title}"
description: ""
date: "${today}"
category: "${category}"
tags: []
thumbnail: ""
published: false
coupangLinks:
  - name: "상품명"
    price: 0
    link: "https://link.coupang.com/your-link"
    image: ""
    rating: 0
    pros:
      - "장점 1"
    cons:
      - "단점 1"
---

## 소제목 1

본문 내용을 여기에 작성하세요.

## 소제목 2

비교나 리뷰 내용을 작성하세요.

> 💡 **결론**: 핵심 추천 내용을 여기에.
`;

// AI 생성 모드
async function generateWithAI(title, category) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    console.log("⚠️  ANTHROPIC_API_KEY가 없어서 AI 생성을 건너뜁니다.");
    return null;
  }

  console.log("🤖 Claude API로 본문 생성 중...");

  const prompt = `당신은 한국어 제품 리뷰 블로거입니다. SEO에 최적화된 블로그 글을 작성해주세요.

제목: ${title}
카테고리: ${category}

작성 규칙:
- 자연스러운 한국어 구어체 (너무 딱딱하지 않게)
- H2, H3 소제목 활용
- 구매 결정에 도움 되는 실질적인 정보
- 장단점을 균형 있게 서술
- 마지막에 결론/추천 요약
- 1500~2000자 분량
- Markdown 형식

본문만 출력하세요 (frontmatter 제외).`;

  try {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    const data = await res.json();
    return data.content?.[0]?.text || null;
  } catch (e) {
    console.error("AI 생성 실패:", e.message);
    return null;
  }
}

// 실행
async function main() {
  if (!fs.existsSync(POSTS_DIR)) {
    fs.mkdirSync(POSTS_DIR, { recursive: true });
  }

  let content = frontmatter;

  if (opts.ai) {
    const aiContent = await generateWithAI(opts.title, category);
    if (aiContent) {
      // frontmatter + AI 생성 본문
      content = `---
title: "${opts.title}"
description: ""
date: "${today}"
category: "${category}"
tags: []
thumbnail: ""
published: false
coupangLinks:
  - name: "상품명"
    price: 0
    link: "https://link.coupang.com/your-link"
    image: ""
    rating: 0
    pros:
      - "장점 1"
    cons:
      - "단점 1"
---

${aiContent}
`;
    }
  }

  const filePath = path.join(POSTS_DIR, `${slug}.mdx`);
  fs.writeFileSync(filePath, content, "utf-8");

  console.log(`\n✅ 포스트 생성 완료!`);
  console.log(`   파일: content/posts/${slug}.mdx`);
  console.log(`   URL:  /posts/${slug}`);
  console.log(`\n📝 다음 단계:`);
  console.log(`   1. description, tags 채우기`);
  console.log(`   2. coupangLinks에 실제 파트너스 링크 넣기`);
  console.log(`   3. published: true로 변경`);
  console.log(`   4. npm run dev로 확인`);
}

main();

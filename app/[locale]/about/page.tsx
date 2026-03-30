import { Metadata } from "next";
import { siteConfig } from "@/lib/config";

export const metadata: Metadata = {
  title: "소개",
  description: `${siteConfig.name} - ${siteConfig.description}`,
};

export default function AboutPage() {
  return (
    <div className="pt-28 pb-20 max-w-3xl mx-auto px-6">
      <header className="mb-12">
        <div className="flex items-center gap-3 mb-4">
          <span className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-primary text-white text-xl font-bold">
            AI
          </span>
          <h1 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline">
            {siteConfig.name}
          </h1>
        </div>
        <p className="text-lg text-on-surface-variant leading-relaxed">
          {siteConfig.description}
        </p>
      </header>

      <div className="prose max-w-none">
        <h2>왜 AI 브리핑인가요?</h2>
        <p>
          AI 기술은 빠르게 발전하고 있지만, 정보가 너무 많고 어렵게 쓰여 있어서
          따라가기 어렵습니다. AI 브리핑은 이런 정보 격차를 줄이기 위해 만들었습니다.
        </p>
        <ul>
          <li>영어 논문/뉴스를 쉬운 한국어로 번역 및 정리</li>
          <li>정부 AI 지원사업을 쉽게 설명하고 신청 방법 안내</li>
          <li>실전에서 바로 쓸 수 있는 AI 도구 가이드</li>
          <li>비전공자도 이해할 수 있는 AI 개념 설명</li>
        </ul>

        <h2>카테고리</h2>
        <ul>
          {siteConfig.categories.map((cat) => (
            <li key={cat.slug}>
              <a href={`/categories/${cat.slug}`}>
                {cat.emoji} <strong>{cat.name}</strong>
              </a>
            </li>
          ))}
        </ul>

        <h2>콘텐츠 제작 방법</h2>
        <ol>
          <li>정부 사이트, 뉴스, 논문 등에서 원본 정보 수집</li>
          <li>AI를 활용한 1차 요약 및 정리</li>
          <li>에디터의 사실 확인 및 쉬운 설명 추가</li>
          <li>SEO 최적화 후 발행</li>
        </ol>

        <blockquote>{siteConfig.disclaimer}</blockquote>

        <h2>문의</h2>
        <p>
          콘텐츠 관련 문의사항이나 제보는 사이트 운영자에게 연락해주세요.
        </p>
      </div>
    </div>
  );
}

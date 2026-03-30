import { Metadata } from "next";
import Image from "next/image";
import { siteConfig } from "@/lib/config";
import { getAllPosts } from "@/lib/posts";

export const metadata: Metadata = {
  title: "소개",
  description: `${siteConfig.name} - ${siteConfig.description}`,
};

export default function AboutPage() {
  const posts = getAllPosts();

  return (
    <div>
      {/* ── Hero ── */}
      <section className="relative min-h-[360px] flex items-end overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-[#0F0B2E] via-[#1a1145] to-[#0c1a3a]" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_70%_30%,rgba(99,102,241,0.12),transparent_60%)]" />
        <div className="relative w-full max-w-4xl mx-auto px-6 pb-16 pt-32">
          <div className="flex items-center gap-4 mb-5">
            <span className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-white text-primary text-xl font-extrabold shadow-lg">
              AI
            </span>
            <h1 className="text-4xl lg:text-5xl font-extrabold text-white font-headline tracking-tight">
              브리핑
            </h1>
          </div>
          <p className="text-lg text-white/60 leading-relaxed max-w-xl">
            {siteConfig.description}
          </p>
        </div>
      </section>

      {/* ── 왜 AI 브리핑인가요 ── */}
      <section className="py-20 max-w-4xl mx-auto px-6">
        <div className="grid lg:grid-cols-2 gap-12 items-start">
          <div>
            <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">About the Blog</p>
            <h2 className="text-2xl lg:text-3xl font-bold text-on-surface font-headline mb-5 leading-tight">
              왜 AI 브리핑인가요?
            </h2>
            <div className="space-y-4 text-on-surface-variant leading-relaxed">
              <p>
                AI 기술은 빠르게 발전하고 있지만, 정보가 너무 많고 어렵게 쓰여 있어서
                따라가기 어렵습니다. AI 브리핑은 이런 정보 격차를 줄이기 위해 만들었습니다.
              </p>
              <p>
                복잡한 AI 소식을 누구나 이해할 수 있게 정리하고,
                실제로 활용할 수 있는 가이드를 제공합니다.
              </p>
            </div>
          </div>
          <div className="space-y-3">
            {[
              { icon: "translate", text: "영어 논문/뉴스를 쉬운 한국어로 번역 및 정리" },
              { icon: "account_balance", text: "정부 AI 지원사업을 쉽게 설명하고 신청 방법 안내" },
              { icon: "build", text: "실전에서 바로 쓸 수 있는 AI 도구 가이드" },
              { icon: "school", text: "비전공자도 이해할 수 있는 AI 개념 설명" },
            ].map((item) => (
              <div key={item.icon} className="flex items-start gap-3 p-4 rounded-xl bg-slate-50 border border-slate-200/60">
                <span className="material-symbols-outlined text-primary text-lg mt-0.5">{item.icon}</span>
                <p className="text-sm text-on-surface leading-relaxed">{item.text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── 카테고리 ── */}
      <section className="py-16 bg-slate-50">
        <div className="max-w-4xl mx-auto px-6">
          <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">Categories</p>
          <h2 className="text-2xl font-bold text-on-surface font-headline mb-8">다루는 주제</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {siteConfig.categories.map((cat) => (
              <a
                key={cat.slug}
                href={`/categories/${cat.slug}`}
                className="group flex items-center gap-3 p-4 rounded-xl bg-white border border-slate-200/60 hover:border-primary/30 hover:shadow-md transition-all"
              >
                <span className="text-2xl">{cat.emoji}</span>
                <span className="text-sm font-bold text-on-surface group-hover:text-primary transition-colors">{cat.name}</span>
              </a>
            ))}
          </div>
        </div>
      </section>

      {/* ── 콘텐츠 제작 방법 ── */}
      <section className="py-20 max-w-4xl mx-auto px-6">
        <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">How We Work</p>
        <h2 className="text-2xl font-bold text-on-surface font-headline mb-10">콘텐츠 제작 과정</h2>
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {[
            { step: "01", icon: "search", title: "정보 수집", desc: "정부 사이트, 뉴스, 논문 등에서 원본 정보를 수집합니다" },
            { step: "02", icon: "smart_toy", title: "AI 분석", desc: "AI를 활용해 핵심 내용을 요약하고 정리합니다" },
            { step: "03", icon: "fact_check", title: "검수", desc: "사실 확인 후 쉬운 설명을 추가합니다" },
            { step: "04", icon: "publish", title: "발행", desc: "SEO 최적화 후 자동으로 발행합니다" },
          ].map((item) => (
            <div key={item.step} className="text-center">
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-primary/10 mb-4">
                <span className="material-symbols-outlined text-primary text-2xl">{item.icon}</span>
              </div>
              <div className="text-[10px] font-bold text-primary tracking-wider mb-2">STEP {item.step}</div>
              <h3 className="font-bold text-on-surface mb-2">{item.title}</h3>
              <p className="text-xs text-on-surface-variant leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── 실적 ── */}
      <section className="py-14 bg-slate-50 border-y border-slate-100">
        <div className="max-w-4xl mx-auto px-6">
          <div className="flex flex-wrap items-center justify-center gap-10 lg:gap-16">
            {[
              { num: `${posts.length}+`, label: "발행된 글" },
              { num: `${siteConfig.categories.length}`, label: "카테고리" },
              { num: "24/7", label: "자동 운영" },
              { num: "100%", label: "SEO 최적화" },
            ].map((stat, i) => (
              <div key={stat.label} className="flex items-center gap-10 lg:gap-16">
                {i > 0 && <div className="w-px h-10 bg-slate-200 -ml-10 lg:-ml-16 hidden sm:block" />}
                <div className="text-center">
                  <p className="text-3xl font-extrabold text-on-surface font-headline">{stat.num}</p>
                  <p className="text-xs text-slate-400 mt-1">{stat.label}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          회사 소개 — SERO AI
          ═══════════════════════════════════════════ */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6">
          <div className="grid lg:grid-cols-5 gap-12 items-start">
            {/* 왼쪽: 회사 정보 (3/5) */}
            <div className="lg:col-span-3">
              <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">About the Company</p>
              <h2 className="text-2xl lg:text-3xl font-bold text-on-surface font-headline mb-2 leading-tight">
                세로에이아이 (SERO AI)
              </h2>
              <p className="text-sm text-slate-400 mb-6">AI 브리핑을 만들고 운영하는 회사입니다.</p>

              <div className="space-y-4 text-on-surface-variant leading-relaxed">
                <p>
                  세로에이아이는 AI 기술을 활용한 콘텐츠 자동화와 디지털 마케팅 솔루션을 제공합니다.
                  AI 브리핑 블로그는 저희 기술력의 라이브 데모이자, 누구나 AI를 쉽게 이해하고 활용할 수 있도록 돕는 미디어입니다.
                </p>
                <p>
                  블로그 구축부터 콘텐츠 자동화, SEO 최적화, 수익화까지 —
                  직접 해보고 검증한 기술을 바탕으로, 기업과 개인의 온라인 성장을 지원합니다.
                </p>
              </div>

              {/* 핵심 역량 */}
              <div className="mt-8 grid sm:grid-cols-2 gap-3">
                {[
                  { icon: "edit_note", label: "AI 콘텐츠 자동화" },
                  { icon: "travel_explore", label: "SEO · AEO · GEO 최적화" },
                  { icon: "web", label: "웹사이트 · 블로그 구축" },
                  { icon: "smart_toy", label: "AI 파이프라인 개발" },
                ].map((item) => (
                  <div key={item.label} className="flex items-center gap-2.5 p-3 rounded-lg bg-slate-50 border border-slate-200/60">
                    <span className="material-symbols-outlined text-primary text-lg">{item.icon}</span>
                    <span className="text-sm font-medium text-on-surface">{item.label}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* 오른쪽: 회사 정보 카드 (2/5) */}
            <div className="lg:col-span-2">
              <div className="rounded-2xl bg-gradient-to-br from-[#0F0B2E] to-[#1a1145] p-6 lg:p-8 text-white">
                <div className="flex items-center gap-3 mb-6">
                  <span className="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-white text-primary text-sm font-extrabold">
                    AI
                  </span>
                  <div>
                    <p className="font-bold text-sm">SERO AI</p>
                    <p className="text-[11px] text-white/40">세로에이아이</p>
                  </div>
                </div>

                <div className="space-y-4 text-sm">
                  {[
                    { label: "사업 분야", value: "AI 콘텐츠 자동화 · 디지털 마케팅" },
                    { label: "주요 서비스", value: "블로그 구축, SEO 최적화, AI 파이프라인" },
                    { label: "기술 스택", value: "Next.js, Claude API, Python, Vercel" },
                    { label: "웹사이트", value: "seroai.xyz" },
                    { label: "이메일", value: "contact@seroai.xyz" },
                  ].map((item) => (
                    <div key={item.label}>
                      <p className="text-[10px] font-bold text-white/30 uppercase tracking-wider mb-1">{item.label}</p>
                      <p className="text-white/80">{item.value}</p>
                    </div>
                  ))}
                </div>

                <div className="mt-6 pt-6 border-t border-white/10">
                  <a
                    href="/business"
                    className="inline-flex items-center gap-2 text-xs font-semibold text-indigo-300 hover:text-white transition-colors"
                  >
                    서비스 자세히 보기
                    <span className="material-symbols-outlined text-xs">arrow_forward</span>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── 문의 CTA ── */}
      <section className="pb-20">
        <div className="max-w-4xl mx-auto px-6">
          <div className="rounded-2xl bg-slate-50 border border-slate-200/80 p-8 lg:p-12 text-center">
            <h2 className="text-xl font-bold text-on-surface font-headline mb-3">문의</h2>
            <p className="text-sm text-on-surface-variant mb-6 max-w-md mx-auto leading-relaxed">
              콘텐츠 관련 문의, 비즈니스 제안, 또는 궁금한 점이 있으시면 편하게 연락주세요.
            </p>
            <a
              href="mailto:contact@seroai.xyz"
              className="inline-flex items-center gap-2 px-7 py-3.5 bg-primary text-white font-bold text-sm rounded-full hover:bg-indigo-700 transition-colors shadow-lg shadow-primary/20"
            >
              <span className="material-symbols-outlined text-base">mail</span>
              contact@seroai.xyz
            </a>
          </div>

          <p className="mt-8 text-xs text-slate-400 text-center leading-relaxed max-w-2xl mx-auto">
            {siteConfig.disclaimer}
          </p>
        </div>
      </section>
    </div>
  );
}

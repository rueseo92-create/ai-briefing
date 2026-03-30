import { Metadata } from "next";
import { siteConfig } from "@/lib/config";
import { getAllPosts } from "@/lib/posts";

export const metadata: Metadata = {
  title: "회사 소개 | SERO AI",
  description: "세로에이아이(SERO AI) — 헬스케어와 AI를 잇는 콘텐츠 자동화 · 디지털 마케팅 전문 기업",
};

export default function AboutPage() {
  const posts = getAllPosts();

  return (
    <div>
      {/* ── Hero ── */}
      <section className="relative min-h-[400px] flex items-end overflow-hidden grain">
        <div className="absolute inset-0 bg-gradient-to-br from-[#0F0B2E] via-[#1a1145] to-[#0c1a3a]" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_70%_30%,rgba(99,102,241,0.12),transparent_60%)]" />
        <div className="relative w-full max-w-5xl mx-auto px-6 pb-16 pt-36">
          <p className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 border border-white/10 text-white/60 text-xs font-medium mb-6">
            <span className="w-2 h-2 bg-indigo-400 rounded-full animate-pulse" />
            About SERO AI
          </p>
          <h1 className="text-4xl lg:text-6xl font-extrabold text-white font-headline tracking-tight leading-[1.05] mb-5">
            세로에이아이
          </h1>
          <p className="text-lg text-white/50 leading-relaxed max-w-xl">
            Healthcare meets AI — 헬스케어 전문성과 AI 기술을 결합해<br className="hidden lg:block" />
            콘텐츠 자동화와 디지털 성장 솔루션을 만듭니다.
          </p>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          회사 소개
          ═══════════════════════════════════════════ */}
      <section className="py-20 lg:py-24">
        <div className="max-w-5xl mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-14 items-start">
            <div>
              <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">Company</p>
              <h2 className="text-2xl lg:text-3xl font-bold text-on-surface font-headline mb-6 leading-tight">
                기술과 도메인 전문성이<br />만나는 곳
              </h2>
              <div className="space-y-4 text-on-surface-variant leading-relaxed">
                <p>
                  세로에이아이(SERO AI)는 AI 기술 기반 콘텐츠 자동화와 디지털 마케팅 솔루션을 제공하는 기업입니다.
                </p>
                <p>
                  대표는 한국과 미국 간호사(RN) 면허를 보유한 의료 전문가이자,
                  디지털헬스 석·박사 과정을 거친 연구자입니다.
                  스타트업에서 마케팅부터 프로덕트 개발까지 전 과정을 직접 경험하며,
                  도메인 지식과 기술 역량을 동시에 갖추었습니다.
                </p>
                <p>
                  이 독특한 교차점 — 헬스케어의 엄격한 근거 기반 사고와,
                  스타트업의 빠른 실행력, AI 기술의 확장성 — 이 세로에이아이의 핵심입니다.
                </p>
              </div>
            </div>

            {/* 회사 정보 카드 */}
            <div className="rounded-2xl bg-gradient-to-br from-[#0F0B2E] to-[#1a1145] p-6 lg:p-8 text-white">
              <div className="flex items-center gap-3 mb-7">
                <span className="inline-flex items-center justify-center w-11 h-11 rounded-xl bg-white text-primary text-sm font-extrabold">
                  AI
                </span>
                <div>
                  <p className="font-bold">SERO AI</p>
                  <p className="text-[11px] text-white/40">세로에이아이</p>
                </div>
              </div>

              <div className="space-y-5 text-sm">
                {[
                  { label: "사업 분야", value: "AI 콘텐츠 자동화 · 디지털 마케팅 · 헬스테크" },
                  { label: "주요 서비스", value: "블로그/웹사이트 구축, SEO 최적화, AI 파이프라인 개발, 콘텐츠 대행" },
                  { label: "기술 스택", value: "Next.js · TypeScript · Python · Claude API · Vercel" },
                  { label: "웹사이트", value: "seroai.xyz" },
                  { label: "이메일", value: "contact@seroai.xyz" },
                ].map((item) => (
                  <div key={item.label}>
                    <p className="text-[10px] font-bold text-white/30 uppercase tracking-wider mb-1">{item.label}</p>
                    <p className="text-white/80">{item.value}</p>
                  </div>
                ))}
              </div>

              <div className="mt-7 pt-6 border-t border-white/10 flex gap-4">
                <a href="/business" className="inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-300 hover:text-white transition-colors">
                  서비스 보기 <span className="material-symbols-outlined text-xs">arrow_forward</span>
                </a>
                <a href="mailto:contact@seroai.xyz" className="inline-flex items-center gap-1.5 text-xs font-semibold text-white/40 hover:text-white transition-colors">
                  문의하기 <span className="material-symbols-outlined text-xs">mail</span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          대표 프로필
          ═══════════════════════════════════════════ */}
      <section className="py-20 bg-slate-50">
        <div className="max-w-5xl mx-auto px-6">
          <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">Founder</p>
          <h2 className="text-2xl lg:text-3xl font-bold text-on-surface font-headline mb-12 leading-tight">
            대표 소개
          </h2>

          <div className="grid lg:grid-cols-3 gap-8">
            {/* 프로필 요약 */}
            <div className="lg:col-span-1">
              <div className="rounded-2xl bg-white ring-1 ring-slate-200/60 p-6 text-center">
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-indigo-500 to-violet-600 mx-auto mb-4 flex items-center justify-center">
                  <span className="material-symbols-outlined text-white text-3xl">person</span>
                </div>
                <h3 className="font-bold text-on-surface text-lg font-headline">Founder & CEO</h3>
                <p className="text-xs text-slate-400 mt-1 mb-5">세로에이아이 대표</p>

                <div className="space-y-2.5 text-left">
                  {[
                    { icon: "local_hospital", text: "한국 · 미국 RN (간호사 면허)" },
                    { icon: "school", text: "디지털헬스학과 석·박사" },
                    { icon: "rocket_launch", text: "스타트업 창업 · 운영 경험" },
                    { icon: "code", text: "풀스택 개발 (마케팅 → 개발)" },
                  ].map((item) => (
                    <div key={item.icon} className="flex items-start gap-2.5 text-sm text-on-surface-variant">
                      <span className="material-symbols-outlined text-primary text-base mt-0.5">{item.icon}</span>
                      <span>{item.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* 상세 경력 */}
            <div className="lg:col-span-2 space-y-6">
              {[
                {
                  icon: "medical_services",
                  color: "bg-rose-500",
                  title: "헬스케어 전문성",
                  subtitle: "한국 · 미국 RN 면허 / 디지털헬스 석·박사",
                  desc: "임상 현장에서 시작해 디지털헬스 연구까지. 데이터 기반 의사결정과 근거 중심 사고가 체질입니다. 복잡한 정보를 정확하게 정리하고 쉽게 전달하는 능력은 여기서 비롯됐습니다.",
                },
                {
                  icon: "trending_up",
                  color: "bg-amber-500",
                  title: "스타트업 & 마케팅",
                  subtitle: "스타트업 창업 · 운영 / 마케팅 전략 · 실행",
                  desc: "스타트업에서 마케팅 전략 수립부터 콘텐츠 제작, 퍼포먼스 분석, 그로스 해킹까지 직접 실행했습니다. 이론이 아닌, 실제로 성과를 만들어본 경험이 서비스에 반영됩니다.",
                },
                {
                  icon: "terminal",
                  color: "bg-indigo-500",
                  title: "개발 & AI 기술",
                  subtitle: "풀스택 개발 / AI 파이프라인 설계 · 구현",
                  desc: "Next.js, Python, Claude API를 활용한 콘텐츠 자동화 파이프라인을 직접 설계하고 구축합니다. 기획부터 개발, 배포, 운영까지 전 과정을 한 사람이 커버합니다.",
                },
              ].map((item) => (
                <div key={item.title} className="flex gap-4 p-5 rounded-2xl bg-white ring-1 ring-slate-200/60">
                  <div className={`w-10 h-10 rounded-xl ${item.color} flex items-center justify-center flex-shrink-0`}>
                    <span className="material-symbols-outlined text-white text-lg">{item.icon}</span>
                  </div>
                  <div>
                    <h4 className="font-bold text-on-surface mb-0.5">{item.title}</h4>
                    <p className="text-xs text-primary font-medium mb-2">{item.subtitle}</p>
                    <p className="text-sm text-on-surface-variant leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          핵심 역량
          ═══════════════════════════════════════════ */}
      <section className="py-20">
        <div className="max-w-5xl mx-auto px-6">
          <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">What We Do</p>
          <h2 className="text-2xl font-bold text-on-surface font-headline mb-10">서비스 영역</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {[
              { icon: "edit_note", title: "AI 콘텐츠 자동화", desc: "매일 SEO 최적화된 글을 자동으로 생성·발행" },
              { icon: "travel_explore", title: "SEO · AEO · GEO", desc: "검색엔진 + AI 검색엔진 동시 최적화" },
              { icon: "web", title: "웹사이트 구축", desc: "기획부터 디자인, 개발, 배포까지 원스톱" },
              { icon: "smart_toy", title: "AI 파이프라인", desc: "크롤링 → 생성 → 발행 → 분석 전체 자동화" },
            ].map((item) => (
              <div key={item.title} className="rounded-2xl bg-slate-50 border border-slate-200/60 p-6 hover:border-primary/30 hover:shadow-md transition-all">
                <div className="w-11 h-11 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                  <span className="material-symbols-outlined text-primary text-xl">{item.icon}</span>
                </div>
                <h3 className="font-bold text-on-surface mb-2">{item.title}</h3>
                <p className="text-xs text-on-surface-variant leading-relaxed">{item.desc}</p>
              </div>
            ))}
          </div>
          <div className="mt-8 text-center">
            <a href="/business" className="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:text-indigo-700 transition-colors">
              서비스 상세 보기 <span className="material-symbols-outlined text-sm">arrow_forward</span>
            </a>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          AI 브리핑 — 운영 프로젝트
          ═══════════════════════════════════════════ */}
      <section className="py-20 bg-slate-50">
        <div className="max-w-5xl mx-auto px-6">
          <div className="grid lg:grid-cols-5 gap-12 items-center">
            <div className="lg:col-span-3">
              <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">Live Project</p>
              <h2 className="text-2xl lg:text-3xl font-bold text-on-surface font-headline mb-5 leading-tight">
                AI 브리핑
              </h2>
              <p className="text-sm text-slate-400 mb-5">세로에이아이의 기술력으로 운영되는 AI 미디어</p>
              <div className="space-y-4 text-on-surface-variant leading-relaxed">
                <p>
                  AI 브리핑은 세로에이아이의 콘텐츠 자동화 기술을 100% 적용한 라이브 프로젝트입니다.
                  AI 뉴스, 정부사업, 도구 리뷰, 튜토리얼을 매일 자동으로 발행하며,
                  저희가 제공하는 서비스가 실제로 어떻게 작동하는지 직접 보여드립니다.
                </p>
                <p>
                  클롤링부터 AI 글 생성, SEO 최적화, 자동 발행, 수익화까지 —
                  모든 파이프라인이 이 블로그에서 실시간으로 돌아가고 있습니다.
                </p>
              </div>
              <div className="mt-6 flex gap-4">
                <a href="/" className="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-white font-bold text-sm rounded-full hover:bg-indigo-700 transition-colors shadow-md shadow-primary/20">
                  블로그 보기 <span className="material-symbols-outlined text-base">arrow_forward</span>
                </a>
                <a href="/posts" className="inline-flex items-center gap-2 px-5 py-2.5 bg-white text-on-surface font-bold text-sm rounded-full border border-slate-200 hover:border-primary hover:text-primary transition-all">
                  전체 글 보기
                </a>
              </div>
            </div>

            {/* 수치 */}
            <div className="lg:col-span-2">
              <div className="grid grid-cols-2 gap-4">
                {[
                  { num: `${posts.length}+`, label: "발행된 글", icon: "article" },
                  { num: "24/7", label: "자동 운영", icon: "schedule" },
                  { num: `${siteConfig.categories.length}`, label: "카테고리", icon: "category" },
                  { num: "100%", label: "SEO 최적화", icon: "trending_up" },
                ].map((s) => (
                  <div key={s.label} className="rounded-2xl bg-white ring-1 ring-slate-200/60 p-5 text-center">
                    <span className="material-symbols-outlined text-primary text-lg mb-2 block">{s.icon}</span>
                    <p className="text-2xl font-extrabold text-on-surface font-headline">{s.num}</p>
                    <p className="text-[10px] text-slate-400 mt-1">{s.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── CTA ── */}
      <section className="py-20">
        <div className="max-w-5xl mx-auto px-6">
          <div className="relative rounded-2xl overflow-hidden grain">
            <div className="absolute inset-0 bg-gradient-to-br from-[#0F0B2E] via-[#1a1145] to-[#0c1a3a]" />
            <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_30%_50%,rgba(99,102,241,0.1),transparent_60%)]" />
            <div className="relative p-10 lg:p-16 text-center">
              <h2 className="text-2xl lg:text-3xl font-bold text-white font-headline mb-4">
                함께 만들어 볼까요?
              </h2>
              <p className="text-sm text-white/40 mb-8 max-w-md mx-auto leading-relaxed">
                비즈니스 문의, 협업 제안, 또는 궁금한 점이 있으시면 편하게 연락주세요.
              </p>
              <a
                href="mailto:contact@seroai.xyz"
                className="inline-flex items-center gap-2 px-8 py-4 bg-white text-[#0F0B2E] font-bold text-sm rounded-full hover:bg-indigo-100 transition-colors shadow-[0_0_40px_rgba(99,102,241,0.15)]"
              >
                <span className="material-symbols-outlined text-base">mail</span>
                contact@seroai.xyz
              </a>
              <p className="mt-5 text-white/20 text-xs">보통 하루 안에 답장드려요</p>
            </div>
          </div>

          <p className="mt-10 text-xs text-slate-400 text-center leading-relaxed max-w-2xl mx-auto">
            {siteConfig.disclaimer}
          </p>
        </div>
      </section>
    </div>
  );
}

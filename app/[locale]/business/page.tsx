import { Metadata } from "next";
import { siteConfig } from "@/lib/config";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

export const metadata: Metadata = {
  title: "Business | SERO AI",
  description: "AI 콘텐츠 자동화, SEO 최적화, 블로그 구축 — SERO AI가 제공하는 올인원 AI 솔루션",
};

export default async function BusinessPage({ params }: { params: { locale: string } }) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);

  return (
    <div className="bg-white">
      {/* ── Hero ── */}
      <section className="relative pt-32 pb-24 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900" />
        <div className="absolute inset-0 opacity-20" style={{ backgroundImage: "radial-gradient(circle at 25% 50%, #4F46E5 0%, transparent 50%), radial-gradient(circle at 75% 50%, #0891B2 0%, transparent 50%)" }} />
        <div className="relative max-w-6xl mx-auto px-6 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 text-white/80 text-xs font-medium mb-8">
            <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
            AI-Powered Solutions
          </div>
          <h1 className="text-5xl lg:text-7xl font-extrabold text-white leading-[1.05] tracking-tight font-headline mb-6">
            AI로 비즈니스를<br />
            <span className="bg-gradient-to-r from-indigo-400 via-cyan-400 to-emerald-400 bg-clip-text text-transparent">
              자동화하세요
            </span>
          </h1>
          <p className="text-lg lg:text-xl text-white/70 max-w-2xl mx-auto mb-10 leading-relaxed">
            콘텐츠 생성부터 SEO 최적화, 다국어 배포까지.<br />
            SERO AI가 검증된 파이프라인으로 비즈니스 성장을 가속합니다.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a href="#contact" className="px-8 py-4 bg-white text-slate-900 font-bold rounded-xl hover:bg-slate-100 transition-colors shadow-xl shadow-white/10 text-sm">
              무료 상담 신청
            </a>
            <a href="#services" className="px-8 py-4 bg-white/10 text-white font-bold rounded-xl hover:bg-white/20 transition-colors border border-white/20 backdrop-blur-sm text-sm">
              서비스 살펴보기
            </a>
          </div>
        </div>
      </section>

      {/* ── Stats ── */}
      <section className="relative -mt-12 z-10 max-w-5xl mx-auto px-6">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { num: "29+", label: "자동 발행 콘텐츠", icon: "article" },
            { num: "5", label: "지원 언어", icon: "language" },
            { num: "24/7", label: "자동 운영", icon: "schedule" },
            { num: "100%", label: "SEO 최적화", icon: "trending_up" },
          ].map((s) => (
            <div key={s.label} className="bg-white rounded-2xl p-6 shadow-lg shadow-slate-200/50 border border-slate-100 text-center">
              <span className="material-symbols-outlined text-primary text-2xl mb-2 block">{s.icon}</span>
              <p className="text-3xl font-extrabold text-on-surface font-headline">{s.num}</p>
              <p className="text-xs text-on-surface-variant mt-1">{s.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Services ── */}
      <section id="services" className="pt-28 pb-20 max-w-6xl mx-auto px-6">
        <div className="text-center mb-16">
          <span className="inline-flex items-center px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold mb-4 tracking-wider uppercase">
            Services
          </span>
          <h2 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-4">
            제공 서비스
          </h2>
          <p className="text-on-surface-variant max-w-xl mx-auto">
            AI 기술을 활용한 콘텐츠 자동화부터 비즈니스 성장 전략까지
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[
            {
              icon: "edit_note",
              title: "AI 콘텐츠 자동화",
              desc: "Claude API 기반 고품질 블로그 콘텐츠를 자동 생성합니다. SEO 최적화, GEO 최적화, 출처 인용까지 포함된 전문 콘텐츠를 매일 자동 발행합니다.",
              tags: ["Claude API", "MDX", "자동 발행"],
              accent: "from-indigo-500 to-blue-600",
            },
            {
              icon: "travel_explore",
              title: "SEO / AEO / GEO 최적화",
              desc: "검색엔진은 물론 ChatGPT, Perplexity 같은 AI 검색엔진에도 노출되는 콘텐츠 전략을 구축합니다. 구조화 데이터, 메타태그, llms.txt까지.",
              tags: ["Schema.org", "hreflang", "AI 검색"],
              accent: "from-emerald-500 to-teal-600",
            },
            {
              icon: "language",
              title: "다국어 자동 배포",
              desc: "한국어 콘텐츠를 영어, 중국어, 일본어, 스페인어로 UI 자동 전환. 글로벌 트래픽을 확보하고 해외 유입을 극대화합니다.",
              tags: ["5개 언어", "hreflang SEO", "자동 라우팅"],
              accent: "from-violet-500 to-purple-600",
            },
            {
              icon: "web",
              title: "Next.js 블로그 구축",
              desc: "Next.js 14 + MDX 기반 초고속 정적 블로그를 구축합니다. Vercel 배포, 자동 CI/CD, Google Analytics, AdSense 연동까지 원스톱 세팅.",
              tags: ["Next.js 14", "Vercel", "MDX"],
              accent: "from-cyan-500 to-blue-600",
            },
            {
              icon: "campaign",
              title: "SNS 자동 발행",
              desc: "블로그 콘텐츠를 Threads, Instagram에 자동 변환 발행합니다. 플랫폼별 최적화된 포맷으로 추가 트래픽을 확보합니다.",
              tags: ["Threads API", "Instagram", "자동화"],
              accent: "from-pink-500 to-rose-600",
            },
            {
              icon: "monetization_on",
              title: "수익화 연동",
              desc: "쿠팡 파트너스, Google AdSense 등 수익화 채널을 자동 연동합니다. 콘텐츠 태그 기반 관련 상품 추천으로 전환율을 높입니다.",
              tags: ["쿠팡 파트너스", "AdSense", "어필리에이트"],
              accent: "from-amber-500 to-orange-600",
            },
          ].map((service) => (
            <div
              key={service.title}
              className="group relative bg-white rounded-2xl p-8 border border-slate-200/80 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/5 transition-all duration-300"
            >
              <div className={`inline-flex items-center justify-center w-12 h-12 rounded-xl bg-gradient-to-br ${service.accent} text-white mb-5`}>
                <span className="material-symbols-outlined text-2xl">{service.icon}</span>
              </div>
              <h3 className="text-lg font-extrabold text-on-surface mb-3 font-headline">
                {service.title}
              </h3>
              <p className="text-sm text-on-surface-variant leading-relaxed mb-4">
                {service.desc}
              </p>
              <div className="flex flex-wrap gap-1.5">
                {service.tags.map((tag) => (
                  <span key={tag} className="px-2 py-0.5 bg-slate-50 border border-slate-100 rounded text-[10px] text-slate-500 font-medium">
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── Tech Stack ── */}
      <section className="py-20 bg-slate-50 border-y border-slate-200/50">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-14">
            <span className="inline-flex items-center px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold mb-4 tracking-wider uppercase">
              Tech Stack
            </span>
            <h2 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-4">
              검증된 기술 스택
            </h2>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            {[
              { name: "Next.js 14", desc: "프레임워크" },
              { name: "Claude API", desc: "AI 콘텐츠" },
              { name: "Vercel", desc: "배포/CDN" },
              { name: "Tailwind CSS", desc: "디자인" },
              { name: "MDX", desc: "콘텐츠 포맷" },
              { name: "GitHub Actions", desc: "CI/CD" },
              { name: "Schema.org", desc: "구조화 데이터" },
              { name: "Google Analytics", desc: "분석" },
              { name: "TypeScript", desc: "타입 안정성" },
              { name: "Threads API", desc: "SNS 자동화" },
              { name: "Google AdSense", desc: "광고 수익" },
              { name: "Coupang Partners", desc: "어필리에이트" },
            ].map((tech) => (
              <div key={tech.name} className="bg-white rounded-xl p-4 border border-slate-200/80 text-center hover:border-primary/30 transition-colors">
                <p className="text-sm font-bold text-on-surface">{tech.name}</p>
                <p className="text-[10px] text-on-surface-variant mt-0.5">{tech.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Process ── */}
      <section className="py-24 max-w-5xl mx-auto px-6">
        <div className="text-center mb-16">
          <span className="inline-flex items-center px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold mb-4 tracking-wider uppercase">
            Process
          </span>
          <h2 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-4">
            진행 프로세스
          </h2>
        </div>
        <div className="grid md:grid-cols-4 gap-8">
          {[
            { step: "01", title: "상담", desc: "비즈니스 목표와 콘텐츠 전략을 파악합니다", icon: "handshake" },
            { step: "02", title: "구축", desc: "블로그 + AI 파이프라인을 세팅합니다", icon: "construction" },
            { step: "03", title: "자동화", desc: "콘텐츠 자동 생성·발행 시스템을 가동합니다", icon: "smart_toy" },
            { step: "04", title: "성장", desc: "데이터 기반으로 최적화하고 확장합니다", icon: "rocket_launch" },
          ].map((p) => (
            <div key={p.step} className="text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-500 to-cyan-500 text-white mb-5 shadow-lg shadow-primary/20">
                <span className="material-symbols-outlined text-3xl">{p.icon}</span>
              </div>
              <div className="text-xs font-bold text-primary mb-2 tracking-wider">{p.step}</div>
              <h3 className="text-lg font-extrabold text-on-surface font-headline mb-2">{p.title}</h3>
              <p className="text-sm text-on-surface-variant leading-relaxed">{p.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Portfolio / Live Demo ── */}
      <section className="py-20 bg-gradient-to-br from-indigo-50 via-white to-cyan-50 border-y border-slate-200/50">
        <div className="max-w-5xl mx-auto px-6 text-center">
          <span className="inline-flex items-center px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold mb-4 tracking-wider uppercase">
            Live Demo
          </span>
          <h2 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-4">
            지금 보고 계신 이 사이트가 결과물입니다
          </h2>
          <p className="text-on-surface-variant max-w-xl mx-auto mb-10">
            AI 브리핑 블로그는 SERO AI의 모든 기술이 적용된 라이브 데모입니다.
            직접 둘러보세요.
          </p>
          <div className="grid sm:grid-cols-3 gap-4 max-w-3xl mx-auto">
            <a href={lh("/")} className="bg-white rounded-xl p-6 border border-slate-200/80 hover:border-primary/30 hover:shadow-lg transition-all group">
              <span className="material-symbols-outlined text-3xl text-primary mb-3 block group-hover:scale-110 transition-transform">home</span>
              <p className="font-bold text-on-surface text-sm">블로그 홈</p>
              <p className="text-[10px] text-on-surface-variant mt-1">AI 자동 콘텐츠</p>
            </a>
            <a href={lh("/search")} className="bg-white rounded-xl p-6 border border-slate-200/80 hover:border-primary/30 hover:shadow-lg transition-all group">
              <span className="material-symbols-outlined text-3xl text-primary mb-3 block group-hover:scale-110 transition-transform">search</span>
              <p className="font-bold text-on-surface text-sm">검색 기능</p>
              <p className="text-[10px] text-on-surface-variant mt-1">태그 기반 필터</p>
            </a>
            <a href="/en" className="bg-white rounded-xl p-6 border border-slate-200/80 hover:border-primary/30 hover:shadow-lg transition-all group">
              <span className="material-symbols-outlined text-3xl text-primary mb-3 block group-hover:scale-110 transition-transform">language</span>
              <p className="font-bold text-on-surface text-sm">다국어 전환</p>
              <p className="text-[10px] text-on-surface-variant mt-1">5개 언어 지원</p>
            </a>
          </div>
        </div>
      </section>

      {/* ── CTA / Contact ── */}
      <section id="contact" className="py-24">
        <div className="max-w-3xl mx-auto px-6 text-center">
          <div className="bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900 rounded-3xl p-12 lg:p-16 relative overflow-hidden">
            <div className="absolute inset-0 opacity-20" style={{ backgroundImage: "radial-gradient(circle at 30% 50%, #4F46E5 0%, transparent 50%)" }} />
            <div className="relative">
              <h2 className="text-3xl lg:text-4xl font-extrabold text-white font-headline mb-4 leading-tight">
                AI 자동화,<br />지금 시작하세요
              </h2>
              <p className="text-white/60 mb-8 max-w-md mx-auto leading-relaxed">
                비즈니스에 맞는 AI 콘텐츠 자동화 전략을 무료로 상담해드립니다.
                아래 이메일로 문의하세요.
              </p>
              <a
                href="mailto:contact@seroai.xyz"
                className="inline-flex items-center gap-2 px-8 py-4 bg-white text-slate-900 font-bold rounded-xl hover:bg-slate-100 transition-colors shadow-xl text-sm"
              >
                <span className="material-symbols-outlined text-lg">mail</span>
                contact@seroai.xyz
              </a>
              <p className="mt-6 text-white/40 text-xs">
                24시간 내 회신 드립니다
              </p>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

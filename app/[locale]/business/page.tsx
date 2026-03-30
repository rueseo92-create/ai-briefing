import { Metadata } from "next";
import { siteConfig } from "@/lib/config";
import { getAllPosts } from "@/lib/posts";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

export const metadata: Metadata = {
  title: "직접 하기 어려우시다면 | AI 브리핑",
  description: "AI 블로그, SEO, 콘텐츠 자동화 — 다 알려드리지만, 직접 하기 어려우시면 대행해드립니다.",
};

export default async function BusinessPage({ params }: { params: { locale: string } }) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);
  const posts = getAllPosts();

  return (
    <div className="pt-28 pb-20">
      {/* ── Intro ── */}
      <section className="max-w-3xl mx-auto px-6 mb-20">
        <p className="text-sm text-primary font-bold mb-4">솔직하게 말씀드릴게요</p>
        <h1 className="text-3xl lg:text-5xl font-extrabold text-on-surface leading-[1.15] tracking-tight font-headline mb-6">
          이 블로그에서<br />다 알려드려요.
        </h1>
        <div className="space-y-4 text-on-surface-variant text-lg leading-relaxed">
          <p>
            AI 블로그 만드는 법, SEO 최적화, 콘텐츠 자동화 —
            저희가 블로그에 올리는 글만 잘 따라하시면 직접 다 하실 수 있어요.
          </p>
          <p>
            근데 현실적으로, 바쁘시잖아요.
          </p>
          <p className="text-on-surface font-semibold">
            직접 하기 어려우시면, 저희가 대신 해드립니다.
          </p>
        </div>
      </section>

      {/* ── What we actually do ── */}
      <section className="max-w-4xl mx-auto px-6 mb-24">
        <div className="bg-slate-50 rounded-2xl border border-slate-200/80 p-8 lg:p-12">
          <h2 className="text-2xl font-extrabold text-on-surface font-headline mb-2">
            이런 걸 대신 해드려요
          </h2>
          <p className="text-sm text-on-surface-variant mb-8">전부 이 블로그에 직접 적용하고 검증한 것들입니다.</p>

          <div className="space-y-6">
            {[
              {
                icon: "edit_note",
                title: "AI 블로그 글 자동 발행",
                blog: "블로그에 방법 다 있어요",
                agency: "매일 자동으로 SEO 최적화된 글이 올라가게 세팅해드려요",
                link: "/categories/tutorials",
              },
              {
                icon: "travel_explore",
                title: "SEO / 검색엔진 최적화",
                blog: "구글 서치 콘솔 세팅부터 스키마 마크업까지 글로 정리했어요",
                agency: "사이트 분석하고 기술적 SEO 전부 적용해드려요",
                link: "/categories/ai-tools",
              },
              {
                icon: "web",
                title: "블로그 / 웹사이트 구축",
                blog: "Next.js + Vercel 배포하는 법도 튜토리얼에 있어요",
                agency: "기획부터 디자인, 배포, 도메인 연결까지 통째로 만들어드려요",
                link: "/categories/tutorials",
              },
              {
                icon: "smart_toy",
                title: "AI 자동화 파이프라인",
                blog: "Claude API 연동하는 법, 자동화 스크립트 예제도 있어요",
                agency: "크롤링 → AI 글 생성 → 발행 → SNS 공유까지 전부 자동화해드려요",
                link: "/categories/ai-tools",
              },
              {
                icon: "monetization_on",
                title: "수익화 (애드센스, 쿠팡)",
                blog: "쿠팡 파트너스 연동 방법도 포스팅했어요",
                agency: "광고 최적 배치, 어필리에이트 상품 매칭까지 세팅해드려요",
                link: "/posts",
              },
            ].map((item) => (
              <div key={item.title} className="flex gap-5">
                <div className="flex-shrink-0 w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
                  <span className="material-symbols-outlined text-primary text-xl">{item.icon}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-bold text-on-surface mb-2">{item.title}</h3>
                  <div className="grid sm:grid-cols-2 gap-3">
                    <div className="rounded-lg bg-white border border-slate-200 p-3">
                      <p className="text-[10px] font-bold text-emerald-600 uppercase tracking-wider mb-1">직접 하기</p>
                      <p className="text-xs text-on-surface-variant leading-relaxed">{item.blog}</p>
                      <a href={lh(item.link)} className="inline-flex items-center gap-1 text-[10px] text-primary font-semibold mt-2 hover:underline">
                        글 보러 가기 <span className="material-symbols-outlined text-[10px]">arrow_forward</span>
                      </a>
                    </div>
                    <div className="rounded-lg bg-primary/[0.03] border border-primary/10 p-3">
                      <p className="text-[10px] font-bold text-primary uppercase tracking-wider mb-1">대행 맡기기</p>
                      <p className="text-xs text-on-surface-variant leading-relaxed">{item.agency}</p>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── This site is the proof ── */}
      <section className="max-w-3xl mx-auto px-6 mb-24">
        <div className="text-center mb-10">
          <h2 className="text-2xl font-extrabold text-on-surface font-headline mb-3">
            증거요? 지금 보고 계세요.
          </h2>
          <p className="text-on-surface-variant text-sm">
            이 블로그 자체가 저희 기술로 만든 결과물입니다.
          </p>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { num: `${posts.length}`, label: "AI 자동 발행 글", icon: "article" },
            { num: "24/7", label: "무인 자동 운영", icon: "schedule" },
            { num: "0", label: "직접 작성한 글", icon: "person_off" },
            { num: "100%", label: "SEO 최적화율", icon: "trending_up" },
          ].map((s) => (
            <div key={s.label} className="rounded-xl border border-slate-200 p-5 text-center">
              <span className="material-symbols-outlined text-primary text-xl mb-2 block">{s.icon}</span>
              <p className="text-2xl font-extrabold text-on-surface font-headline">{s.num}</p>
              <p className="text-[10px] text-on-surface-variant mt-1">{s.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── How it works ── */}
      <section className="max-w-4xl mx-auto px-6 mb-24">
        <div className="text-center mb-12">
          <h2 className="text-2xl font-extrabold text-on-surface font-headline mb-3">
            진행은 이렇게 됩니다
          </h2>
          <p className="text-on-surface-variant text-sm">
            복잡하지 않아요. 메일 한 통이면 시작됩니다.
          </p>
        </div>

        <div className="relative">
          {/* 연결선 */}
          <div className="hidden md:block absolute top-8 left-[calc(12.5%+20px)] right-[calc(12.5%+20px)] h-0.5 bg-slate-200" />

          <div className="grid md:grid-cols-4 gap-8">
            {[
              {
                step: "01",
                icon: "mail",
                title: "메일로 문의",
                desc: "\"이런 걸 하고 싶어요\" 정도만 보내주세요. 형식 없어도 됩니다.",
                detail: "현재 상황, 원하시는 것, 예산 범위 등 편하게 적어주시면 돼요.",
              },
              {
                step: "02",
                icon: "description",
                title: "분석 & 제안",
                desc: "보내주신 내용을 바탕으로 현재 상태를 분석하고, 맞춤 제안서를 드려요.",
                detail: "견적 + \"직접 하시려면 이렇게 하면 됩니다\" 가이드도 같이 드려요.",
              },
              {
                step: "03",
                icon: "construction",
                title: "구축 & 세팅",
                desc: "합의된 범위대로 작업합니다. 중간중간 진행 상황을 공유드려요.",
                detail: "블로그 구축, AI 파이프라인 세팅, SEO 적용 등 실제 작업 단계예요.",
              },
              {
                step: "04",
                icon: "rocket_launch",
                title: "운영 & 인수인계",
                desc: "완성된 시스템을 넘겨드리고, 직접 운영할 수 있도록 가이드해드려요.",
                detail: "자동화 시스템은 넘긴 후에도 알아서 돌아갑니다. 유지보수도 가능해요.",
              },
            ].map((item) => (
              <div key={item.step} className="relative text-center">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary/10 mb-4 relative z-10 bg-white border border-slate-200">
                  <span className="material-symbols-outlined text-primary text-2xl">{item.icon}</span>
                </div>
                <div className="text-[10px] font-bold text-primary tracking-wider mb-2">STEP {item.step}</div>
                <h3 className="font-extrabold text-on-surface font-headline mb-2">{item.title}</h3>
                <p className="text-sm text-on-surface-variant leading-relaxed mb-2">{item.desc}</p>
                <p className="text-xs text-slate-400 leading-relaxed">{item.detail}</p>
              </div>
            ))}
          </div>
        </div>

        {/* 보충 설명 */}
        <div className="mt-12 grid sm:grid-cols-3 gap-4">
          {[
            {
              icon: "timer",
              title: "소요 기간",
              desc: "간단한 블로그 세팅은 1~2주, 자동화 파이프라인 포함 시 2~4주 정도 걸려요.",
            },
            {
              icon: "sync",
              title: "수정 & 피드백",
              desc: "작업 중 피드백 반영은 무제한이에요. 만족하실 때까지 조정합니다.",
            },
            {
              icon: "support_agent",
              title: "사후 지원",
              desc: "인수인계 후 1개월간 무료 지원. 이후에도 유지보수 계약이 가능해요.",
            },
          ].map((item) => (
            <div key={item.title} className="rounded-xl border border-slate-200 p-5">
              <span className="material-symbols-outlined text-primary text-lg mb-2 block">{item.icon}</span>
              <h4 className="text-sm font-bold text-on-surface mb-1">{item.title}</h4>
              <p className="text-xs text-on-surface-variant leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Pricing Philosophy ── */}
      <section className="max-w-3xl mx-auto px-6 mb-24">
        <div className="rounded-2xl bg-gradient-to-br from-slate-50 to-indigo-50/30 border border-slate-200/80 p-8 lg:p-12">
          <h2 className="text-2xl font-extrabold text-on-surface font-headline mb-6">
            비용은 어떻게 되나요?
          </h2>
          <div className="space-y-4 text-sm text-on-surface-variant leading-relaxed">
            <p>
              정해진 가격표는 없어요. 사이트 규모, 콘텐츠 양, 자동화 범위에 따라 다르거든요.
            </p>
            <p>
              대신 상담은 무료입니다. 어떤 걸 원하시는지 말씀만 해주시면,
              <span className="text-on-surface font-semibold"> 견적과 함께 "직접 하시면 이렇게 하면 돼요"까지 같이 알려드려요.</span>
            </p>
            <p className="text-xs text-slate-400">
              상담 받으시고 직접 하셔도 전혀 상관없습니다. 진짜요.
            </p>
          </div>
        </div>
      </section>

      {/* ── CTA ── */}
      <section className="max-w-3xl mx-auto px-6">
        <div className="bg-slate-900 rounded-2xl p-10 lg:p-14 text-center relative overflow-hidden">
          <div className="absolute inset-0 opacity-10" style={{ backgroundImage: "radial-gradient(circle at 30% 50%, #4F46E5 0%, transparent 50%)" }} />
          <div className="relative">
            <h2 className="text-2xl lg:text-3xl font-extrabold text-white font-headline mb-3">
              일단 편하게 물어보세요
            </h2>
            <p className="text-white/50 text-sm mb-8 max-w-md mx-auto leading-relaxed">
              "이런 것도 되나요?" 수준의 질문도 환영합니다.<br />
              부담 없이 메일 주세요.
            </p>
            <a
              href="mailto:contact@seroai.xyz"
              className="inline-flex items-center gap-2 px-8 py-4 bg-white text-slate-900 font-bold rounded-xl hover:bg-slate-100 transition-colors shadow-xl text-sm"
            >
              <span className="material-symbols-outlined text-lg">mail</span>
              contact@seroai.xyz
            </a>
            <p className="mt-5 text-white/30 text-xs">
              보통 하루 안에 답장드려요
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}

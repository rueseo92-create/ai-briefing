import { Metadata } from "next";
import Image from "next/image";
import { siteConfig } from "@/lib/config";
import { getAllPosts } from "@/lib/posts";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";
import InquiryForm from "@/components/InquiryForm";

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
    <div>
      {/* ── Hero with background image ── */}
      <section className="relative min-h-[520px] lg:min-h-[600px] flex items-center">
        <Image
          src="https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=1920&q=80"
          alt="Professional workspace"
          fill
          className="object-cover"
          priority
        />
        <div className="absolute inset-0 bg-gradient-to-r from-slate-900/90 via-slate-900/75 to-slate-900/50" />
        <div className="relative max-w-6xl mx-auto px-6 py-32 lg:py-40 w-full">
          <div className="max-w-2xl">
            <p className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 text-white/80 text-xs font-medium mb-8">
              <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
              솔직하게 말씀드릴게요
            </p>
            <h1 className="text-4xl lg:text-6xl font-extrabold text-white leading-[1.1] tracking-tight font-headline mb-6">
              이 블로그에서<br />다 알려드려요.
            </h1>
            <div className="space-y-4 text-white/70 text-lg leading-relaxed max-w-xl">
              <p>
                AI 블로그 만드는 법, SEO 최적화, 콘텐츠 자동화 —
                저희가 블로그에 올리는 글만 잘 따라하시면 직접 다 하실 수 있어요.
              </p>
              <p className="text-white font-semibold text-xl">
                근데 바쁘시잖아요. 저희가 대신 해드립니다.
              </p>
            </div>
            <div className="mt-10 flex flex-col sm:flex-row gap-4">
              <a
                href="#services"
                className="inline-flex items-center justify-center gap-2 px-7 py-3.5 bg-white text-slate-900 font-bold rounded-xl hover:bg-slate-100 transition-colors shadow-xl text-sm"
              >
                서비스 살펴보기
                <span className="material-symbols-outlined text-base">arrow_downward</span>
              </a>
              <a
                href="#inquiry"
                className="inline-flex items-center justify-center gap-2 px-7 py-3.5 bg-white/10 text-white font-bold rounded-xl hover:bg-white/20 transition-colors border border-white/20 backdrop-blur-sm text-sm"
              >
                <span className="material-symbols-outlined text-base">send</span>
                바로 견적 요청
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* ── What we actually do ── */}
      <section id="services" className="py-24 bg-white">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <p className="text-sm text-primary font-bold mb-3 tracking-wider uppercase">Services</p>
            <h2 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-4">
              이런 걸 대신 해드려요
            </h2>
            <p className="text-on-surface-variant max-w-lg mx-auto">
              전부 이 블로그에 직접 적용하고 검증한 것들입니다.
            </p>
          </div>

          <div className="grid lg:grid-cols-2 gap-6">
            {[
              {
                icon: "edit_note",
                title: "AI 블로그 글 자동 발행",
                blog: "블로그에 방법 다 있어요",
                agency: "매일 자동으로 SEO 최적화된 글이 올라가게 세팅해드려요",
                link: "/categories/marketing",
                img: "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=600&q=80",
              },
              {
                icon: "travel_explore",
                title: "SEO / 검색엔진 최적화",
                blog: "구글 서치 콘솔 세팅부터 스키마 마크업까지 글로 정리했어요",
                agency: "사이트 분석하고 기술적 SEO 전부 적용해드려요",
                link: "/categories/ai-tools",
                img: "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600&q=80",
              },
              {
                icon: "web",
                title: "블로그 / 웹사이트 구축",
                blog: "Next.js + Vercel 배포하는 법도 AI 도구 카테고리에 있어요",
                agency: "기획부터 디자인, 배포, 도메인 연결까지 통째로 만들어드려요",
                link: "/categories/ai-tools",
                img: "https://images.unsplash.com/photo-1547658719-da2b51169166?w=600&q=80",
              },
              {
                icon: "smart_toy",
                title: "AI 자동화 파이프라인",
                blog: "Claude API 연동하는 법, 자동화 스크립트 예제도 있어요",
                agency: "크롤링 → AI 글 생성 → 발행 → SNS 공유까지 전부 자동화해드려요",
                link: "/categories/ai-tools",
                img: "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=600&q=80",
              },
              {
                icon: "monetization_on",
                title: "수익화 (애드센스, 쿠팡)",
                blog: "쿠팡 파트너스 연동 방법도 포스팅했어요",
                agency: "광고 최적 배치, 어필리에이트 상품 매칭까지 세팅해드려요",
                link: "/posts",
                img: "https://images.unsplash.com/photo-1553729459-uj1ef3166c4b?w=600&q=80",
                imgFallback: "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=600&q=80",
              },
            ].map((item) => (
              <div key={item.title} className="group rounded-2xl border border-slate-200/80 overflow-hidden hover:shadow-xl hover:shadow-slate-200/50 transition-all duration-300 bg-white">
                <div className="flex flex-col sm:flex-row">
                  {/* 이미지 */}
                  <div className="relative w-full sm:w-48 h-40 sm:h-auto flex-shrink-0">
                    <Image
                      src={item.imgFallback || item.img}
                      alt={item.title}
                      fill
                      className="object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t sm:bg-gradient-to-r from-white/20 to-transparent" />
                    <div className="absolute top-3 left-3 w-10 h-10 rounded-xl bg-white/90 backdrop-blur-sm flex items-center justify-center shadow-sm">
                      <span className="material-symbols-outlined text-primary text-xl">{item.icon}</span>
                    </div>
                  </div>
                  {/* 콘텐츠 */}
                  <div className="flex-1 p-5 lg:p-6">
                    <h3 className="font-extrabold text-on-surface text-lg mb-3 font-headline">{item.title}</h3>
                    <div className="grid grid-cols-2 gap-3">
                      <div className="rounded-lg bg-emerald-50/50 border border-emerald-100 p-3">
                        <p className="text-[10px] font-bold text-emerald-600 uppercase tracking-wider mb-1.5">직접 하기</p>
                        <p className="text-xs text-on-surface-variant leading-relaxed">{item.blog}</p>
                        <a href={lh(item.link)} className="inline-flex items-center gap-1 text-[10px] text-primary font-semibold mt-2 hover:underline">
                          글 보러 가기 <span className="material-symbols-outlined text-[10px]">arrow_forward</span>
                        </a>
                      </div>
                      <div className="rounded-lg bg-primary/[0.04] border border-primary/10 p-3">
                        <p className="text-[10px] font-bold text-primary uppercase tracking-wider mb-1.5">대행 맡기기</p>
                        <p className="text-xs text-on-surface-variant leading-relaxed">{item.agency}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── This site is the proof ── */}
      <section className="relative py-24 overflow-hidden">
        <Image
          src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=1920&q=80"
          alt="Analytics dashboard"
          fill
          className="object-cover"
        />
        <div className="absolute inset-0 bg-slate-900/85" />
        <div className="relative max-w-5xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl lg:text-4xl font-extrabold text-white font-headline mb-3">
              증거요? 지금 보고 계세요.
            </h2>
            <p className="text-white/60 text-sm">
              이 블로그 자체가 저희 기술로 만든 결과물입니다.
            </p>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 lg:gap-6">
            {[
              { num: `${posts.length}`, label: "AI 자동 발행 글", icon: "article" },
              { num: "24/7", label: "무인 자동 운영", icon: "schedule" },
              { num: "0", label: "직접 작성한 글", icon: "person_off" },
              { num: "100%", label: "SEO 최적화율", icon: "trending_up" },
            ].map((s) => (
              <div key={s.label} className="rounded-2xl bg-white/10 backdrop-blur-sm border border-white/10 p-6 lg:p-8 text-center">
                <span className="material-symbols-outlined text-indigo-300 text-2xl mb-3 block">{s.icon}</span>
                <p className="text-3xl lg:text-4xl font-extrabold text-white font-headline">{s.num}</p>
                <p className="text-xs text-white/50 mt-2">{s.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── How it works ── */}
      <section className="py-24 bg-white">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <p className="text-sm text-primary font-bold mb-3 tracking-wider uppercase">Process</p>
            <h2 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-4">
              진행은 이렇게 됩니다
            </h2>
            <p className="text-on-surface-variant">
              복잡하지 않아요. 클릭 몇 번이면 시작됩니다.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              {
                step: "01",
                icon: "touch_app",
                title: "서비스 선택 & 견적 요청",
                desc: "원하는 서비스와 예산 범위를 클릭하고, 이메일만 입력하면 끝.",
                detail: "아래 견적 요청 폼에서 30초면 완료됩니다.",
                img: "https://images.unsplash.com/photo-1596526131083-e8c633c948d2?w=400&q=80",
              },
              {
                step: "02",
                icon: "description",
                title: "분석 & 제안",
                desc: "현재 상태를 분석하고, 맞춤 제안서를 드려요.",
                detail: "견적 + \"직접 하시려면 이렇게 하면 됩니다\" 가이드도 같이 드려요.",
                img: "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&q=80",
              },
              {
                step: "03",
                icon: "construction",
                title: "구축 & 세팅",
                desc: "합의된 범위대로 작업합니다. 중간중간 진행 상황 공유드려요.",
                detail: "블로그 구축, AI 파이프라인 세팅, SEO 적용 등 실제 작업 단계예요.",
                img: "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400&q=80",
              },
              {
                step: "04",
                icon: "rocket_launch",
                title: "운영 & 인수인계",
                desc: "완성된 시스템을 넘겨드리고, 직접 운영할 수 있게 가이드해드려요.",
                detail: "자동화 시스템은 넘긴 후에도 알아서 돌아갑니다.",
                img: "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400&q=80",
              },
            ].map((item) => (
              <div key={item.step} className="group rounded-2xl border border-slate-200/80 overflow-hidden hover:shadow-lg transition-all duration-300">
                <div className="relative h-36 overflow-hidden">
                  <Image
                    src={item.img}
                    alt={item.title}
                    fill
                    className="object-cover group-hover:scale-105 transition-transform duration-500"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-slate-900/60 to-transparent" />
                  <div className="absolute bottom-3 left-3 text-[10px] font-bold text-white/80 tracking-wider">
                    STEP {item.step}
                  </div>
                </div>
                <div className="p-5">
                  <h3 className="font-extrabold text-on-surface font-headline mb-2">{item.title}</h3>
                  <p className="text-sm text-on-surface-variant leading-relaxed mb-2">{item.desc}</p>
                  <p className="text-xs text-slate-400 leading-relaxed">{item.detail}</p>
                </div>
              </div>
            ))}
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
              <div key={item.title} className="rounded-xl bg-slate-50 border border-slate-200/80 p-5">
                <span className="material-symbols-outlined text-primary text-lg mb-2 block">{item.icon}</span>
                <h4 className="text-sm font-bold text-on-surface mb-1">{item.title}</h4>
                <p className="text-xs text-on-surface-variant leading-relaxed">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Inquiry Form ── */}
      <section id="inquiry" className="py-24 bg-slate-50 scroll-mt-20">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <p className="text-sm text-primary font-bold mb-3 tracking-wider uppercase">견적 요청</p>
            <h2 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-4">
              클릭만으로 견적 요청 완료
            </h2>
            <p className="text-on-surface-variant max-w-lg mx-auto">
              서비스와 예산을 선택하고 이메일만 입력하면 맞춤 견적을 보내드립니다.
            </p>
          </div>

          <InquiryForm />
        </div>
      </section>
    </div>
  );
}

"use client";

import { useEffect, useRef } from "react";
import { siteConfig } from "@/lib/config";

const AF_CODE = siteConfig.coupang.trackingCode;

/** 쿠팡 파트너스 어필리에이트 링크 생성 */
function buildAffiliateLink(keyword: string): string {
  const encodedKw = encodeURIComponent(keyword);
  // landingUrl의 구조 부분은 수동 인코딩, 키워드만 encodeURIComponent
  return `https://link.coupang.com/re/AFFDP?lptag=${AF_CODE}&subid=&pageType=SEARCH&landingUrl=https%3A%2F%2Fwww.coupang.com%2Fnp%2Fsearch%3Fq%3D${encodedKw}%26channel%3Duser`;
}

// ─── 동적 배너 광고 (g.js) ───────────────────

interface CoupangAdProps {
  id: number;
  template?: "carousel" | "banner" | "card";
  width?: string;
  height?: string;
  subId?: string;
  className?: string;
}

export function CoupangAd({
  id,
  template = "carousel",
  width = "680",
  height = "140",
  subId = "",
  className = "",
}: CoupangAdProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const initialized = useRef(false);

  useEffect(() => {
    if (initialized.current || !containerRef.current) return;
    initialized.current = true;

    const script = document.createElement("script");
    script.src = "https://ads-partners.coupang.com/g.js";
    script.async = true;
    script.onload = () => {
      if (typeof (window as any).PartnersCoupang !== "undefined") {
        new (window as any).PartnersCoupang.G({
          id,
          template,
          subId,
          width,
          height,
        });
      }
    };
    containerRef.current.appendChild(script);
  }, [id, template, subId, width, height]);

  return (
    <div
      ref={containerRef}
      className={`coupang-ad-container flex justify-center ${className}`}
    />
  );
}

// ─── 키워드 기반 어필리에이트 링크 카드 ──────

interface CoupangLinkAdProps {
  keywords: string[];
  title?: string;
  className?: string;
}

export function CoupangLinkAd({
  keywords,
  title = "추천 상품 보러가기",
  className = "",
}: CoupangLinkAdProps) {
  return (
    <div className={`rounded-xl border border-slate-200 bg-white overflow-hidden ${className}`}>
      <div className="flex items-center gap-2 px-5 py-3 bg-slate-50 border-b border-slate-100">
        <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
          <rect width="24" height="24" rx="6" fill="#E31937" />
          <path d="M7 8.5h10M7 12h10M7 15.5h6" stroke="white" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
        <span className="text-sm font-bold text-slate-700">{title}</span>
      </div>
      <div className="p-4 grid gap-2">
        {keywords.map((kw) => (
          <a
            key={kw}
            href={buildAffiliateLink(kw)}
            target="_blank"
            rel="noopener noreferrer sponsored"
            className="flex items-center justify-between px-4 py-3 rounded-lg bg-slate-50 hover:bg-red-50 border border-slate-100 hover:border-red-200 transition-all group"
          >
            <span className="text-sm text-slate-700 group-hover:text-red-600 font-medium">
              🔍 {kw}
            </span>
            <span className="text-xs text-slate-400 group-hover:text-red-500 font-bold flex items-center gap-1">
              쿠팡에서 보기
              <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </span>
          </a>
        ))}
      </div>
      <p className="px-5 py-2 text-[10px] text-slate-400 bg-slate-50 border-t border-slate-100">
        {siteConfig.coupang.disclaimer}
      </p>
    </div>
  );
}

// ─── 컴팩트 사이드바 광고 ────────────────────

interface CoupangSidebarAdProps {
  keywords: string[];
  className?: string;
}

export function CoupangSidebarAd({
  keywords,
  className = "",
}: CoupangSidebarAdProps) {
  return (
    <div className={`rounded-xl border border-slate-200 bg-white ${className}`}>
      <div className="flex items-center gap-2 px-4 py-3 border-b border-slate-100">
        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none">
          <rect width="24" height="24" rx="6" fill="#E31937" />
          <path d="M7 8.5h10M7 12h10M7 15.5h6" stroke="white" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
        <span className="text-xs font-bold text-slate-600">쿠팡 추천</span>
      </div>
      <div className="p-3 space-y-1.5">
        {keywords.map((kw) => (
          <a
            key={kw}
            href={buildAffiliateLink(kw)}
            target="_blank"
            rel="noopener noreferrer sponsored"
            className="flex items-center gap-2 px-3 py-2.5 rounded-lg hover:bg-red-50 transition-colors group"
          >
            <span className="text-xs text-slate-500 group-hover:text-red-600">🔍</span>
            <span className="text-xs text-slate-600 group-hover:text-red-600 font-medium truncate">
              {kw}
            </span>
          </a>
        ))}
      </div>
      <p className="px-4 py-2 text-[9px] text-slate-400 border-t border-slate-50">
        쿠팡 파트너스 활동으로 수수료를 받을 수 있습니다.
      </p>
    </div>
  );
}

// ─── 광고 래퍼 ───────────────────────────────

export function AdSlot({
  children,
  className = "",
  label = true,
}: {
  children: React.ReactNode;
  className?: string;
  label?: boolean;
}) {
  return (
    <div className={`my-8 ${className}`}>
      {label && (
        <p className="text-[10px] text-slate-400 text-center mb-2 tracking-wider">
          SPONSORED
        </p>
      )}
      <div className="flex justify-center">{children}</div>
    </div>
  );
}

"use client";

import { useEffect, useRef } from "react";

interface CoupangAdProps {
  /** 쿠팡 파트너스 광고 ID */
  id: number;
  /** 광고 템플릿: carousel, banner, card */
  template?: "carousel" | "banner" | "card";
  /** 광고 너비 */
  width?: string;
  /** 광고 높이 */
  height?: string;
  /** 서브 트래킹 ID */
  subId?: string;
  /** 추가 CSS 클래스 */
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

/** 쿠팡 배너 광고 (iframe 방식) */
export function CoupangBanner({
  src,
  width = "680",
  height = "140",
  className = "",
}: {
  src: string;
  width?: string;
  height?: string;
  className?: string;
}) {
  return (
    <div className={`coupang-ad-container flex justify-center ${className}`}>
      <iframe
        src={src}
        width={width}
        height={height}
        frameBorder="0"
        scrolling="no"
        referrerPolicy="unsafe-url"
        style={{ maxWidth: "100%" }}
      />
    </div>
  );
}

/** 광고 래퍼: 레이블 + 광고 + 구분선 */
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

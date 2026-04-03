"use client";

import { useEffect, useRef } from "react";

const ADSENSE_ID = "ca-pub-1902054355965964";

interface AdSenseProps {
  slot: string;
  format?: "auto" | "fluid" | "rectangle" | "horizontal" | "vertical";
  layout?: string;
  className?: string;
}

export function AdSense({
  slot,
  format = "auto",
  layout,
  className = "",
}: AdSenseProps) {
  const adRef = useRef<HTMLDivElement>(null);
  const pushed = useRef(false);

  useEffect(() => {
    if (pushed.current) return;
    try {
      ((window as any).adsbygoogle = (window as any).adsbygoogle || []).push({});
      pushed.current = true;
    } catch {
      // adsbygoogle not loaded yet
    }
  }, []);

  return (
    <div className={`adsense-container my-8 ${className}`}>
      <p className="text-[10px] text-slate-400 text-center mb-2 tracking-wider">
        SPONSORED
      </p>
      <div ref={adRef} className="flex justify-center">
        <ins
          className="adsbygoogle"
          style={{ display: "block" }}
          data-ad-client={ADSENSE_ID}
          data-ad-slot={slot}
          data-ad-format={format}
          {...(layout ? { "data-ad-layout": layout } : {})}
          data-full-width-responsive="true"
        />
      </div>
    </div>
  );
}

export function InArticleAd({ className = "" }: { className?: string }) {
  return (
    <AdSense
      slot="auto"
      format="fluid"
      layout="in-article"
      className={className}
    />
  );
}

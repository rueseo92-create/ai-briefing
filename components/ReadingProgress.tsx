"use client";

import { useEffect, useState } from "react";

export function ReadingProgress() {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    function onScroll() {
      const el = document.querySelector("article");
      if (!el) return;
      const rect = el.getBoundingClientRect();
      const total = el.scrollHeight - window.innerHeight;
      const current = -rect.top;
      setProgress(Math.min(100, Math.max(0, (current / total) * 100)));
    }
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  if (progress <= 0) return null;

  return (
    <div className="fixed top-16 left-0 w-full h-[3px] z-50 bg-transparent">
      <div
        className="h-full bg-gradient-to-r from-primary via-indigo-400 to-cyan-400 transition-[width] duration-150 ease-out"
        style={{ width: `${progress}%` }}
      />
    </div>
  );
}

"use client";

import { useEffect, useState } from "react";

interface TocItem {
  id: string;
  text: string;
  level: number;
}

export function TableOfContents() {
  const [headings, setHeadings] = useState<TocItem[]>([]);
  const [activeId, setActiveId] = useState("");

  useEffect(() => {
    const article = document.querySelector(".prose");
    if (!article) return;

    const els = article.querySelectorAll("h2, h3");
    const items: TocItem[] = [];
    els.forEach((el, i) => {
      if (!el.id) el.id = `heading-${i}`;
      items.push({
        id: el.id,
        text: el.textContent || "",
        level: el.tagName === "H2" ? 2 : 3,
      });
    });
    setHeadings(items);

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries.filter((e) => e.isIntersecting);
        if (visible.length > 0) {
          setActiveId(visible[0].target.id);
        }
      },
      { rootMargin: "-80px 0px -60% 0px", threshold: 0.1 }
    );

    els.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  if (headings.length < 3) return null;

  return (
    <nav className="hidden xl:block fixed right-[max(1rem,calc((100vw-1280px)/2-16rem))] top-28 w-56 max-h-[calc(100vh-8rem)] overflow-y-auto text-xs">
      <p className="font-bold text-slate-400 uppercase tracking-widest mb-3 text-[10px]">
        On this page
      </p>
      <ul className="space-y-1.5 border-l border-slate-200">
        {headings.map((h) => (
          <li key={h.id}>
            <a
              href={`#${h.id}`}
              onClick={(e) => {
                e.preventDefault();
                document.getElementById(h.id)?.scrollIntoView({ behavior: "smooth", block: "start" });
              }}
              className={`block transition-colors leading-snug ${
                h.level === 3 ? "pl-6" : "pl-3"
              } py-0.5 border-l-2 -ml-[1px] ${
                activeId === h.id
                  ? "border-primary text-primary font-semibold"
                  : "border-transparent text-slate-400 hover:text-slate-600 hover:border-slate-300"
              }`}
            >
              {h.text}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}

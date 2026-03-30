"use client";

import { useEffect, useState } from "react";

export function ScrollToTop() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    function onScroll() {
      setShow(window.scrollY > 500);
    }
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  if (!show) return null;

  return (
    <button
      onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
      className="fixed bottom-6 right-6 z-40 w-11 h-11 rounded-full bg-white border border-slate-200 shadow-lg flex items-center justify-center text-slate-500 hover:text-primary hover:border-primary transition-all hover:shadow-xl"
      aria-label="Scroll to top"
    >
      <span className="material-symbols-outlined text-xl">keyboard_arrow_up</span>
    </button>
  );
}

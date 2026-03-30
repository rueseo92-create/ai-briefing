"use client";

import { useState } from "react";

interface MobileNavProps {
  items: { href: string; label: string }[];
  searchHref: string;
}

export function MobileNav({ items, searchHref }: MobileNavProps) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="p-2 text-slate-600 hover:text-primary transition-colors md:hidden"
        aria-label="Open menu"
      >
        <span className="material-symbols-outlined">menu</span>
      </button>

      {open && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-black/30 z-[60] md:hidden"
            onClick={() => setOpen(false)}
          />
          {/* Drawer */}
          <div className="fixed top-0 right-0 w-72 h-full bg-white z-[70] shadow-2xl md:hidden flex flex-col">
            <div className="flex items-center justify-between p-4 border-b border-slate-100">
              <span className="text-sm font-bold text-slate-900">Menu</span>
              <button
                onClick={() => setOpen(false)}
                className="p-1 text-slate-400 hover:text-slate-600"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <nav className="flex-1 overflow-y-auto py-3">
              {items.map((item) => (
                <a
                  key={item.href}
                  href={item.href}
                  className="block px-6 py-3 text-sm text-slate-700 hover:bg-slate-50 hover:text-primary transition-colors"
                  onClick={() => setOpen(false)}
                >
                  {item.label}
                </a>
              ))}
            </nav>
            <div className="p-4 border-t border-slate-100">
              <a
                href={searchHref}
                className="flex items-center gap-2 px-4 py-2.5 rounded-lg bg-slate-50 text-sm text-slate-600 hover:bg-slate-100 transition-colors"
              >
                <span className="material-symbols-outlined text-base">search</span>
                Search
              </a>
            </div>
          </div>
        </>
      )}
    </>
  );
}

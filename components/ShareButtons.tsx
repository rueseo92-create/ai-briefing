"use client";

import { useState } from "react";

interface ShareButtonsProps {
  url: string;
  title: string;
  description?: string;
}

export function ShareButtons({ url, title, description }: ShareButtonsProps) {
  const [copied, setCopied] = useState(false);
  const text = description || title;

  const shareLinks = [
    {
      name: "X",
      icon: "𝕏",
      href: `https://twitter.com/intent/tweet?text=${encodeURIComponent(title)}&url=${encodeURIComponent(url)}`,
      color: "hover:bg-slate-900 hover:text-white",
    },
    {
      name: "Facebook",
      icon: "f",
      href: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`,
      color: "hover:bg-blue-600 hover:text-white",
    },
    {
      name: "LinkedIn",
      icon: "in",
      href: `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(url)}&title=${encodeURIComponent(title)}&summary=${encodeURIComponent(text)}`,
      color: "hover:bg-blue-700 hover:text-white",
    },
  ];

  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // fallback
      const input = document.createElement("input");
      input.value = url;
      document.body.appendChild(input);
      input.select();
      document.execCommand("copy");
      document.body.removeChild(input);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div className="flex items-center gap-2">
      {shareLinks.map((link) => (
        <a
          key={link.name}
          href={link.href}
          target="_blank"
          rel="noopener noreferrer"
          className={`inline-flex items-center justify-center w-9 h-9 rounded-lg border border-slate-200 text-slate-500 text-xs font-bold transition-all ${link.color}`}
          title={link.name}
        >
          {link.icon}
        </a>
      ))}
      <button
        onClick={copyLink}
        className={`inline-flex items-center justify-center w-9 h-9 rounded-lg border transition-all ${
          copied
            ? "bg-emerald-50 border-emerald-200 text-emerald-600"
            : "border-slate-200 text-slate-500 hover:bg-slate-100"
        }`}
        title={copied ? "Copied!" : "Copy link"}
      >
        <span className="material-symbols-outlined text-base">
          {copied ? "check" : "link"}
        </span>
      </button>
    </div>
  );
}

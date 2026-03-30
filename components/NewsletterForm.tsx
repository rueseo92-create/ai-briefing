"use client";

import { useState } from "react";

interface Props {
  placeholder: string;
  buttonText: string;
}

export default function NewsletterForm({ placeholder, buttonText }: Props) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [message, setMessage] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim()) return;

    setStatus("loading");
    try {
      const res = await fetch("/api/newsletter", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim() }),
      });
      const data = await res.json();

      if (res.ok) {
        setStatus("success");
        setMessage("구독 완료! 감사합니다.");
        setEmail("");
      } else {
        setStatus("error");
        setMessage(data.error || "오류가 발생했습니다.");
      }
    } catch {
      setStatus("error");
      setMessage("네트워크 오류가 발생했습니다.");
    }
  }

  if (status === "success") {
    return (
      <div className="flex items-center gap-2 px-5 py-3 rounded-full bg-white/[0.15] backdrop-blur-sm border border-white/[0.15]">
        <span className="material-symbols-outlined text-emerald-300 text-lg">check_circle</span>
        <span className="text-sm text-white font-medium">{message}</span>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-2.5 w-full lg:w-auto flex-shrink-0">
      <div className="relative">
        <input
          className="px-5 py-3 rounded-full bg-white/[0.12] backdrop-blur-sm border border-white/[0.1] text-sm text-white placeholder-white/40 focus:ring-2 focus:ring-white/20 focus:border-white/20 focus:bg-white/[0.15] transition-all w-full sm:w-64"
          placeholder={placeholder}
          type="email"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (status === "error") setStatus("idle");
          }}
          required
        />
        {status === "error" && (
          <p className="absolute -bottom-5 left-2 text-[10px] text-red-300">{message}</p>
        )}
      </div>
      <button
        type="submit"
        disabled={status === "loading"}
        className="px-6 py-3 bg-white text-indigo-700 font-bold text-sm rounded-full hover:bg-indigo-50 transition-colors flex-shrink-0 shadow-lg disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {status === "loading" ? "처리 중..." : buttonText}
      </button>
    </form>
  );
}

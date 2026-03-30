"use client";

import { useState } from "react";

const SERVICES = [
  { id: "blog", icon: "edit_note", label: "AI 블로그 자동 발행" },
  { id: "seo", icon: "travel_explore", label: "SEO / AEO / GEO 최적화" },
  { id: "website", icon: "web", label: "블로그 / 웹사이트 구축" },
  { id: "pipeline", icon: "smart_toy", label: "AI 자동화 파이프라인" },
  { id: "monetize", icon: "monetization_on", label: "수익화 (애드센스, 쿠팡)" },
];

const BUDGETS = [
  { id: "starter", label: "50만원~", desc: "단일 서비스" },
  { id: "pro", label: "150만원~", desc: "풀 패키지" },
  { id: "enterprise", label: "별도 협의", desc: "대규모/장기" },
];

export default function InquiryForm() {
  const [services, setServices] = useState<string[]>([]);
  const [budget, setBudget] = useState("");
  const [email, setEmail] = useState("");
  const [company, setCompany] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMsg, setErrorMsg] = useState("");

  function toggleService(id: string) {
    setServices((prev) =>
      prev.includes(id) ? prev.filter((s) => s !== id) : [...prev, id]
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (services.length === 0) {
      setErrorMsg("관심 있는 서비스를 1개 이상 선택해주세요.");
      setStatus("error");
      return;
    }
    if (!budget) {
      setErrorMsg("예산 범위를 선택해주세요.");
      setStatus("error");
      return;
    }
    if (!email.trim()) {
      setErrorMsg("연락받으실 이메일을 입력해주세요.");
      setStatus("error");
      return;
    }

    setStatus("loading");
    try {
      const res = await fetch("/api/inquiry", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          services,
          budget,
          email: email.trim(),
          company: company.trim(),
        }),
      });
      if (res.ok) {
        setStatus("success");
      } else {
        const data = await res.json();
        setErrorMsg(data.error || "오류가 발생했습니다.");
        setStatus("error");
      }
    } catch {
      setErrorMsg("네트워크 오류가 발생했습니다.");
      setStatus("error");
    }
  }

  if (status === "success") {
    return (
      <div className="max-w-lg mx-auto text-center py-12">
        <div className="w-16 h-16 rounded-full bg-emerald-100 flex items-center justify-center mx-auto mb-5">
          <span className="material-symbols-outlined text-emerald-600 text-3xl">check_circle</span>
        </div>
        <h3 className="text-2xl font-extrabold text-on-surface font-headline mb-3">
          문의가 접수되었습니다!
        </h3>
        <p className="text-on-surface-variant text-sm leading-relaxed">
          입력하신 이메일로 하루 안에 맞춤 견적을 보내드릴게요.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-2xl mx-auto">
      {/* Step 1: 서비스 선택 */}
      <div className="mb-10">
        <div className="flex items-center gap-3 mb-5">
          <span className="w-7 h-7 rounded-full bg-primary text-white text-xs font-bold flex items-center justify-center">1</span>
          <h3 className="text-lg font-bold text-on-surface font-headline">어떤 서비스가 필요하세요?</h3>
          <span className="text-xs text-slate-400">복수 선택 가능</span>
        </div>
        <div className="grid sm:grid-cols-2 gap-3">
          {SERVICES.map((s) => {
            const selected = services.includes(s.id);
            return (
              <button
                key={s.id}
                type="button"
                onClick={() => { toggleService(s.id); setStatus("idle"); }}
                className={`flex items-center gap-3 p-4 rounded-xl border-2 transition-all text-left ${
                  selected
                    ? "border-primary bg-indigo-50 shadow-sm"
                    : "border-slate-200 bg-white hover:border-slate-300"
                }`}
              >
                <span className={`material-symbols-outlined text-xl ${selected ? "text-primary" : "text-slate-400"}`}>
                  {s.icon}
                </span>
                <span className={`text-sm font-semibold ${selected ? "text-primary" : "text-on-surface"}`}>
                  {s.label}
                </span>
                {selected && (
                  <span className="material-symbols-outlined text-primary text-lg ml-auto">check_circle</span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Step 2: 예산 범위 */}
      <div className="mb-10">
        <div className="flex items-center gap-3 mb-5">
          <span className="w-7 h-7 rounded-full bg-primary text-white text-xs font-bold flex items-center justify-center">2</span>
          <h3 className="text-lg font-bold text-on-surface font-headline">예산 범위는?</h3>
        </div>
        <div className="grid grid-cols-3 gap-3">
          {BUDGETS.map((b) => {
            const selected = budget === b.id;
            return (
              <button
                key={b.id}
                type="button"
                onClick={() => { setBudget(b.id); setStatus("idle"); }}
                className={`p-4 rounded-xl border-2 transition-all text-center ${
                  selected
                    ? "border-primary bg-indigo-50 shadow-sm"
                    : "border-slate-200 bg-white hover:border-slate-300"
                }`}
              >
                <p className={`text-lg font-extrabold font-headline ${selected ? "text-primary" : "text-on-surface"}`}>
                  {b.label}
                </p>
                <p className="text-[11px] text-slate-400 mt-1">{b.desc}</p>
              </button>
            );
          })}
        </div>
      </div>

      {/* Step 3: 연락처 */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-5">
          <span className="w-7 h-7 rounded-full bg-primary text-white text-xs font-bold flex items-center justify-center">3</span>
          <h3 className="text-lg font-bold text-on-surface font-headline">견적 받으실 이메일</h3>
        </div>
        <div className="grid sm:grid-cols-2 gap-3">
          <input
            type="email"
            value={email}
            onChange={(e) => { setEmail(e.target.value); setStatus("idle"); }}
            placeholder="name@company.com"
            required
            className="px-4 py-3 rounded-xl border-2 border-slate-200 text-sm focus:border-primary focus:ring-0 outline-none transition-colors"
          />
          <input
            type="text"
            value={company}
            onChange={(e) => setCompany(e.target.value)}
            placeholder="회사/팀명 (선택)"
            className="px-4 py-3 rounded-xl border-2 border-slate-200 text-sm focus:border-primary focus:ring-0 outline-none transition-colors"
          />
        </div>
      </div>

      {/* 에러 메시지 */}
      {status === "error" && (
        <div className="mb-6 flex items-center gap-2 px-4 py-3 rounded-xl bg-red-50 border border-red-200">
          <span className="material-symbols-outlined text-red-500 text-base">error</span>
          <p className="text-sm text-red-600">{errorMsg}</p>
        </div>
      )}

      {/* 제출 */}
      <button
        type="submit"
        disabled={status === "loading"}
        className="w-full py-4 bg-primary text-white font-bold rounded-xl hover:bg-indigo-700 transition-colors text-sm disabled:opacity-60 disabled:cursor-not-allowed shadow-lg shadow-indigo-200"
      >
        {status === "loading" ? "접수 중..." : "맞춤 견적 요청하기"}
      </button>
      <p className="text-center text-xs text-slate-400 mt-4">
        보통 하루 안에 이메일로 견적을 보내드려요
      </p>
    </form>
  );
}

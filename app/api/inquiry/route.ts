import { NextRequest, NextResponse } from "next/server";

interface Inquiry {
  services: string[];
  budget: string;
  email: string;
  company?: string;
  createdAt: string;
}

const VALID_SERVICES = ["blog", "seo", "website", "pipeline", "monetize"];
const VALID_BUDGETS = ["starter", "pro", "enterprise"];

const SERVICE_LABELS: Record<string, string> = {
  blog: "AI 블로그 자동 발행",
  seo: "SEO / AEO / GEO 최적화",
  website: "블로그 / 웹사이트 구축",
  pipeline: "AI 자동화 파이프라인",
  monetize: "수익화 (애드센스, 쿠팡)",
};

const BUDGET_LABELS: Record<string, string> = {
  starter: "50만원~ (단일 서비스)",
  pro: "150만원~ (풀 패키지)",
  enterprise: "별도 협의 (대규모/장기)",
};

async function sendEmail(inquiry: Inquiry) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return;

  const serviceList = inquiry.services.map((s) => SERVICE_LABELS[s] || s).join(", ");
  const budgetLabel = BUDGET_LABELS[inquiry.budget] || inquiry.budget;

  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      from: "AI 브리핑 <onboarding@resend.dev>",
      to: "rueseo92@gmail.com",
      subject: `[견적문의] ${serviceList}`,
      html: `
        <h2>새 견적 문의가 접수되었습니다</h2>
        <table style="border-collapse:collapse;width:100%;max-width:500px;">
          <tr><td style="padding:8px;border:1px solid #ddd;font-weight:bold;">서비스</td><td style="padding:8px;border:1px solid #ddd;">${serviceList}</td></tr>
          <tr><td style="padding:8px;border:1px solid #ddd;font-weight:bold;">예산</td><td style="padding:8px;border:1px solid #ddd;">${budgetLabel}</td></tr>
          <tr><td style="padding:8px;border:1px solid #ddd;font-weight:bold;">이메일</td><td style="padding:8px;border:1px solid #ddd;">${inquiry.email}</td></tr>
          <tr><td style="padding:8px;border:1px solid #ddd;font-weight:bold;">회사/팀</td><td style="padding:8px;border:1px solid #ddd;">${inquiry.company || "-"}</td></tr>
          <tr><td style="padding:8px;border:1px solid #ddd;font-weight:bold;">접수일시</td><td style="padding:8px;border:1px solid #ddd;">${inquiry.createdAt}</td></tr>
        </table>
      `,
    }),
  });
}

export async function POST(req: NextRequest) {
  try {
    const { services, budget, email, company } = await req.json();

    if (!Array.isArray(services) || services.length === 0 || !services.every((s: string) => VALID_SERVICES.includes(s))) {
      return NextResponse.json({ error: "서비스를 선택해주세요." }, { status: 400 });
    }
    if (!VALID_BUDGETS.includes(budget)) {
      return NextResponse.json({ error: "예산 범위를 선택해주세요." }, { status: 400 });
    }
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return NextResponse.json({ error: "유효한 이메일을 입력해주세요." }, { status: 400 });
    }

    const inquiry: Inquiry = {
      services,
      budget,
      email: email.trim().toLowerCase(),
      company: company?.trim() || undefined,
      createdAt: new Date().toISOString(),
    };

    // 이메일 알림 발송
    await sendEmail(inquiry);

    // Vercel Logs에도 기록
    console.log("[견적문의]", JSON.stringify(inquiry));

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "서버 오류가 발생했습니다." }, { status: 500 });
  }
}

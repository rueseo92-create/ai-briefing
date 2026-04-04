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

    // 외부 웹훅 설정 시 전달 (Slack, Discord 등)
    const webhookUrl = process.env.INQUIRY_WEBHOOK_URL;
    if (webhookUrl) {
      await fetch(webhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(inquiry),
      });
    }

    // Vercel Logs에 기록 (Vercel 대시보드 > Logs에서 확인 가능)
    console.log("[견적문의]", JSON.stringify(inquiry));

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "서버 오류가 발생했습니다." }, { status: 500 });
  }
}

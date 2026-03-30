import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";

const INQUIRIES_FILE = path.join(process.cwd(), "data/inquiries.json");

interface Inquiry {
  services: string[];
  budget: string;
  email: string;
  company?: string;
  createdAt: string;
}

function readInquiries(): Inquiry[] {
  try {
    if (!fs.existsSync(INQUIRIES_FILE)) return [];
    return JSON.parse(fs.readFileSync(INQUIRIES_FILE, "utf-8"));
  } catch {
    return [];
  }
}

function writeInquiries(data: Inquiry[]) {
  const dir = path.dirname(INQUIRIES_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(INQUIRIES_FILE, JSON.stringify(data, null, 2), "utf-8");
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

    // 외부 웹훅 설정 시 전달
    const webhookUrl = process.env.INQUIRY_WEBHOOK_URL;
    if (webhookUrl) {
      await fetch(webhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(inquiry),
      });
      return NextResponse.json({ ok: true });
    }

    // 로컬 JSON 저장
    const inquiries = readInquiries();
    inquiries.push(inquiry);
    writeInquiries(inquiries);

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "서버 오류가 발생했습니다." }, { status: 500 });
  }
}

import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";

const SUBSCRIBERS_FILE = path.join(process.cwd(), "data/subscribers.json");

function readSubscribers(): { email: string; subscribedAt: string }[] {
  try {
    if (!fs.existsSync(SUBSCRIBERS_FILE)) return [];
    return JSON.parse(fs.readFileSync(SUBSCRIBERS_FILE, "utf-8"));
  } catch {
    return [];
  }
}

function writeSubscribers(data: { email: string; subscribedAt: string }[]) {
  const dir = path.dirname(SUBSCRIBERS_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(SUBSCRIBERS_FILE, JSON.stringify(data, null, 2), "utf-8");
}

export async function POST(req: NextRequest) {
  try {
    const { email } = await req.json();

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return NextResponse.json(
        { error: "유효한 이메일 주소를 입력해주세요." },
        { status: 400 }
      );
    }

    const normalized = email.trim().toLowerCase();

    // 외부 웹훅이 설정된 경우 (Google Sheets, Zapier 등)
    const webhookUrl = process.env.NEWSLETTER_WEBHOOK_URL;
    if (webhookUrl) {
      await fetch(webhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: normalized, subscribedAt: new Date().toISOString() }),
      });
      return NextResponse.json({ ok: true });
    }

    // 로컬 JSON 파일 저장
    const subscribers = readSubscribers();

    if (subscribers.some((s) => s.email === normalized)) {
      return NextResponse.json(
        { error: "이미 구독 중인 이메일입니다." },
        { status: 409 }
      );
    }

    subscribers.push({ email: normalized, subscribedAt: new Date().toISOString() });
    writeSubscribers(subscribers);

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json(
      { error: "서버 오류가 발생했습니다." },
      { status: 500 }
    );
  }
}

export async function GET() {
  const key = process.env.NEWSLETTER_ADMIN_KEY;
  if (!key) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const subscribers = readSubscribers();
  return NextResponse.json({ count: subscribers.length, subscribers });
}

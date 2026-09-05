import { headers } from "next/headers";
import { NextResponse } from "next/server";
import { collectFingerprint } from "@/lib/fingerprint";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

/**
 * Environment fingerprint endpoint.
 * Safe-by-construction: DATABASE_URL is only ever reported as
 * scheme/host/port/database — credentials are never included.
 */
export async function GET() {
  const h = await headers();
  const report = await collectFingerprint(h.get("host"), h.get("x-forwarded-proto"));
  return NextResponse.json(report, { status: 200 });
}

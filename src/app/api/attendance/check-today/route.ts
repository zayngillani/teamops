import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import prisma from "@/lib/prisma";

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session?.user) return NextResponse.json({ completed: false });

  const userId = (session.user as any).id;
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  
  const todayEnd = new Date();
  todayEnd.setHours(23, 59, 59, 999);

  const completedTodayRaw = await prisma.$queryRawUnsafe<any[]>(
    `SELECT id FROM "Attendance" WHERE "userId" = $1::text AND "startTime" >= $2::timestamp AND "startTime" <= $3::timestamp AND "status" = 'COMPLETED' LIMIT 1`,
    userId, todayStart, todayEnd
  );

  return NextResponse.json({ completed: completedTodayRaw.length > 0 });
}

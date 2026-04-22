"use server";

import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { sendSlackNotification } from "@/lib/slack";

/**
 * Helper to parse dates from raw SQL results correctly.
 * Postgres 'timestamp' without time zone comes back as a string or local-ambiguous Date.
 * We treat it as UTC.
 */
function parseDbDate(date: any): Date {
  if (!date) return new Date();
  if (date instanceof Date) return date;
  if (typeof date === "string") {
    return new Date(date.includes("Z") || date.includes("+") ? date : date + "Z");
  }
  return new Date(date);
}

/**
 * Start the day for a user. Creates a single Attendance record.
 */
export async function startAttendance() {
  const session = await getServerSession(authOptions);
  if (!session?.user) throw new Error("Unauthorized");

  const userId = (session.user as any).id;
  const userName = session.user.name || "A team member";
  const userRole = (session.user as any).role;
  const now = new Date();
  const timeStr = now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  const isWeekend = now.getDay() === 0 || now.getDay() === 6;

  // 1. Restriction: No check-in on weekends (Admins are exempt)
  if (isWeekend && userRole !== "admin") {
    throw new Error("Check-in is restricted on weekends unless on-call support is enabled.");
  }

  // 2. Restriction: No check-in if on approved leave (Admins are exempt)
  if (userRole !== "admin") {
    const todayLeave = await prisma.leaveRequest.findFirst({
      where: {
        userId,
        status: "APPROVED",
        startDate: { lte: now },
        endDate: { gte: now },
      },
    });

    if (todayLeave) {
      throw new Error("You cannot check in while on an approved leave.");
    }
  }

  // 3. Check for existing record for today using Raw SQL
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const todayEnd = new Date();
  todayEnd.setHours(23, 59, 59, 999);

  const existingRecords = await prisma.$queryRawUnsafe<any[]>(
    `SELECT * FROM "Attendance" WHERE "userId" = $1::text AND "startTime" >= $2::timestamp AND "startTime" <= $3::timestamp LIMIT 1`,
    userId, todayStart, todayEnd
  );

  const existingRecord = existingRecords[0];

  if (existingRecord) {
    if (existingRecord.status === "COMPLETED") {
      throw new Error("You have already completed your work session for today.");
    }
    return existingRecord; // Already started
  }

  // Create record using Raw SQL
  const id = Math.random().toString(36).substring(7);
  await prisma.$executeRawUnsafe(
    `INSERT INTO "Attendance" ("id", "userId", "startTime", "status", "updatedAt") VALUES ($1, $2, $3, $4, NOW())`,
    id, userId, now, "WORKING"
  );

  // Slack Notification
  await sendSlackNotification({
    type: "CHECK_IN",
    user: userName,
    time: timeStr,
  });

  revalidatePath("/dashboard/attendance");
  return { id, startTime: now, status: "WORKING" };
}

/**
 * Handle transitions (Break, Resume, Finish)
 */
export async function updateAttendanceStatus(action: "BREAK" | "RESUME" | "FINISH", report?: string) {
  const session = await getServerSession(authOptions);
  if (!session?.user) throw new Error("Unauthorized");

  const userId = (session.user as any).id;
  const userName = session.user.name || "A team member";
  const now = new Date();
  const timeStr = now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

  const records = await prisma.$queryRawUnsafe<any[]>(
    `SELECT * FROM "Attendance" WHERE "userId" = $1::text AND "status" != 'COMPLETED' ORDER BY "startTime" DESC LIMIT 1`,
    userId
  );

  const record = records[0];
  if (!record) throw new Error("No active session found.");

  // Safely parse start time from DB
  const startTime = parseDbDate(record.startTime);

  if (action === "BREAK") {
    await prisma.$executeRawUnsafe(
      `UPDATE "Attendance" SET "status" = 'ON_BREAK', "lastBreakStartTime" = $1::timestamp, "updatedAt" = NOW() WHERE "id" = $2::text`,
      now, record.id
    );
  } else if (action === "RESUME") {
    const lastBreakStart = record.lastBreakStartTime ? parseDbDate(record.lastBreakStartTime) : null;
    const breakDuration = lastBreakStart ? (now.getTime() - lastBreakStart.getTime()) : 0;
    await prisma.$executeRawUnsafe(
      `UPDATE "Attendance" SET "status" = 'WORKING', "totalBreakMs" = "totalBreakMs" + $1::int, "lastBreakStartTime" = NULL, "updatedAt" = NOW() WHERE "id" = $2::text`,
      Math.max(0, breakDuration), record.id
    );
  } else if (action === "FINISH") {
    // Calculate final break adjustment if finishing while on break
    let breakAdjustment = 0;
    if (record.status === "ON_BREAK" && record.lastBreakStartTime) {
      const lastBreakStart = parseDbDate(record.lastBreakStartTime);
      breakAdjustment = Math.max(0, now.getTime() - lastBreakStart.getTime());
    }

    // Use SQL to calculate the final totalWorkMs to avoid any JS timezone issues
    // We update totalBreakMs first, then calculate workMs as (TotalTime - TotalBreak)
    await prisma.$executeRawUnsafe(`
      UPDATE "Attendance" 
      SET 
        "totalBreakMs" = "totalBreakMs" + $1::int,
        "lastBreakStartTime" = NULL,
        "status" = 'COMPLETED',
        "endTime" = NOW(),
        "report" = $2::text,
        "updatedAt" = NOW()
      WHERE "id" = $3::text
    `, breakAdjustment, report || "", record.id);

    // Now calculate and set totalWorkMs based on the final endTime and totalBreakMs
    await prisma.$executeRawUnsafe(`
      UPDATE "Attendance"
      SET "totalWorkMs" = GREATEST(0, (EXTRACT(EPOCH FROM ("endTime" - "startTime")) * 1000)::int - "totalBreakMs")
      WHERE "id" = $1::text
    `, record.id);
  }

  // Slack Notifications
  if (action === "BREAK") {
    await sendSlackNotification({ type: "BREAK_IN", user: userName, time: timeStr });
  } else if (action === "RESUME") {
    await sendSlackNotification({ type: "BREAK_OUT", user: userName, time: timeStr });
  } else if (action === "FINISH") {
    await sendSlackNotification({ type: "CHECK_OUT", user: userName, time: timeStr, report });
  }

  revalidatePath("/dashboard/attendance");
  revalidatePath("/dashboard/reports");
  
  // Return the updated record for client state sync
  const updatedRecords = await prisma.$queryRawUnsafe<any[]>(
    `SELECT * FROM "Attendance" WHERE "id" = $1::text`, 
    record.id
  );
  const updated = updatedRecords[0];

  return { 
    id: updated.id, 
    status: updated.status,
    startTime: parseDbDate(updated.startTime),
    totalBreakMs: updated.totalBreakMs,
    lastBreakStartTime: updated.lastBreakStartTime ? parseDbDate(updated.lastBreakStartTime) : null
  };
}

export async function getActiveAttendance() {
  const session = await getServerSession(authOptions);
  if (!session?.user) return null;
  const userId = (session.user as any).id;

  const records = await prisma.$queryRawUnsafe<any[]>(
    `SELECT * FROM "Attendance" WHERE "userId" = $1::text AND "status" != 'COMPLETED' LIMIT 1`,
    userId
  );
  const record = records[0];
  if (!record) return null;

  return {
    ...record,
    startTime: parseDbDate(record.startTime),
    lastBreakStartTime: record.lastBreakStartTime ? parseDbDate(record.lastBreakStartTime) : null
  };
}

export async function getMonthlySummary(userId?: string) {
  const session = await getServerSession(authOptions);
  if (!session?.user) throw new Error("Unauthorized");

  const targetUserId = userId || (session.user as any).id;
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const logs = await prisma.$queryRawUnsafe<any[]>(
    `SELECT "totalWorkMs", "totalBreakMs" FROM "Attendance" WHERE "userId" = $1::text AND "startTime" >= $2::timestamp`,
    targetUserId, startOfMonth
  );

  let totalWorkMs = 0;
  let totalBreakMs = 0;

  logs.forEach((log: any) => {
    totalWorkMs += log.totalWorkMs || 0;
    totalBreakMs += log.totalBreakMs || 0;
  });

  return { totalWorkMs, totalBreakMs, logCount: logs.length };
}

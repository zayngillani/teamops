import { headers } from "next/headers";
import prisma from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export async function checkIPAccess() {
  const session = await getServerSession(authOptions);
  if (!session?.user) return true; // Let auth middleware handle login

  // Always fetch fresh user data from DB to ensure instant bypass updates
  const user = await prisma.user.findUnique({
    where: { id: (session.user as any).id },
    select: { role: true, canOutsideAccess: true },
  });

  if (!user) return false;

  // 1. If user is an admin or has outside access allowed, skip check
  if (user.role === "admin" || user.canOutsideAccess) return true;

  // 2. Get client IP
  const headersList = await headers();
  const ip = headersList.get("x-forwarded-for") || headersList.get("x-real-ip") || "127.0.0.1";

  // 3. Check if IP is whitelisted
  const whitelist = await prisma.ipManagement.findUnique({
    where: { ipAddress: ip, status: true },
  });

  return !!whitelist;
}
